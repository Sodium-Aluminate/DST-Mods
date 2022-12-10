local moduleList = require("moduleList")

local modules = {}
for _, moduleName in ipairs(moduleList) do
    local module = require(moduleName)
    if ((type(module.test) == "function") and (type(module.apply) == "function")) then
        module.priority = (type(module.priority) == "number") and module.priority or 0
        table.insert(modules, module)
    end
end

if (#modules > 1) then
    -- if 只是为了销毁 table
    local defaultModuleOrder = {}
    for i, v in ipairs(modules) do
        defaultModuleOrder[v] = i
    end
    table.sort(modules, function(a, b)
        return (a == b) and defaultModuleOrder[a] < defaultModuleOrder[b] or a.priority > b.priority
    end)
end

local rawExecuteConsoleCommandFn = GLOBAL.ExecuteConsoleCommand
GLOBAL.ExecuteConsoleCommand = function(fnstr, guid, x, z)
    local disableOriginalExecutor = false
    for _, module in ipairs(modules) do
        if(module.test(fnstr, guid, x, z, env)) then
            local result = module.apply(fnstr, guid, x, z, env)
            result = (type(result) == "table") and result or {}
            if(not result.shouldContinue)then
                return
            elseif (result.disableOriginalExecutor) then
                disableOriginalExecutor = true
            end
        end
    end

    if(not disableOriginalExecutor)then
        rawExecuteConsoleCommandFn(fnstr, guid, x, z)
    end
end