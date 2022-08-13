GLOBAL.TUNING.COM_NAALOH4_ALLOW_BUG_BOAT=(GetModConfigData("allowBugBoat") == 1)
GLOBAL.TUNING.COM_NAALOH4_KEEP_BUG_BOAT=(GetModConfigData("keepBugBoat") == 1)

AddStategraphPostInit("boat", function(inst_sg)
    local oldPlaceFn = inst_sg.states.place.events.animover.fn
    local oldIdleFn = inst_sg.states.idle.events.death.fn
    inst_sg.states.place.events.animover.fn = function(inst_boat,data)
        -- 如果开启了禁止无敌船，那么在船展开后重新给船回血来防止船死亡。
        if (not TUNING.COM_NAALOH4_ALLOW_BUG_BOAT) then
            inst_boat.components.health:SetPercent(1, false, nil)
        end
        return oldPlaceFn(inst_boat,data)
    end

    inst_sg.states.idle.events.death.fn = function(inst_boat, data)
        -- 如果是是读档造成的死亡，且开启了保护船的功能，那么忽略这次死亡。
        if (data and data.cause == "file_load" and TUNING.COM_NAALOH4_KEEP_BUG_BOAT) then
            return;
        end
        return oldIdleFn(inst_boat,data)
    end
end)