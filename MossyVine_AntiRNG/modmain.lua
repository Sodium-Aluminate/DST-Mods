local DistXZSq = GLOBAL.DistXZSq
local PI2 = GLOBAL.PI2
local MIN = TUNING.SHADE_CANOPY_RANGE_SMALL
local MAX = MIN + TUNING.WATERTREE_PILLAR_CANOPY_BUFFER
local NEW_VINES_SPAWN_RADIUS_MIN = 6
local OCEANVINES_FAMILY_RANGE = 4
local OCEANVINE_TAGS = { "OCEANVINE" }
local function spawnvine(inst)
    local tree_x, _, tree_z = inst.Transform:GetWorldPosition()

    local vine = GLOBAL.SpawnPrefab("oceanvine")
    vine.components.pickable:MakeEmpty()

    local lastvine
    if (inst.lastvine and inst.lastvine.Transform) then
        local x, _, z = inst.lastvine.Transform:GetWorldPosition()
        if (DistXZSq({ x = x, z = z }, { x = tree_x, z = tree_z }) < MAX) then
            lastvine = inst.lastvine
        end
    end
    inst.lastvine = vine -- 《LinkedList.java》

    local X, Z -- 即将生成的 vine 的位置
    if (lastvine) then
        -- 有上一个 vine 的时候用上一个 vine 的位置随机偏移
        local x, _, z = lastvine.Transform:GetWorldPosition() -- 上一个vine的位置
        for i = 1, 15 do
            local theta = math.random() * PI2
            local offset = (math.random() * OCEANVINES_FAMILY_RANGE + OCEANVINES_FAMILY_RANGE) / 2
            X = x + (offset * math.cos(theta))
            Z = z + (offset * math.sin(theta))

            if (DistXZSq({ x = X, z = Z }, { x = tree_x, z = tree_z }) < MAX and GLOBAL.TheWorld.Map:IsVisualGroundAtPoint(X, 0, Z)) then
                break
            else
                X = nil
                Z = nil
            end
        end

        -- fallback when random not working
        if (not (X and Z)) then
            X = 0.2 * tree_x + 0.8 * x
            Z = 0.2 * tree_z + 0.8 * x
        end
    else
        -- 随机roll位置吧
        for i = 1, 30 do
            local theta = math.random() * PI2
            local radius_variance = MAX - NEW_VINES_SPAWN_RADIUS_MIN
            local offset = NEW_VINES_SPAWN_RADIUS_MIN + radius_variance * math.random()

            X = tree_x + (offset * math.cos(theta))
            Z = tree_z + (offset * math.sin(theta))

            -- 前15次既要邻居藤蔓也要陆地；然后不管邻居只要陆地，最后一次直接放弃随便哪里都好
            if ((i > 15 or (#GLOBAL.TheSim:FindEntities(X, 0, Z, OCEANVINES_FAMILY_RANGE, OCEANVINE_TAGS) > 0)) and
                    (i >= 30 or GLOBAL.TheWorld.Map:IsVisualGroundAtPoint(X, 0, Z))
            ) then
                break
            else
                X = nil
                Z = nil
            end
        end
    end
    vine.Transform:SetPosition(X, 0, Z)
    vine:fall_down_fn()
    vine.SoundEmitter:PlaySound("dontstarve/movement/foley/hidebush")
end
local function startvines(inst)
    inst:DoTaskInTime(2 + math.random(),function() spawnvine(inst) end)
    inst:DoTaskInTime(2.5 + math.random(),function() spawnvine(inst) end)
    inst:DoTaskInTime(2.5 + math.random(),function() spawnvine(inst) end)
    if math.random() < 0.33 then
        inst:DoTaskInTime(3 + math.random(),function() spawnvine(inst) end)
    end
    inst.droppedvines = true
end

local debug = GLOBAL.debug
local error = GLOBAL.error
local Prefabs = GLOBAL.Prefabs
AddSimPostInit(function()
    local tree_fn = Prefabs.oceantree_pillar.fn
    local i = 1
    while (true) do
        local name, _ = debug.getupvalue(tree_fn, i)
        --GLOBAL.print(name)
        if (name == "startvines") then
            debug.setupvalue(tree_fn, i, startvines)
            break
        elseif name == nil then
            error('"spawnvine" fn not found, maybe klei changed code?')
        end
        i = i + 1
    end
end)