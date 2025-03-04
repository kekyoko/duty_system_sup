if CLIENT then return end

-- NET
util.AddNetworkString( "RE.Duty.Patrol_Next" )
util.AddNetworkString( "RE.Duty.Patrol_Arrived" )
util.AddNetworkString( "RE.Duty.Patrol_End" )

util.AddNetworkString( "RE.Duty.Station_Select" )

util.AddNetworkString( "RE.Duty.Fail" )

util.AddNetworkString( "RE.Duty.Open_Terminal" )
util.AddNetworkString( "RE.Duty.Request_Duty" )
util.AddNetworkString( "RE.Duty.Cancel_Duty" )

util.AddNetworkString( "Duty.UpdateBoxStatus" )
-----

duty_leaderboard = duty_leaderboard or {
	{0, "-"},
	{0, "-"},
	{0, "-"},
}

duty_cur_stations = duty_cur_stations or {}

---- Проверка доступа к патрулю
local function CheckPatrolAccess(ply)
	return true
end

local function IsOnDuty(ply)
	local status = ply:GetNW2Int("Duty_Status", DUTY_NONE)
	if status >= DUTY_PATROL_PREPARING and status <= DUTY_LOGISTICS_CARRY then 
		return true
	else
		return false
	end
end

-- Прибытие на точку
local function IsPlayerOnPoint(ply)

	local cur_point = ply.Duty_Point
	local progress = ply.Duty_Progress or nil
	if not IsOnDuty(ply) then 
		return false, "Вы не на патруле" 
	end
	-- Добавим 50 на случай рассинхрона
	if ply:GetPos():Distance(cur_point) > (DUTIES_CONFIG.patrol_point_dist + 50) then 
		return false, "Вы слишком далеко от точки" 
	end
	return true
end

local function RegisterDutyLeader(ply, type, result)
	local type_tbl = duty_leaderboard[type]
	local cur_result = type_tbl[1] or 0
	local old_nick = type_tbl[2] or "-"
	local nick = ply:Nick()
	if result > cur_result then
		duty_leaderboard[type] = {result, nick}
		if nick == old_nick or (result - cur_result) < 1 then return end
		local type_name = "задачам"
		if type == 1 then
			type_name = "патрулям"
		elseif type == 2 then
			type_name = "постам"
		elseif type == 3 then
			type_name = "логистике"
		end
		ChatAddTextAll(Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "Боец ", Color(17, 148, 240), nick, Color(255, 255, 255), " стал лидером по ", Color(17, 148, 240), type_name, Color(255, 255, 255), " с результатом ", Color(17, 148, 240), tostring(result))
	end
end

local function AddDutyStat(ply, type, amount)
	local stats = ply.Duty_Stats or {0, 0, 0}
	stats[type] = stats[type] + amount
	ply.Duty_Stats = stats

	RegisterDutyLeader(ply, type, stats[type])
	local name = ply:Nick()
	local steamID = ply:SteamID()
	local time = math.Round(CurTime() - ply.Duty_Start_Time)
	local average = 0
	local message = "[LOR.Duty] "..name.." ("..steamID..") выполнил задачу "..type.." за "..time.." секунд."
	if type == 1 then
		average = time / (DUTIES_CONFIG.patrol_num_points + 2)
		message = message.." Среднее между точками: ".. average
	elseif type == 3 then
		average = time / amount
		message = message.." Среднее время на ящик: ".. average
	end
	--GmLogger.PostMessageInDiscord(message)
	ply.Duty_Start_Time = nil
end

-- Выбор следующей точки
local function SelectNextPatrolPoint(prev_point)

	local patrol_points = table.Copy(DUTIES_CONFIG.patrol_points)
	if prev_point then
		table.RemoveByValue(patrol_points, prev_point)
	end
	local new_point = patrol_points[math.random(1, #patrol_points)]
	return new_point
end

local function SendNextPatrolPoint(ply, force_point, prev_point)

	local point = SelectNextPatrolPoint(prev_point)
	local status = ply:GetNW2Int("Duty_Status", 0)
	
	if force_point then 
		point = force_point 
	end

	local progress = ply.Duty_Progress or 0

	ply.Duty_Point = point
	net.Start("RE.Duty.Patrol_Next")
		net.WriteVector(point)
		net.WriteInt(progress, 9)
		if status == DUTY_STATION_CHOOSING then
			net.WriteTable(duty_cur_stations)
		end
	net.Send(ply)
end

local function SendToNextPickup(ply, storage)

	local point
	local point_name = "Склад"
	if storage then
		point = table.Random(DUTIES_CONFIG.storage_points)
		ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "Направляйтесь за следующей коробкой! ")
	else
		point = DUTIES_CONFIG.drop_points[math.random(1, #DUTIES_CONFIG.drop_points)]
		point_name = point[2]
		point = point[1]
		ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "Направляйтесь к месту выгрузки: ", Color(17, 148, 240), point_name)
	end

	local progress = ply.Duty_Progress or 0

	ply.Duty_Point = point
	net.Start("RE.Duty.Patrol_Next")
		net.WriteVector(point)
		net.WriteInt(progress, 9)
	net.Send(ply)
end

local function StoragePickupBox(ply)
	ply.Duty_Point = nil
	
	ply:SetNW2Int("Duty_Status", DUTY_LOGISTICS_CARRY)
	GiveDutyBox(ply)
	--ply:Say("/me наклонился к коробке и поднял её")
	SendToNextPickup(ply)
end

local function DestinationDropBox(ply)
	ply.Duty_Point = nil
	
	ply:SetNW2Int("Duty_Status", DUTY_LOGISTICS)
	StripDutyBox(ply)
	--ply:Say("/me наклонился и поставил коробку на землю")
	SendToNextPickup(ply, true)

	local min = DUTIES_CONFIG.logistics_minimum
	local progress = ply.Duty_Progress

	-- TODO: Сделать ограничение в 255 коробок из-за установленного лимита net сообщения

	ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "Вы успешно доставили коробку. Двигайтесь обратно на склад!")
	if progress == min then
		ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "Вы выполнили норму в ", Color(0, 200, 0), min.." коробок", Color(255, 255, 255),". Можете продолжить работу или получить награду у терминала.")
	elseif progress < min then
		ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "Перенесите ещё ", Color(17, 148, 240), min-progress.." коробок", Color(255, 255, 255),", чтобы получить награду!")
	end
end

local function ArmoryPickup(ply)
	ply.Duty_Point = nil
	ply:Give(DUTIES_CONFIG.weapon)
	ply:SelectWeapon(DUTIES_CONFIG.weapon)
	local status = ply:GetNW2Int("Duty_Status", DUTY_NONE)

	if status == DUTY_PATROL_PREPARING then
		ply:SetNW2Int("Duty_Status", DUTY_PATROL)
		ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "Ваша задача: Передвигаться по точкам для патрулирования.")
		ChatAddText(ply, Color(17, 148, 240), "• ", Color(240, 65, 17), "Двигайтесь только шагом, оружие держите в руках на предохранителе.")
		ply.Duty_Progress = 0

		SendNextPatrolPoint(ply)
	elseif status == DUTY_STATION_PREPARING then
		ply:SetNW2Int("Duty_Status", DUTY_STATION_CHOOSING)
		ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "Выберите один из свободных постов.")
		ChatAddText(ply, Color(17, 148, 240), "• ", Color(255, 255, 255), "Чтобы выбрать пост - оставайтесь на месте.")
		ply.Duty_Progress = 0

		SendNextPatrolPoint(ply)
		timer.Adjust("Duty_Station_"..ply:SteamID64(), DUTIES_CONFIG.station_equip_time, 1, function() EndStation(ply) end)
	end
end

local function ArmoryDrop(ply)
	ply.Duty_Point = nil
	ply:StripWeapon(DUTIES_CONFIG.weapon)
	--ply:Say("/me вернул DC-15A в пирамиду")
end

local function AddStat( ply )
	local data = ply:GetMetadata( 'dutyStats', 0 )
	ply:SetMetadata( data + 1 )
end

-- Награда за патруль
local function GivePatrolAward(ply)

	local money = DUTIES_CONFIG.patrol_award_money
	local exp = DUTIES_CONFIG.patrol_award_exp

	ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "Вы получили ", Color(17, 148, 240), money.."РК", Color(255, 255, 255), " и ", Color(17, 148, 240), exp.."EXP", Color(255, 255, 255), " за патруль.")
	ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "В данный момент происходит настройка системы. После теста награды могут быть изменены!")
	ply:AddMoney(money)
	ply:AddCharExperience(exp)

	AddStat( ply )
end

-- Награда за патруль
local function GiveStationAward(ply)
	
	local money = DUTIES_CONFIG.station_award_money
	local exp = DUTIES_CONFIG.station_award_exp

	ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "Вы получили ", Color(17, 148, 240), money.."РК", Color(255, 255, 255), " и ", Color(17, 148, 240), exp.."EXP", Color(255, 255, 255), " за пост.")
	ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "В данный момент происходит настройка системы. После теста награды могут быть изменены!")
	ply:AddMoney(money)
	ply:AddCharExperience(exp)

	AddStat( ply )
end

-- Награда за коробки
local function GiveLogisticsAward(ply, progress)
	ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "Вы получили награду за ", Color(17, 148, 240), progress.." коробок", Color(255, 255, 255),"! Так держать!")

	
	local money = progress * DUTIES_CONFIG.logistics_award_money
	local exp = progress * DUTIES_CONFIG.logistics_award_exp

	ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "Вы получили ", Color(17, 148, 240), money.." РК", Color(255, 255, 255), " и ", Color(17, 148, 240), exp.." EXP", Color(255, 255, 255), " за перенесенные грузы: ", Color(17, 148, 240), progress)
	ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "В данный момент происходит настройка системы. После теста награды могут быть изменены!")
	ply:AddMoney(money)
	ply:AddCharExperience(exp)

	AddStat( ply )
end

-- Сброс точки за нарушение
local function CancelPoint(ply)

	ply.Duty_Progress = ply.Duty_Progress - 1

end

-- Завершение патруля
local function EndPatrol(ply)
	if not IsOnDuty(ply) then return "Вы не на патруле" end

	ArmoryDrop(ply)

	local progress = ply.Duty_Progress or 0
	local award_player = false
	ply.Duty_Progress = nil
	ply.Duty_Point = nil
	ply:SetNW2Int("Duty_Status", DUTY_NONE)

	if progress > DUTIES_CONFIG.patrol_num_points then
		GivePatrolAward(ply)
		award_player = true
		AddDutyStat(ply, 1, 1)
	else
		ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(240, 65, 17), "Выполнение задания было отменено!")
	end
	net.Start("RE.Duty.Patrol_End")
		net.WriteBool(award_player)
	net.Send(ply)
end

-- Завершение поста
local function EndStation(ply)
    local status = ply:GetNW2Int("Duty_Status", 0)
    if status < DUTY_STATION_PREPARING or status > DUTY_STATION_FINISH then return "Вы не на постовой службе" end

    ArmoryDrop(ply)

    local progress = ply.Duty_Progress or 0
    local award_player = false
    if timer.Exists("Duty_Station_"..ply:SteamID64()) then
        timer.Remove("Duty_Station_"..ply:SteamID64())
    end
    if ply.Duty_Station then
        duty_cur_stations[ply.Duty_Station] = nil
    end
    ply.Duty_Progress = nil
    ply.Duty_Station = nil
    ply.Duty_Point = nil
    ply:SetNW2Int("Duty_Status", DUTY_NONE)

	if progress > DUTIES_CONFIG.patrol_num_points then
		GiveStationAward(ply)
		award_player = true
		AddDutyStat(ply, 2, 1)
	else
		ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(240, 65, 17), "Выполнение задания было отменено!")
	end
	net.Start("RE.Duty.Patrol_End")
		net.WriteBool(award_player)
	net.Send(ply)
end

-- Завершение логистики
local function EndLogistics(ply)
	if not IsOnDuty(ply) then return "Вы не работаете" end

	StripDutyBox(ply)

	local progress = ply.Duty_Progress or 0
	local award_player = false
	ply.Duty_Progress = nil
	ply.Duty_Point = nil
	ply:SetNW2Int("Duty_Status", DUTY_NONE)

	if progress >= DUTIES_CONFIG.logistics_minimum then
		GiveLogisticsAward(ply, progress)
		award_player = true
		AddDutyStat(ply, 3, progress)
	else
		ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(240, 65, 17), "Выполнение задания было отменено!")
	end
	net.Start("RE.Duty.Patrol_End")
		net.WriteBool(award_player)
	net.Send(ply)
end

-- Прибытие на точку
local function PlayerArrived(ply)
	local prev_point = ply.Duty_Point
	ply.Duty_Point = nil

	local progress = ply.Duty_Progress or 0
	local status = ply:GetNW2Int("Duty_Status", DUTY_NONE)

	if status != DUTY_LOGISTICS then
		ply.Duty_Progress = progress + 1
	end

	net.Start("RE.Duty.Patrol_Arrived")
		net.WriteInt(progress, 9)
	net.Send(ply)

	timer.Simple(DUTIES_CONFIG.patrol_wait, function()

		if status == DUTY_LOGISTICS then
			StoragePickupBox(ply)
		elseif status == DUTY_LOGISTICS_CARRY then
			DestinationDropBox(ply)
		elseif status == DUTY_PATROL_PREPARING or status == DUTY_STATION_PREPARING then
			ArmoryPickup(ply)
		elseif status == DUTY_PATROL and ply.Duty_Progress < DUTIES_CONFIG.patrol_num_points then
			SendNextPatrolPoint(ply, nil, prev_point)
		elseif status == DUTY_PATROL and ply.Duty_Progress == DUTIES_CONFIG.patrol_num_points then
			ply:SetNW2Int("Duty_Status", DUTY_PATROL_FINISH)
			SendNextPatrolPoint(ply, DUTIES_CONFIG.armory_point) -- Отправка в оружейку для сдачи оружия (патруль)
		elseif status == DUTY_PATROL_FINISH then
			EndPatrol(ply) -- Сдача оружия в оружейке
		elseif status == DUTY_STATION_FINISH then
			EndStation(ply) -- Сдача оружия в оружейке
		end
	end)
end

-- Текстовые комаанды на случай бага на первое время
hook.Add( "PlayerSay", "RE.Duty", function( ply, text )
	if ( string.lower( text ) == "/patrol" ) then
		local check, msg = IsPlayerOnPoint(ply)
		if check then
			PlayerArrived(ply)
		else
			ChatAddText(ply, Color(17, 148, 240), "RE.Duty • ", Color(240, 65, 17), msg)
		end

		return ""
	end
	if ( string.lower( text ) == "/patrol_fail" ) then
		local check = IsOnDuty(ply)
		if check then
			CancelPoint(ply)
		end

		return ""
	end
end )

net.Receive("RE.Duty.Patrol_Arrived", function( len, ply )
	local status = ply:GetNW2Int("Duty_Status", 0)
	if status == DUTY_NONE then return end

	local check, msg = IsPlayerOnPoint(ply)
	if check then
		PlayerArrived(ply)
	else
		ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(240, 65, 17), msg)
	end
end )

net.Receive("RE.Duty.Fail", function( len, ply )
	local status = ply:GetNW2Int("Duty_Status", DUTY_NONE)
	if (status == DUTY_NONE) then return end

	if status == DUTY_STATION then
		local point = DUTIES_CONFIG.station_points[ply.Duty_Station]
		local dist = ply:GetPos():Distance(point)
		if dist > DUTIES_CONFIG.patrol_point_dist then
			EndStation(ply)
		end
	elseif status == DUTY_PATROL then
		CancelPoint(ply)
	end	
end )

net.Receive("RE.Duty.Station_Select", function( len, ply )
	local status = ply:GetNW2Int("Duty_Status", 0)
	if (status != DUTY_STATION_CHOOSING) then return end

	local point_id = net.ReadInt(9)
	local point = DUTIES_CONFIG.station_points[point_id]
	if not point then return end
	local occupant = duty_cur_stations[point_id]
	if IsValid(occupant) then
		if occupant.Duty_Station != point_id then
			duty_cur_stations[point_id] = nil
		else
			ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(240, 65, 17), "Этот пост уже занят. Выберите другой!")
			SendNextPatrolPoint(ply)
			return false
		end
	end

	ply:SetNW2Int("Duty_Status", DUTY_STATION)
	ply.Duty_Station = point_id
	duty_cur_stations[point_id] = ply

	net.Start("RE.Duty.Station_Select")
		net.WriteInt(point_id, 9)
	net.Send(ply)

	timer.Create("Duty_Station_"..ply:SteamID64(), DUTIES_CONFIG.station_wait, 1, function()
		if IsValid(ply) then
			ply:SetNW2Int("Duty_Status", DUTY_STATION_FINISH)
			duty_cur_stations[point_id] = nil
			ply.Duty_Station = nil
			ply.Duty_Progress = DUTIES_CONFIG.patrol_num_points
			SendNextPatrolPoint(ply, DUTIES_CONFIG.armory_point)
			ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "Вы успешно отстояли время на посту. Двигайтесь на сдачу оружия!")
			timer.Adjust("Duty_Station_"..ply:SteamID64(), DUTIES_CONFIG.station_equip_time, 1, function() EndStation(ply) end)
		end
	end)
end )

-- Инициализация патруля для игрока
function RE_Duty_Patrol_Init(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local access, error = CheckPatrolAccess(ply)
	if not access then ply:ChatPrint(error) return end

	ply.Duty_Progress = -2
	ply.Duty_Start_Time = CurTime()
	ply:SetNW2Int("Duty_Status", DUTY_PATROL_PREPARING)

	ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "Вы заступаете на патруль.")
	ChatAddText(ply, Color(17, 148, 240), "• ", Color(255, 255, 255), "Направляйтесь в арсенал для получения вооружения.")

	SendNextPatrolPoint(ply, DUTIES_CONFIG.armory_point)
end

-- Инициализация поста для игрока
function RE_Duty_Station_Init(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local access, error = CheckPatrolAccess(ply)
	if not access then ply:ChatPrint(error) return end

	ply.Duty_Progress = -2
	ply.Duty_Start_Time = CurTime()
	ply:SetNW2Int("Duty_Status", DUTY_STATION_PREPARING)

	ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "Вы заступаете на постовую службу.")
	ChatAddText(ply, Color(17, 148, 240), "• ", Color(255, 255, 255), "Направляйтесь в арсенал для получения вооружения.")

	SendNextPatrolPoint(ply, DUTIES_CONFIG.armory_point)
	timer.Create("Duty_Station_"..ply:SteamID64(), DUTIES_CONFIG.station_equip_time, 1, function() EndStation(ply) end)
end

-- Инициализация логистики для игрока
function RE_Duty_Logistics_Init(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local access, error = CheckPatrolAccess(ply)
	if not access then ply:ChatPrint(error) return end

	ply.Duty_Progress = 0
	ply.Duty_Start_Time = CurTime()
	ply:SetNW2Int("Duty_Status", DUTY_LOGISTICS)

	ChatAddText(ply, Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "Вы начали работу по переноске материалов.")
	ChatAddText(ply, Color(17, 148, 240), "• ", Color(255, 255, 255), "Двигайтесь на склад, получите коробку и отнесите её куда прикажут.")

	SendToNextPickup(ply, true)
end

local function Request_Duty(ply, duty_type)
	local status = ply:GetNW2Int("Duty_Status", DUTY_NONE)

	if ply:GetMoveType() == MOVETYPE_NOCLIP then 
		ChatAddText(ply, Color(17, 148, 240), "RE.Duty • ", Color(240, 65, 17), "Отставить! Вы в режиме полета!")
		return 
	end

	-- TODO: Добавить проверку что рядом есть терминал, а не то мамины хацкеры будут брать из любой точки карты

	if duty_type == 1 and status == DUTY_NONE then
		RE_Duty_Patrol_Init(ply)
	elseif duty_type == 2 and status == DUTY_NONE then
		RE_Duty_Station_Init(ply)
	elseif duty_type == 3 and status == DUTY_NONE then
		RE_Duty_Logistics_Init(ply)
	elseif duty_type == 0 then
		if status >= DUTY_PATROL_PREPARING and status <= DUTY_PATROL_FINISH then
			EndPatrol(ply)
		elseif status >= DUTY_STATION_PREPARING and status <= DUTY_STATION_FINISH then
			EndStation(ply)
		elseif status == DUTY_LOGISTICS then
			EndLogistics(ply)
		end
	end
end

net.Receive("RE.Duty.Request_Duty", function( len, ply )
	local duty_type = net.ReadUInt(2)
	Request_Duty(ply, duty_type)
end )

function GiveDutyBox(ply)
	if ply.bWearBox then return end
	net.Start('Duty.UpdateBoxStatus')
	net.WriteEntity(ply)
	net.WriteBool(true)
	net.Send(player.GetAll())
	ply.bWearBox = true
	ply:Give("weapon_duty_box")
	ply:EmitSound("physics/cardboard/cardboard_box_impact_soft2.wav")
	ply:SelectWeapon("weapon_duty_box")
end

function StripDutyBox(ply)
	net.Start('Duty.UpdateBoxStatus')
	net.WriteEntity(ply)
	net.WriteBool(false)
	net.Send(player.GetAll())
	ply.bWearBox = false
	ply:EmitSound("physics/cardboard/cardboard_box_impact_soft1.wav")
	ply:StripWeapon("weapon_duty_box")
end

hook.Add("KeyPress", "CheckPlayerJumping", function(ply, key)
	if key == IN_JUMP and ply.bWearBox then
		ply:SetNW2Int("Duty_Status", DUTY_LOGISTICS)
		StripDutyBox(ply)
		--ply:Say("/me уронил коробку с материалами")
		SendToNextPickup(ply, true)

		ply:EmitSound("physics/cardboard/cardboard_box_impact_hard2.wav")
		ChatAddText(ply, Color(17, 148, 240), "RE.Duty • ", Color(240, 65, 17), "Вы уронили ящик!")
	end
end)

hook.Add( "PlayerNoClip", "Duty_Noclip", function( ply, desiredNoClipState )
	local status = ply:GetNW2Int("Duty_Status", DUTY_NONE)
	if status == DUTY_NONE then return end
	if ( desiredNoClipState ) then
		if ply.bWearBox then
			ply:SetNW2Int("Duty_Status", DUTY_LOGISTICS)
			StripDutyBox(ply)
			--ply:Say("/me уронил коробку с материалами")
			SendToNextPickup(ply, true)

			ply:EmitSound("physics/cardboard/cardboard_box_impact_hard2.wav")
			ChatAddText(ply, Color(17, 148, 240), "RE.Duty • ", Color(240, 65, 17), "Вы уронили ящик!")
		elseif status == DUTY_PATROL then
			CancelPoint(ply)
		else
			Request_Duty(ply, 0)
		end
	end
end )