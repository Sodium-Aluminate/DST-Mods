local events =
{

}

local states =
{
    State{
        name = "place",
        onenter = function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.place)
            inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/large",nil,.3)
            inst.AnimState:PlayAnimation("place")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
                if(not TUNING.COM_NAALOH4_ALLOW_BUG_BOAT) then
                    inst.components.health:SetPercent(1, false, nil)
                end
            end),
        },
    },

    State{
        name = "idle",
        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle_full", true)
        end,

        events =
        {
            EventHandler("death", function(inst)
                -- 如果是无敌船那么忽略读档造成的死亡
                if (inst.isBugBoat and TUNING.COM_NAALOH4_KEEP_BUG_BOAT) then
                    return;
                end
                inst.sg:GoToState("ready_to_snap")
            end),
        },
    },

    State{
        name = "ready_to_snap",
        onenter = function(inst)
            local ents = inst.components.walkableplatform:GetEntitiesOnPlatform()
            for ent in pairs(ents) do    
                ent:PushEvent("abandon_ship")
            end

            inst.sg:SetTimeout(0.75)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("snapping")
        end,
    },

    State{
        name = "snapping",
        onenter = function(inst)
            if inst.boat_crackle then
                local fx_boat_crackle = SpawnPrefab(inst.boat_crackle)
                fx_boat_crackle.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
            inst.AnimState:PlayAnimation("crack")
            inst.sg:SetTimeout(1)

            for k in pairs(inst.components.walkableplatform:GetPlayersOnPlatform()) do
                k:PushEvent("onpresink")
            end
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("popping") end),
        },

        timeline =
        {
            TimeEvent(0 * FRAMES, function(inst)
                if inst.sounds.creak then inst.SoundEmitter:PlaySoundWithParams(inst.sounds.creak) end
                if inst.leaky then inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/fountain_small_LP", "small_leak") end
            end),
            TimeEvent(2 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams(inst.sounds.damage,{intensity= .1})
            end),
            TimeEvent(17 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams(inst.sounds.damage,{intensity= .2})
            end),
            TimeEvent(32* FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams(inst.sounds.damage,{intensity= .3})
            end),
            TimeEvent(39* FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams(inst.sounds.damage,{intensity= .3})
            end),
            TimeEvent(39* FRAMES, function(inst)
                if inst.sounds.creak then inst.SoundEmitter:PlaySoundWithParams(inst.sounds.creak) end
            end),
            TimeEvent(51 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams(inst.sounds.damage,{intensity= .4})
            end),
            TimeEvent(58 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams(inst.sounds.damage,{intensity= .4})
            end),
            TimeEvent(60 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams(inst.sounds.damage,{intensity= .5})
            end),
            TimeEvent(71 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams(inst.sounds.damage,{intensity= .5})
            end),
            TimeEvent(75 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams(inst.sounds.damage, {intensity= .6})
            end),
            TimeEvent(82 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams(inst.sounds.damage, {intensity= .6})
            end),
        },
    },

    State{
        name = "popping",
        onenter = function(inst)
            inst.sinkloot()
            if inst.postsinkfn then
                inst:postsinkfn()
            end
            inst:Remove()
        end,
    },
}

return StateGraph("boat", states, events, "idle")
