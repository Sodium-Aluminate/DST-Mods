print("这个 mod 还在测试阶段，可能会炸。")

setmetatable = GLOBAL.setmetatable
assert = GLOBAL.assert

TUNING.COM_NAALOH4_ALLOW_SWIM = (GetModConfigData("allowSwim") == 1) -- 1: can swim; 0: can't swim.

local NOT_HOOK = "NOT_HOOK"
local DISABLE_CHECK = "DISABLE_CHECK"
local CHECK_BUSY = "CHECK_BUSY"
local STRICT = "STRICT"

local BUSY_TAGS = {"busy","drowning"} -- 其实带溺水标签的都带繁忙，但是谁知道科雷以后怎么写呢
local STRICT_SG_TAGS = { "idle", "moving", "running" }

local function checkSG(sg, tags)
    for _, tag in ipairs(tags) do
        if (sg:HasStateTag(tag)) then
            return true
        end
    end
    return false
end
TUNING.COM_NAALOH4_CRAFT_CONDITION = ({
    [-1] = NOT_HOOK, -- use original code
    [0] = DISABLE_CHECK, -- allow any craft
    [1] = CHECK_BUSY, -- disallow craft when busy
    [2] = STRICT, -- only allow craft when idle/moving/running
})[GetModConfigData("banBusy")]

assert(TUNING.COM_NAALOH4_CRAFT_CONDITION)


--[[
返回一个新 table，其读写都对旧 table 操作，但是当访问 path 的时候会得到设置的 value 而不是真的的值
rawTable 应为一个 Table；
path 可以是数组也可以是字符串，如果是字符串则视为是包含该字符串的数组。

如 hookedBuilder = tableValueOverride(Builder, {"inst","sg","HasStateTag"}, hookedFn) 可以 hook 这个函数而不修改其他的东西。

]]
local rawTableKey = "com.NaAlOH4.tableValueOverride.rawTable"
local hookingPathKey = "com.NaAlOH4.tableValueOverride.hookingPath"
local targetValueKey = "com.NaAlOH4.tableValueOverride.targetValue"
local function tableValueOverride(rawTable, path, targetValue)
    local hookingPath = type(path) == "string" and { path } or path

    local metatable = {
        [rawTableKey] = rawTable,
        [hookingPathKey] = hookingPath,
        [targetValueKey] = targetValue,
    }
    function metatable:__index(key)

        local currentRawTable = self[rawTableKey]
        local currentHookingPath = self[hookingPathKey]
        local currentTargetValue = self[targetValueKey]
        if (#currentHookingPath == 0) then
            return currentRawTable[key]
        end
        if (currentHookingPath[1] == key) then
            if (#currentHookingPath == 1) then
                return currentTargetValue
            else
                local shadow = {}
                for i, v in ipairs(currentRawTable) do
                    if (i > 1) then
                        shadow[i - 1] = v
                    end
                end
                return tableValueOverride(currentRawTable[key], shadow, currentTargetValue)
            end
        end
        return currentRawTable[key]
    end

    function metatable:__newindex(key, value)
        self[rawTableKey][key] = value
    end

    return toReturn;
end

AddComponentPostInit("builder", function(Builder, instEntitiy)
    local oldMakeRecipeFn = Builder.MakeRecipe

    function Builder.MakeRecipe(Builder, recipe, pt, rot, skin, onsuccess)
        if (TUNING.COM_NAALOH4_CRAFT_CONDITION == NOT_HOOK) then
            return oldMakeRecipeFn(Builder, recipe, pt, rot, skin, onsuccess)
        end
        if (TUNING.COM_NAALOH4_CRAFT_CONDITION == DISABLE_CHECK) then
            local old_HasStateTag_fn = Builder.inst.sg.HasStateTag
            local HookedBuilder = tableValueOverride(Builder, { "inst", "sg", "HasStateTag", function(sg, tagName)
                if (tagName == "drowning") then
                    return not TUNING.COM_NAALOH4_ALLOW_SWIM;
                end
                if (tagName == "busy") then
                    -- 根据注释未来可能改为繁忙检测
                    return false
                end
                return old_HasStateTag_fn(sg, tagName)
            end })
            return oldMakeRecipeFn(HookedBuilder, recipe, pt, rot, skin, onsuccess)
        end
        if (TUNING.COM_NAALOH4_CRAFT_CONDITION == CHECK_BUSY) then
            if (checkSG(Builder.inst.sg, BUSY_TAGS)) then
                return false
            end
            return oldMakeRecipeFn(Builder, recipe, pt, rot, skin, onsuccess)
        end
        if (TUNING.COM_NAALOH4_CRAFT_CONDITION == STRICT) then
            if (checkSG(Builder.inst.sg, STRICT_SG_TAGS)) then
                return oldMakeRecipeFn(Builder, recipe, pt, rot, skin, onsuccess)
            end
            return false
        end
    end

end)

