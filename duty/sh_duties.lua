hook.Add('CalcMainActivity', 'Fabrik_CalcMainActivity', function(pPlayer, velocity)
	if pPlayer.bWearBox then
		if CLIENT and pPlayer == LocalPlayer() then
			local eModel = pPlayer.eModelBox or false

			if thirdperson_enabled then
				eModel:SetNoDraw(false)
			else
				eModel:SetNoDraw(true)
			end
		end

		return ACT_HL2MP_RUN_DUEL, -1
	end
end)

hook.Add('PostPlayerDraw', 'Fabrik_PostPlayerDraw', function(pPlayer)
	if pPlayer.bWearBox then
		local eModel = pPlayer.eModelBox or false

		if eModel then
			local bone = pPlayer:LookupBone('ValveBiped.Bip01_R_Hand')

			if bone then
				local matrix_bone = pPlayer:GetBoneMatrix(bone)

				if matrix_bone then
					local ang = matrix_bone:GetAngles()
					ang:RotateAroundAxis(ang:Forward(), 0)
					ang:RotateAroundAxis(ang:Right(), 0)
					ang:RotateAroundAxis(ang:Up(), -10)
					eModel:SetAngles(ang)
					eModel:SetModelScale(0.6)
					-- eModel:SetNoDraw(true)
					local pos = pPlayer:GetBonePosition(bone) + ang:Right() * 11 + ang:Forward() * -6
					eModel:SetPos(pos)
				end
			end
		end
	end
end)