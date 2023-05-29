
local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local AddPrefabPostInit = ENV.AddPrefabPostInit
local AddComponentPostInit = ENV.AddComponentPostInit

local says = {
	["english.po"] = "I think it should no longer be able to generate",
	["french.po"] = "Je pense qu'il ne devrait plus être capable de générer",
	["spanish.po"] = "Creo que ya no debería poder generar",
	["german.po"] = "Ich denke, es sollte nicht mehr generieren können",
	["italian.po"] = "Penso che non dovrebbe più essere in grado di generare",
	["portuguese_br.po"] = "Eu acho que não deveria mais ser capaz de gerar",
	["polish.po"] = "Myślę, że nie powinien już móc generować",
	["russian.po"] = "Я думаю, что он больше не может генерировать",
	["korean.po"] = "더 이상 생성할 수 없을 것 같습니다",
	["chinese_s.po"] = "我想它应该不再能生成了",
	["chinese_t.po"] = "我想它應該不再能生成了",
}

local say = says[LOC.GetLocale().strings] or says["english.po"]

AddPrefabPostInit("bomb_lunarplant", function(inst_prefab)
	if not ((TheWorld and TheWorld.ismastersim)) then
		return
	end

	local bomb_lunarplant = inst_prefab
	local oldOnHitFn = bomb_lunarplant.components.complexprojectile.onhitfn

	bomb_lunarplant.components.complexprojectile:SetOnHit(
			function(inst, attacker, target)
				local x, y, z = inst.Transform:GetWorldPosition()
				local portals = TheSim:FindEntities(x, y, z, TUNING.BOMB_LUNARPLANT_RANGE, { "lunarrift_portal" })
				if (#portals > 0) then
					if (TheWorld and TheWorld.components and TheWorld.components.riftspawner) then
						print("sending close rift event")
						TheWorld:PushEvent("lunarrift_closed")
						if (attacker and attacker:IsValid() and attacker:HasTag("player")
								and attacker.components and attacker.components.talker
						) then
							attacker.components.talker:Say(say)
						end
					else
						print("存在裂隙，但是没有 riftspawner 的世界？")
					end
				end
				oldOnHitFn(inst, attacker, target)
			end
	)
end)

local RIFTSPAWN_TIMERNAME = "rift_spawn_timer"
AddComponentPostInit("riftspawner", function(inst_component)
	if not ((TheWorld and TheWorld.ismastersim)) then
		return
	end
	local RiftSpawner = inst_component

	RiftSpawner.inst:ListenForEvent("lunarrift_closed", function(...)
		RiftSpawner:DisableLunarRifts(...)
	end)

	function RiftSpawner.DisableLunarRifts(self, src)
		self.lunar_rifts_enabled = false
		--self._worldsettingstimer:StopTimer(RIFTSPAWN_TIMERNAME)
		print("lunar rift closed")
	end
end)
