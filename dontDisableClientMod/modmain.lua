assert = GLOBAL.assert
debug = GLOBAL.debug

if (not (GLOBAL.KnownModIndex and GLOBAL.KnownModIndex.GetClientModNamesTable)) then
    return
end

local oldFn = GLOBAL.KnownModIndex.GetClientModNamesTable
function GLOBAL.KnownModIndex:GetClientModNamesTable()
    local stackStr = GLOBAL.StackTrace()
    print("checking stack...")
    print(stackStr)

    if (stackStr:find("2860210553")) then
        print("found, return empty table.")
        return {}
    else
        print("not found.")
    end

    return oldFn(self)
end
