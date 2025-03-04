if SERVER then return end

local terminal_main_panel

local function TerminalButton(parent, text, color)
	local activebuttonslidersize = 0
	local alphabutton = 180
	local button = vgui.Create("DButton", parent)
	button:SetPos(0, 0)
	button:SetSize(0, 0)
	button:SetText("")
	button:SetAlpha(255)

	button.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(32, 36, 41, alphabutton))
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.RoundedBox(0, 0, 0, activebuttonslidersize * w / 5, h, Color(255, 255, 255, 20))
		draw.ShadowSimpleText(text, luna.MontBaseTitle, w / 2, h / 2, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	button.OnCursorEntered = function()
		surface.PlaySound("luna_ui/click2.wav")
		alphabutton = 255
	end

	button.OnCursorExited = function()
		alphabutton = 200
	end
	return button
end

local function Patrol_Options(disable)

	local patrol_panel = vgui.Create("DFrame", terminal_main_panel)
	patrol_panel:SetPos(ScrW() * 0.5, ScrH() * 0.25)
	patrol_panel:SetSize(ScrW() * 0.35, ScrH() * 0.6)
	patrol_panel:SetTitle("")
	patrol_panel:SetVisible(true)
	patrol_panel:SetDraggable(false)
	patrol_panel:ShowCloseButton(false)
	patrol_panel:MakePopup()
	patrol_panel:SetAlpha(0)
	patrol_panel:AlphaTo(255, 0.5)
	
	patrol_panel.Paint = function(self, w, h)
		--BACKGROUND-----------
		--draw.RoundedBox(0, 0, 0, ScrW(), ScrH(), Color(64, 71, 79, 150))
		--surface.SetMaterial(Material("celestia/vignette.png"))

		draw.ShadowSimpleText("Патрулирование базы:", luna.MontBase54, w*0.5, h*0.1, Color(17, 148, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.ShadowSimpleText("Ваша задача - двигаться в указанные помещения для их проверки.", luna.MontBase22, w*0.5, h*0.1 + 50, Color(100,100,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.ShadowSimpleText("После прохождения всех помещений будет выдана награда.", luna.MontBase22, w*0.5, h*0.1 + 70, Color(100,100,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.ShadowSimpleText("Запрещено бегать, прыгать и отвлекаться от патруля!", luna.MontBase22, w*0.5, h*0.1 + 90, Color(100,100,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	patrol_panel:MakePopup()
	patrol_panel:DockPadding(0, patrol_panel:GetTall()*0.1 + 90, 0, 0)

	if LocalPlayer():GetNW2Int("Duty_Status", 0) > 0 then
		local start_button = TerminalButton(patrol_panel, "Отменить выполнение", Color(180, 49, 28))
		start_button:SetSize(ScrW() * 0.3, ScrH() * 0.1)
		start_button:Dock(BOTTOM)
		start_button:DockMargin(0, 15, 0, 15)
		start_button.DoClick = function()
			net.Start("RE.Duty.Request_Duty")
				net.WriteUInt(0, 2)
			net.SendToServer()
			terminal_main_panel:Close()
		end
	elseif not disable then
		local start_button = TerminalButton(patrol_panel, "Начать!", Color(17, 148, 240))
		start_button:SetSize(ScrW() * 0.3, ScrH() * 0.1)
		start_button:Dock(BOTTOM)
		start_button:DockMargin(0, 15, 0, 15)
		start_button.DoClick = function()
			net.Start("RE.Duty.Request_Duty")
				net.WriteUInt(1, 2)
			net.SendToServer()
			terminal_main_panel:Close()
		end
	end
end

local function Station_Options(disable)

	local station_panel = vgui.Create("DFrame", terminal_main_panel)
	station_panel:SetPos(ScrW() * 0.5, ScrH() * 0.25)
	station_panel:SetSize(ScrW() * 0.35, ScrH() * 0.6)
	station_panel:SetTitle("")
	station_panel:SetVisible(true)
	station_panel:SetDraggable(false)
	station_panel:ShowCloseButton(false)
	station_panel:MakePopup()
	station_panel:SetAlpha(0)
	station_panel:AlphaTo(255, 0.5)
	
	station_panel.Paint = function(self, w, h)
		--BACKGROUND-----------
		--draw.RoundedBox(0, 0, 0, ScrW(), ScrH(), Color(64, 71, 79, 150))
		--surface.SetMaterial(Material("celestia/vignette.png"))

		draw.ShadowSimpleText("Служба на посту:", luna.MontBase54, w*0.5, h*0.1, Color(17, 148, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.ShadowSimpleText("Ваша задача - находиться на выбранном посту в течение 6 минут.", luna.MontBase22, w*0.5, h*0.1 + 50, Color(100,100,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.ShadowSimpleText("Дежурство несется с оружием в руках на предохранителе.", luna.MontBase22, w*0.5, h*0.1 + 90, Color(100,100,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.ShadowSimpleText("Если вы покидаете пост досрочно - он не засчитывается!", luna.MontBase22, w*0.5, h*0.1 + 70, Color(100,100,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	station_panel:MakePopup()
	station_panel:DockPadding(0, station_panel:GetTall()*0.1 + 90, 0, 0)

	if LocalPlayer():GetNW2Int("Duty_Status", 0) > 0 then
		local end_button = TerminalButton(station_panel, "Отменить выполнение", Color(180, 49, 28))
		end_button:SetSize(ScrW() * 0.3, ScrH() * 0.1)
		end_button:Dock(BOTTOM)
		end_button:DockMargin(0, 15, 0, 15)
		end_button.DoClick = function()
			net.Start("RE.Duty.Request_Duty")
				net.WriteUInt(0, 2)
			net.SendToServer()
			terminal_main_panel:Close()
		end
	elseif not disable then
		local start_button = TerminalButton(station_panel, "Начать!", Color(17, 148, 240))
		start_button:SetSize(ScrW() * 0.3, ScrH() * 0.1)
		start_button:Dock(BOTTOM)
		start_button:DockMargin(0, 15, 0, 15)
		start_button.DoClick = function()
			net.Start("RE.Duty.Request_Duty")
				net.WriteUInt(2, 2)
			net.SendToServer()
			terminal_main_panel:Close()
		end
	end
end

-- local function Logistics_Options(disable)

-- 	local station_panel = vgui.Create("DFrame", terminal_main_panel)
-- 	station_panel:SetPos(ScrW() * 0.5, ScrH() * 0.25)
-- 	station_panel:SetSize(ScrW() * 0.35, ScrH() * 0.6)
-- 	station_panel:SetTitle("")
-- 	station_panel:SetVisible(true)
-- 	station_panel:SetDraggable(false)
-- 	station_panel:ShowCloseButton(false)
-- 	station_panel:MakePopup()
-- 	station_panel:SetAlpha(0)
-- 	station_panel:AlphaTo(255, 0.5)
	
-- 	station_panel.Paint = function(self, w, h)
-- 		--BACKGROUND-----------
-- 		--draw.RoundedBox(0, 0, 0, ScrW(), ScrH(), Color(64, 71, 79, 150))
-- 		--surface.SetMaterial(Material("celestia/vignette.png"))

-- 		draw.ShadowSimpleText("Переноска грузов:", luna.MontBase54, w*0.5, h*0.1, Color(17, 148, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
-- 		draw.ShadowSimpleText("Ваша задача - разносить коробки со склада по помещениям базы.", luna.MontBase22, w*0.5, h*0.1 + 50, Color(100,100,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
-- 		draw.ShadowSimpleText("Для получения награды отнесите минимум ".. DUTIES_CONFIG.logistics_minimum .." ящиков.", luna.MontBase22, w*0.5, h*0.1 + 90, Color(100,100,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
-- 		draw.ShadowSimpleText("Чем больше ящиков, тем больше награда!", luna.MontBase22, w*0.5, h*0.1 + 70, Color(100,100,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
-- 	end
-- 	station_panel:MakePopup()
-- 	station_panel:DockPadding(0, station_panel:GetTall()*0.1 + 90, 0, 0)

-- 	if LocalPlayer():GetNW2Int("Duty_Status", 0) > 0 then
-- 		local end_button = TerminalButton(station_panel, "Завершить выполнение", Color(180, 49, 28))
-- 		end_button:SetSize(ScrW() * 0.3, ScrH() * 0.1)
-- 		end_button:Dock(BOTTOM)
-- 		end_button:DockMargin(0, 15, 0, 15)
-- 		end_button.DoClick = function()
-- 			net.Start("RE.Duty.Request_Duty")
-- 				net.WriteUInt(0, 2)
-- 			net.SendToServer()
-- 			terminal_main_panel:Close()
-- 		end
-- 	elseif not disable then
-- 		local start_button = TerminalButton(station_panel, "Начать!", Color(17, 148, 240))
-- 		start_button:SetSize(ScrW() * 0.3, ScrH() * 0.1)
-- 		start_button:Dock(BOTTOM)
-- 		start_button:DockMargin(0, 15, 0, 15)
-- 		start_button.DoClick = function()
-- 			net.Start("RE.Duty.Request_Duty")
-- 				net.WriteUInt(3, 2)
-- 			net.SendToServer()
-- 			terminal_main_panel:Close()
-- 		end
-- 	end
-- end

local function Open_Terminal(active_duty_players, top_duty_players)

	local top_patrol_result, top_patrol_nick  = top_duty_players[1][1], top_duty_players[1][2]
	local top_station_result, top_station_nick = top_duty_players[2][1], top_duty_players[2][2]
	-- local top_logistics_result, top_logistics_nick = top_duty_players[3][1], top_duty_players[3][2]

	surface.PlaySound("luna_ui/blip1.wav")

	----------------------------------ОТКРЫТИЕПАНЕЛИ------------------------------------
	terminal_main_panel = vgui.Create("DFrame")
	terminal_main_panel:SetPos(0, 0)
	terminal_main_panel:SetSize(ScrW(), ScrH())
	terminal_main_panel:SetTitle("")
	terminal_main_panel:SetVisible(true)
	terminal_main_panel:SetDraggable(false)
	terminal_main_panel:ShowCloseButton(false)
	terminal_main_panel:MakePopup()
	terminal_main_panel:SetAlpha(0)
	terminal_main_panel:AlphaTo(255, 0.5)

	terminal_main_panel.Paint = function(self, w, h)
		Derma_DrawBackgroundBlur(self, self.startTime)
		--BACKGROUND-----------
		--draw.RoundedBox(0, 0, 0, ScrW(), ScrH(), Color(22, 23, 28, 150))
		draw.RoundedBox(0, w * 0.1, h * 0.1, w * 0.8, h * 0.8, Color(22, 23, 28, 150))
		-- surface.SetMaterial(Material("celestia/vignette.png"))
		-- surface.SetDrawColor(255, 255, 255, 255)
		-- surface.DrawTexturedRect(0, 0, w, h)

		--HEADER-----------
		draw.RoundedBox(0, w * 0.1, h * 0.1, w * 0.8, h * 0.1, Color(22, 23, 28, 150))
		surface.SetMaterial(Material("luna_icons/checkbox-tree.png"))
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect(w * 0.11, h * 0.11, h * 0.08, h * 0.08)
		draw.ShadowSimpleText("ЗАДАНИЯ НА ТЕРРИТОРИИ БАЗЫ", luna.MontBaseNormal, w * 0.17, h * 0.15, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end


	local closebutton = TerminalButton(terminal_main_panel, "X", color_white)
	closebutton:SetPos(ScrW() * 0.86, ScrH() * 0.125)
	closebutton:SetSize(ScrH() * 0.05, ScrH() * 0.05)
	closebutton.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(180, 49, 28, 255))
		draw.ShadowSimpleText("X", luna.MontBaseTitle, w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	closebutton.DoClick = function()
		terminal_main_panel:Remove()
		surface.PlaySound("luna_ui/pop.wav")
	end

	local info_panel = vgui.Create("DFrame", terminal_main_panel)
	info_panel:SetPos(ScrW() * 0.5, ScrH() * 0.25)
	info_panel:SetSize(ScrW() * 0.35, ScrH() * 0.6)
	info_panel:SetTitle("")
	info_panel:SetVisible(true)
	info_panel:SetDraggable(false)
	info_panel:ShowCloseButton(false)
	info_panel:MakePopup()
	info_panel:SetAlpha(0)
	info_panel:AlphaTo(255, 0.5)

	info_panel.Paint = function(self, w, h)
		--BACKGROUND-----------
		--draw.RoundedBox(0, 0, 0, ScrW(), ScrH(), Color(64, 71, 79, 150))
		--surface.SetMaterial(Material("celestia/vignette.png"))

		draw.ShadowSimpleText("Самые активные бойцы:", luna.MontBase54, w*0.5, h*0.2, Color(150,150,150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.ShadowSimpleText("В патруле: "..top_patrol_nick.." ("..top_patrol_result..")", luna.MontBase45, w*0.5, h*0.4, Color(100,100,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.ShadowSimpleText("На постах: "..top_station_nick.." ("..top_station_result..")", luna.MontBase45, w*0.5, h*0.6, Color(100,100,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		-- draw.ShadowSimpleText("Логистика: "..top_logistics_nick.." ("..top_logistics_result..")", luna.MontBase45, w*0.5, h*0.8, Color(100,100,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	local patrol_button = TerminalButton(terminal_main_panel, "ПАТРУЛИРОВАНИЕ  ".. active_duty_players[1] .. " / "..DUTIES_CONFIG.max_patrol_units, color_white)
	patrol_button:SetPos(ScrW() * 0.15, ScrH() * 0.25)
	patrol_button:SetSize(ScrW() * 0.3, ScrH() * 0.15)
	patrol_button.DoClick = function()
		Patrol_Options(active_duty_players[1] >= DUTIES_CONFIG.max_patrol_units)
	end

	local station_button = TerminalButton(terminal_main_panel, "ДЕЖУРСТВО НА ПОСТУ  ".. active_duty_players[2] .." / "..#DUTIES_CONFIG.station_points, color_white)
	station_button:SetPos(ScrW() * 0.15, ScrH() * 0.475)
	station_button:SetSize(ScrW() * 0.3, ScrH() * 0.15)
	station_button.DoClick = function()
		Station_Options(active_duty_players[2] >= #DUTIES_CONFIG.station_points)
	end

	-- local logistics_button = TerminalButton(terminal_main_panel, "ЛОГИСТИКА  ".. active_duty_players[3] .." / ∞", color_white)
	-- logistics_button:SetPos(ScrW() * 0.15, ScrH() * 0.7)
	-- logistics_button:SetSize(ScrW() * 0.3, ScrH() * 0.15)
	-- logistics_button.DoClick = function()
	-- 	Logistics_Options()
	-- end

end

net.Receive("RE.Duty.Open_Terminal", function()
	local active_duty_players = net.ReadTable()
	local top_duty_players = net.ReadTable()
	Open_Terminal(active_duty_players, top_duty_players)
end)
