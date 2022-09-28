
setmetatable = GLOBAL.setmetatable
assert = GLOBAL.assert
rawget = GLOBAL.rawget

L = require("log")
L:setDataDumper(GLOBAL.DataDumper)
L:loadEnv(env)
L = nil

TUNING.COM_NAALOH4_ALLOW_SWIM = (GetModConfigData("allowSwim") == 1) -- 1: can swim; 0: can't swim.

local NOT_HOOK = "NOT_HOOK"
local DISABLE_CHECK = "DISABLE_CHECK"
local CHECK_BUSY = "CHECK_BUSY"
local STRICT = "STRICT"

local BUSY_TAGS = { "busy", "drowning" } -- 其实带溺水标签的都带繁忙，但是谁知道科雷以后怎么写呢
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
    log("=========tableValueOverride=========")
    log("path: ")
    log(path)
    local hookingPath = type(path) == "string" and { path } or path or {}
    log("set hooking patch: ")
    log(hookingPath)
    --[[
    path        result
    "aaa"       {"aaa"}
    {"a","b"}   {"a","b"}
    nil         {}
    ]]

    local metatable = {
    }
    function metatable:__index(key)


        log("getting key: ")
        log(key)
        log("self: ")
        log(self, true)
        log("target keys: ")
        log(hookingPath)

        if (#hookingPath == 0) then
            log("find empty hook patch. returning: ")
            log(rawTable[key], true)
            return rawTable[key]
        end
        if (hookingPath[1] == key) then
            log("find key match.")
            if (#hookingPath == 1) then
                log("return value: ")
                log(targetValue)
                return targetValue
            else
                log("create new hook list:")
                local shadow = {}
                for i, v in ipairs(hookingPath) do
                    if (i > 1) then
                        shadow[i - 1] = v
                    end
                end
                log(shadow)
                return tableValueOverride(rawTable[key], shadow, targetValue)
            end
        end
        log("key not match. returning: ")
        log(rawTable[key], true)
        return rawTable[key]
    end

    function metatable:__newindex(key, value)
        rawget(self, rawTableKey)[key] = value
    end

    local toReturn = GLOBAL.setmetatable({}, metatable)
    return toReturn;
end

AddComponentPostInit("builder", function(Builder, instEntitiy)
    local oldMakeRecipeFn = Builder.MakeRecipe

    log("hooking MakeRecipe fn")
    function Builder.MakeRecipe(Builder, recipe, pt, rot, skin, onsuccess)
        log("hooked MakeRecipe fn")
        if (TUNING.COM_NAALOH4_CRAFT_CONDITION == NOT_HOOK) then
            log("config=NOT_HOOK, use original fn")
            return oldMakeRecipeFn(Builder, recipe, pt, rot, skin, onsuccess)
        end
        if (TUNING.COM_NAALOH4_CRAFT_CONDITION == DISABLE_CHECK) then
            log("config=DISABLE_CHECK, start hooking HasStateTag fn")
            local old_HasStateTag_fn = Builder.inst.sg.HasStateTag
            local HookedBuilder = tableValueOverride(Builder, { "inst", "sg", "HasStateTag"}, function(sg, tagName)
                if (tagName == "drowning") then
                    if (TUNING.COM_NAALOH4_ALLOW_SWIM) then
                        log("假装没淹死...")
                        return false
                    end
                end
                if (tagName == "busy") then
                    -- 根据注释未来可能改为繁忙检测
                    return false
                end
                return old_HasStateTag_fn(sg, tagName)
            end )
            log("using original fn with hooked argument.")
            return oldMakeRecipeFn(HookedBuilder, recipe, pt, rot, skin, onsuccess)
        end
        if (TUNING.COM_NAALOH4_CRAFT_CONDITION == CHECK_BUSY) then
            log("config=CHECK_BUSY, check player if busy")
            if (checkSG(Builder.inst.sg, BUSY_TAGS)) then
                log("found player busy, skip this craft.")
                return false
            end
            log("player not busy, use original fn to craft.")
            return oldMakeRecipeFn(Builder, recipe, pt, rot, skin, onsuccess)
        end
        if (TUNING.COM_NAALOH4_CRAFT_CONDITION == STRICT) then
            log("config=STRICT, check player if idle or walk")
            if (checkSG(Builder.inst.sg, STRICT_SG_TAGS)) then
                log("check passed, use original fn to craft")
                return oldMakeRecipeFn(Builder, recipe, pt, rot, skin, onsuccess)
            end
            log("check failed, skip this craft")
            return false
        end
    end

end)

