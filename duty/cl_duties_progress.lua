if SERVER then return end

local re_duty_patrol_point = nil
local re_duty_patrol_progress = nil
local re_duty_end_time = nil

local re_duty_station_occupied = {}

local point_request_sent = false
local fail_request_sent = false
local station_request_sent = 0

local icon_size = 50
local mat_point =  Material('luna_ui_base/etc/usable.png', 'smooth noclamp')
local mat_armory = Material('luna_menus/inventory/dc-17_dual.png', 'smooth noclamp')
local mat_task =   Material("luna_ui_base/etc/usable.png", "noclamp smooth")
local mat_box =   Material("luna_icons/chest.png", "noclamp smooth")

local function DrawNextPatrolPoint(status)
	local point = re_duty_patrol_point
	if not point then return end
	local dist = LocalPlayer():GetPos():Distance(point)
	local dist_text = math.Round(dist/52.5)
	point = point + Vector(0,0,70)
	local icon_pos = point:ToScreen()
	local icon_color = color_white
	local icon_mat = mat_point

	if dist <= DUTIES_CONFIG.patrol_point_dist then

		icon_color = Color(17, 148, 240, 255)
		draw.ShadowSimpleText("Вы прибыли на точку. Ожидайте указаний!", luna.MontBase18, icon_pos.x, icon_pos.y+icon_size*0.75, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		if not point_request_sent then
			point_request_sent = true
			net.Start( "RE.Duty.Patrol_Arrived" )
			net.SendToServer()
			--LocalPlayer():ConCommand("say /patrol")
		end

	elseif status == DUTY_PATROL_PREPARING or status == DUTY_STATION_PREPARING then

		draw.ShadowSimpleText("Оружейная комната ("..dist_text.." м)", luna.MontBase18, icon_pos.x, icon_pos.y+icon_size*0.75, Color(17, 148, 240, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.ShadowSimpleText("(получите оружие)", luna.MontBase12, icon_pos.x, icon_pos.y+icon_size*1.1, Color(17, 148, 240, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		icon_mat = mat_armory

	elseif status == DUTY_PATROL_FINISH or status == DUTY_STATION_FINISH then

		draw.ShadowSimpleText("Оружейная комната ("..dist_text.." м)", luna.MontBase18, icon_pos.x, icon_pos.y+icon_size*0.75, Color(17, 148, 240, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.ShadowSimpleText("(сдайте оружие)", luna.MontBase12, icon_pos.x, icon_pos.y+icon_size*1.1, Color(17, 148, 240, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		icon_mat = mat_armory

	elseif status == DUTY_PATROL and fail_request_sent then

		draw.ShadowSimpleText("Штрафная точка ("..dist_text.." м)", luna.MontBase18, icon_pos.x, icon_pos.y+icon_size*0.75, Color(240, 65, 17, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.ShadowSimpleText("(нарушение правил патруля)", luna.MontBase12, icon_pos.x, icon_pos.y+icon_size*1.1, Color(240, 65, 17, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	-- elseif status == DUTY_LOGISTICS then

	-- 	draw.ShadowSimpleText("Склад ("..dist_text.." м)", luna.MontBase18, icon_pos.x, icon_pos.y+icon_size*0.75, Color(17, 148, 240, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	-- 	draw.ShadowSimpleText("(получите коробку)", luna.MontBase12, icon_pos.x, icon_pos.y+icon_size*1.1, Color(17, 148, 240, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	-- 	icon_mat = mat_box

	-- elseif status == DUTY_LOGISTICS_CARRY then

	-- 	draw.ShadowSimpleText("Отнесите коробку ("..dist_text.." м)", luna.MontBase18, icon_pos.x, icon_pos.y+icon_size*0.75, Color(17, 148, 240, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	-- 	icon_mat = mat_task
	else
		draw.ShadowSimpleText("Двигайся на точку ("..dist_text.." м)", luna.MontBase18, icon_pos.x, icon_pos.y+icon_size*0.75, Color(17, 148, 240, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	draw.Icon(icon_pos.x-icon_size*0.5,icon_pos.y-icon_size*0.5,icon_size,icon_size,icon_mat,icon_color)

end

local function DrawStationPoint(point, id)

	local dist = LocalPlayer():GetPos():Distance(point)
	local dist_text = math.Round(dist/52.5)
	point = point + Vector(0,0,70)
	local icon_pos = point:ToScreen()
	local icon_color = color_white
	local icon_mat = mat_point

	if dist <= DUTIES_CONFIG.patrol_point_dist then

		icon_color = Color(17, 148, 240, 255)
		draw.ShadowSimpleText("Оставайтесь на месте чтобы занять пост...", luna.MontBase18, icon_pos.x, icon_pos.y+icon_size*0.75, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.Icon(icon_pos.x-icon_size*0.5,icon_pos.y-icon_size*0.5,icon_size,icon_size,icon_mat,icon_color)
		if station_request_sent == 0 then
			-- Начинаем отсчет для заступления на пост
			station_request_sent = CurTime()
			surface.PlaySound("luna_sound_effects/info/infoobnovleno4.mp3")
		elseif not point_request_sent and station_request_sent + 3 <= CurTime() then
			-- Принимаем решение занять этот пост
			point_request_sent = true
			net.Start( "RE.Duty.Station_Select" )
				net.WriteInt( id, 9 )
			net.SendToServer()
		end

	else
		if station_request_sent + 5 <= CurTime() then
			if station_request_sent > 0 then 
				surface.PlaySound("luna_sound_effects/info/infoobnovleno3.mp3")
			end
			station_request_sent = 0
			draw.ShadowSimpleText("[#"..id.."] Свободный пост ("..dist_text.." м)", luna.MontBase18, icon_pos.x, icon_pos.y+icon_size*0.75, Color(17, 148, 240, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.Icon(icon_pos.x-icon_size*0.5,icon_pos.y-icon_size*0.5,icon_size,icon_size,icon_mat,icon_color)
		end

	end

end

local function DrawDutyStatus(title, desc, lines, timer, warning)
    local x_pos, y_pos = 20, 20

    local task = GetGlobalTable("EventTask")
    if task and task != {} and task.text != "" then y_pos = 350 end

    draw.Icon(x_pos, y_pos, 30, 30, mat_task)
    surface.SetFont(luna.MontBase30)
    local wtitle, _ = surface.GetTextSize(title)
    draw.ShadowSimpleText(title, luna.MontBase30, x_pos+40, y_pos+10, COLOR_HOVER, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    if timer and CurTime() < timer then
        local time_left = math.max(0, timer - CurTime())
        local time_color = color_white
        if warning then time_color = Color(240, 65, 17) end
        draw.ShadowSimpleText(string.ToMinutesSeconds(time_left), luna.MontBase30, x_pos+40 + wtitle + 15, y_pos+10, time_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    draw.ShadowSimpleText(desc, luna.MontBase18, x_pos+40, y_pos+40, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    for i, text in ipairs(lines) do
        if text == '' then continue end
        draw.ShadowSimpleText("⚫", luna.MontBase18, x_pos, y_pos+40 + (i * 18) + 15, COLOR_HOVER, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.ShadowSimpleText(text, luna.MontBase18, x_pos+14, y_pos+40 + (i * 18) + 15, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

local function DrawAvailableStations()
	local stations = re_duty_station_points or DUTIES_CONFIG.station_points

	for k,v in ipairs(stations) do
		if re_duty_station_occupied[k] == nil then
			DrawStationPoint(v, k)
		end
	end
end

local fail_timer = 0

local function DrawActiveStation()

    local cur_station = re_duty_patrol_point
    local radius = DUTIES_CONFIG.patrol_point_dist

	if LocalPlayer():GetPos():Distance(cur_station) > radius then
		local top_l = cur_station + radius * Vector(-1,1,0)
		local top_r = cur_station + radius * Vector(1,1,0)
		local bot_l = cur_station + radius * Vector(-1,-1,0)
		local bot_r = cur_station + radius * Vector(1,-1,0)
		top_l = top_l:ToScreen()
		top_r = top_r:ToScreen()
		bot_l = bot_l:ToScreen()
		bot_r = bot_r:ToScreen()


		surface.SetDrawColor( 17, 148, 240, 255 )
		surface.DrawLine( top_l.x, top_l.y, top_r.x, top_r.y)
		surface.DrawLine( bot_l.x, bot_l.y, bot_r.x, bot_r.y)
		surface.DrawLine( top_l.x, top_l.y, bot_l.x, bot_l.y)
		surface.DrawLine( bot_r.x, bot_r.y, top_r.x, top_r.y)

        if fail_timer == 0 then
            fail_timer = CurTime()
        end
        if fail_timer + DUTIES_CONFIG.station_leave_time <= CurTime() and not fail_request_sent then
            fail_request_sent = true
            net.Start("RE.Duty.Fail")
            net.SendToServer()
        end
    else
        fail_timer = 0
        fail_request_sent = false
    end
end

net.Receive( "RE.Duty.Patrol_Next", function( len )
	local point = net.ReadVector()
	local progress = net.ReadInt(9)
	local status = LocalPlayer():GetNW2Int("Duty_Status", 0)
	local stations = {}
	if status == DUTY_STATION_CHOOSING then
		stations = net.ReadTable() or {}
	end
	re_duty_station_occupied = stations
	re_duty_patrol_point = point
	re_duty_patrol_progress = progress
	point_request_sent = false
	fail_request_sent = false
	re_duty_end_time = CurTime() + DUTIES_CONFIG.station_equip_time

	--chat.AddText(Color(17, 148, 240), "RE.Duty • ", Color(255, 255, 255), "Получена новая точка на КПК. Двигайтесь туда!")
	surface.PlaySound("luna_sound_effects/info/infoobnovleno3.mp3")
end )

net.Receive( "RE.Duty.Patrol_Arrived", function( len )
	local progress = net.ReadInt(9)

	re_duty_patrol_progress = progress
	surface.PlaySound("luna_sound_effects/info/infoobnovleno4.mp3")
end )

net.Receive( "RE.Duty.Patrol_End", function( len )
	local award = net.ReadBool()

	re_duty_patrol_point = nil
	re_duty_patrol_progress = nil
	if award then
		chat.AddText(Color(17, 148, 240), "LOR.Duty • ", Color(0, 200, 0), "Вы успешно выполнили поставленную задачу!")
		surface.PlaySound("luna_ui/pop.wav")
	else
		surface.PlaySound("luna_sound_effects/info/infoobnovleno3.mp3")
	end
end )


net.Receive( "RE.Duty.Station_Select", function( len )
	local id = net.ReadInt(9)

	re_duty_patrol_point = DUTIES_CONFIG.station_points[id]
	re_duty_end_time = CurTime() + DUTIES_CONFIG.station_wait
	chat.AddText(Color(17, 148, 240), "LOR.Duty • ", Color(255, 255, 255), "Вы заступили на ", Color(17, 148, 240), "Пост #"..id, Color(255, 255, 255), ". Не покидайте его до конца времени.")
	surface.PlaySound("luna_sound_effects/info/infoobnovleno4.mp3")
end )

hook.Add( "HUDPaint", "HUD_Duty_Active", function()
	local status = LocalPlayer():GetNW2Int("Duty_Status", 0)
	local tasks = {}

	if status <= DUTY_NONE then return end

	local end_timer = DUTIES_CONFIG.station_leave_time-(CurTime()-fail_timer)

	-- TODO: Упростить эту часть

	if status == DUTY_STATION_CHOOSING then
		DrawAvailableStations()
	else
		DrawNextPatrolPoint(status)
	end

	if status == DUTY_PATROL and LocalPlayer():IsSprinting() and not fail_request_sent then
		fail_request_sent = true

		net.Start("RE.Duty.Fail")
		net.SendToServer()

		chat.AddText(Color(17, 148, 240), "LOR.Duty • ", Color(240, 65, 17), "Движение в патруле бегом запрещается! Данная точка будет вне зачёта.")
		surface.PlaySound("luna_characters/c_menu/heyyouthere.mp3")
	end

	if status == DUTY_STATION_CHOOSING then
		tasks[1] = "Выберите один из постов и встаньте на него"
		tasks[2] = "Не двигайтесь чтообы занять выбранный пост"
	end
	if status == DUTY_STATION_PREPARING or status == DUTY_STATION_CHOOSING or status == DUTY_STATION_FINISH then
		DrawDutyStatus("Постовая служба", DUTY_STATUS_TEXTS[status], tasks, re_duty_end_time, true)
	end
	if status == DUTY_STATION then
		DrawActiveStation()
		
		if fail_timer == 0 then
			tasks[1] = "Не покидайте границы поста до конца времени"
			tasks[2] = "Держите оружие в руках на предохранителе"
			DrawDutyStatus("Постовая служба", DUTY_STATUS_TEXTS[status], tasks, re_duty_end_time)
		else
			tasks[1] = "Вернитесь на пост! Осталось "..math.Round(end_timer).." сек"
			DrawDutyStatus("Постовая служба", DUTY_STATUS_TEXTS[status], tasks, fail_timer, true)
		end
	end

	if status >= DUTY_PATROL_PREPARING and status <= DUTY_PATROL_FINISH then
		if status == DUTY_PATROL then
			tasks[1] = "Пройдено точек патруля: ".. (re_duty_patrol_progress or 0) .. "/" .. DUTIES_CONFIG.patrol_num_points
			tasks[2] = "Двигайтесь только шагом с оружием на предохранителе"
		end
		DrawDutyStatus("Патрулирование", DUTY_STATUS_TEXTS[status], tasks)
	-- elseif status == DUTY_LOGISTICS or status == DUTY_LOGISTICS_CARRY then
	-- 	tasks[1] = "Перенесено коробок: ".. (re_duty_patrol_progress or 0) .. "/" .. DUTIES_CONFIG.logistics_minimum
	-- 	DrawDutyStatus("Логистика", DUTY_STATUS_TEXTS[status], tasks)
	end
end )

local function SetBoxBool(ply, wear)
	ply.bWearBox = wear

	if wear then
		local eModel = ClientsideModel('models/props_junk/cardboard_box003a.mdl')
		--eModel:SetColor( Color( 0, 255, 0, 230 ) ) 
		eModel.paretPlayer = ply
		ply.eModelBox = eModel
	else
		if ply and ply.eModelBox then
			ply.eModelBox:Remove()
		end
	end
end

net.Receive('Duty.UpdateBoxStatus', function()
	local ply = net.ReadEntity()
	-- local eEnt = data.eEnt or false
    local wear = net.ReadBool()

    SetBoxBool(ply, wear)
end)