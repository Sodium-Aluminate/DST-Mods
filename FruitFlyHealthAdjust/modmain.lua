local function init(inst)
	if inst.components.health then
		inst.components.health:SetMaxHealth(114514)		
	end
end
AddPrefabPostInit("friendlyfruitfly", init)

