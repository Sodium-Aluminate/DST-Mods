TUNING = GLOBAL.TUNING
setmetatable = GLOBAL.setmetatable
type = GLOBAL.type
ipairs = GLOBAL.ipairs
assert = GLOBAL.assert


TUNING.COM_NAALOH4_ALLOW_SWIM=(GetModConfigData("allowSwim") == 1) -- 1: can swim; 0: can't swim.

TUNING.COM_NAALOH4_CRAFT_CONDITION=({
    [-1]="NOT_HOOK", -- use original code
    [0]= "DISABLE_CHECK", -- allow any craft
    [1]= "CHECK_BUSY", -- disallow craft when busy
    [2]= "STRICT", -- only allow craft when idle/moving/running
})[GetModConfigData("banBusy")]

assert(TUNING.COM_NAALOH4_CRAFT_CONDITION)


--[[
返回一个新 table，其读写都对旧 table 操作，但是当访问 path 的时候会得到设置的 value 而不是真的的值
rawTable 应为一个 Table；
path 可以是数组也可以是字符串，如果是字符串则视为是包含该字符串的数组。

如 hookedBuilder = tableValueOverride(Builder, {"inst","sg","HasStateTag"}, hookedFn) 可以 hook 这个函数而不修改其他的东西。

]]
local function tableValueOverride(rawTable, path, targetValue)
    local hookingPath = type(path)=="string" and {path} or path

    local toReturn = setmetatable({}, {
        ["com.NaAlOH4.tableValueOverride.rawTable"] = rawTable,
        ["com.NaAlOH4.tableValueOverride.hookingPath"] = hookingPath,
        ["com.NaAlOH4.tableValueOverride.targetValue"] = targetValue,
        __index = function(inst, key)

            local currentRawTable = inst["com.NaAlOH4.tableValueOverride.rawTable"]
            local currentHookingPath = inst["com.NaAlOH4.tableValueOverride.hookingPath"]
            local currentTargetValue = inst["com.NaAlOH4.tableValueOverride.targetValue"]
            if (#currentHookingPath == 0)then
                return currentRawTable[key]
            end
            if(currentHookingPath[1]==key)then
                if(#currentHookingPath == 1)then
                    return currentTargetValue
                else
                    local shadow = {}
                    for i, v in ipairs(currentRawTable) do
                        if (i > 1)then
                            shadow[i-1]=v
                        end
                    end
                    return tableValueOverride(currentRawTable[key], shadow, currentTargetValue)
                end
            end
            return currentRawTable[key]
        end,
        __newindex = function(inst, key, value)
            inst["com.NaAlOH4.tableValueOverride.rawTable"][key] = value
        end,
    })
end

AddComponentPostInit("builder", function(Builder, instEntitiy)
    oldMakeRecipeFn = Builder.MakeRecipe

    function Builder.MakeRecipe(Builder, recipe, pt, rot, skin, onsuccess)
        old_HasStateTag_fn = Builder.inst.sg.HasStateTag
        local HookedBuilder = tableValueOverride(Builder, {"inst","sg","HasStateTag", function(sg, tagName)
            if(tagName=="drowning")then

            end
        end})
        return oldMakeRecipeFn(HookedBuilder, recipe, pt, rot, skin, onsuccess)
    end

end)

