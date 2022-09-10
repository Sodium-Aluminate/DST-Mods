TUNING = GLOBAL.TUNING
TUNING.COM_NAALOH4_ALLOW_BUG_BOAT = (GetModConfigData("allowBugBoat") == 1)
TUNING.COM_NAALOH4_KEEP_BUG_BOAT = (GetModConfigData("keepBugBoat") == 1)
TUNING.COM_NAALOH4_ALLOW_BOAT_MOVE_ON_GROUND = (GetModConfigData("allowBoatMoveOnGround") == 1)
TUNING.COM_NAALOH4_ALLOW_STAGEHAND_BOAT_FLY = (GetModConfigData("allowStagehandBoatFly") == 1)
assert = GLOBAL.assert

AddStategraphPostInit("boat", function(inst_sg)
    local oldPlaceFn = inst_sg.states.place.events.animover.fn
    local oldIdleFn = inst_sg.states.idle.events.death.fn

    inst_sg.states.place.events.animover.fn = function(inst_boat, data)
        if TUNING.COM_NAALOH4_ALLOW_BUG_BOAT then
            inst_boat.sg:GoToState("idle")
        else
            return oldPlaceFn(inst_boat, data)
        end
    end

    inst_sg.states.idle.events.death.fn = function(inst_boat, data)
        -- 如果是是读档造成的死亡，且开启了保护船的功能，那么忽略这次死亡。
        if (data and data.cause == "file_load" and TUNING.COM_NAALOH4_KEEP_BUG_BOAT) then
            return ;
        end
        return oldIdleFn(inst_boat, data)
    end
end)

AddComponentPostInit("boatphysics", function(inst_component)
    local oldFn = inst_component.SetHalting
    inst_component.SetHalting = function(inst, shouldHalt)
        if (shouldHalt and TUNING.COM_NAALOH4_ALLOW_BOAT_MOVE_ON_GROUND) then
            print("游戏尝试搁浅一艘船，被咕了。")
        else
            oldFn(inst, shouldHalt)
        end
    end
end)

-- 一看源码的2^n就知道是搞位运算了，那么 CollidesWith 肯定是调用 c 层的位或。因为这俩值位或和加法结果一样，所以就直接加起来得了。
assert(GLOBAL.COLLISION.OBSTACLES == 512 and GLOBAL.COLLISION.SMALLOBSTACLES == 8192, "WTF")
local TARGET_COLLIDES_BITMASK = GLOBAL.COLLISION.OBSTACLES + GLOBAL.COLLISION.SMALLOBSTACLES

AddPrefabPostInit("stagehand", function(inst_prefab)
    local oldFn = inst_prefab.ChangePhysics
    inst_prefab.ChangePhysics = function(inst, is_standing)
        local oldStatus = inst:HasTag("blocker")
        oldFn(inst, is_standing)
        local newStatus = inst:HasTag("blocker") -- 这里逻辑可以简化，但我懒。

        if (newStatus and (newStatus ~= oldStatus) and TUNING.COM_NAALOH4_ALLOW_STAGEHAND_BOAT_FLY) then
            inst.Physics:CollidesWith(TARGET_COLLIDES_BITMASK)
        end
    end

    if (inst_prefab:HasTag("blocker") and TUNING.COM_NAALOH4_ALLOW_STAGEHAND_BOAT_FLY) then
        inst_prefab.Physics:CollidesWith(TARGET_COLLIDES_BITMASK)
    end
end)