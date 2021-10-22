local ACTIONS = GLOBAL.ACTIONS
local SpawnPrefab = GLOBAL.SpawnPrefab

local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")
	inst:Remove()
	GLOBAL.SpawnPrefab("eyeturret_item").Transform:SetPosition(inst.Transform:GetWorldPosition())

end

local function init(inst)
	if (GetModConfigData("drop") == 1) then
		inst:AddComponent("lootdropper")
		inst.components.lootdropper:SetLoot({"eyeturret_item"})
	end
	
	if (GetModConfigData("hammer") == 1) then
		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
		inst.components.workable:SetWorkLeft(GetModConfigData("count"))
		inst.components.workable:SetOnFinishCallback(onhammered)
	end
	
	-- code from https://github.com/jupitersh/dst-mod-enhanced-houndius-shootius 
	-- 有大量改动，希望能跑.jpg
	if (GetModConfigData("movable") == 1) then
		inst:AddComponent("machine")
		inst.components.machine.turnonfn = function(inst)
			inst.on = true
			inst:Remove()
			GLOBAL.SpawnPrefab("eyeturret_item").Transform:SetPosition(inst.Transform:GetWorldPosition())
		end
	end
end

AddPrefabPostInit("eyeturret", init)
