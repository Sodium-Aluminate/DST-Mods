local moduleList = require("moduleList")

local modules = {}
for _, moduleName in ipairs(moduleList) do
    local module = require(moduleName)
    if ((type(module.test) == "function") and (type(module.apply) == "function")) then
        module.priority = (type(module.priority) == "number") and module.priority or 0
        if (module.name and module.name ~= moduleName) then
            print('警告：模块"' .. moduleName .. '"的文件名与模块名不同，将按照文件名为准。')
        end
        module.name = moduleName
        table.insert(modules, module)
    end
end

if (#modules > 1) then
    local defaultModuleOrder = {}
    for i, v in ipairs(modules) do
        defaultModuleOrder[v] = i
    end
    table.sort(modules, function(a, b)
        return (a == b) and defaultModuleOrder[a] < defaultModuleOrder[b] or a.priority > b.priority
    end)
end

local function pcallWithErrorMsg(fn, ...)
    return GLOBAL.xpcall(fn, function(err)
        GLOBAL.TheNet:SystemMessage("命令执行过程出现了一个错误，回滚到原版命令行解析器。\n故障栈已经打印到标准输出和/或服务器日志。")
        GLOBAL.TheNet:SystemMessage("error: " .. tostring(err))

        print(tostring(err) .. "\n" .. GLOBAL.debug.traceback())
        return false, err
    end, ...)
end

local rawExecuteConsoleCommandFn = GLOBAL.ExecuteConsoleCommand
GLOBAL.ExecuteConsoleCommand = function(fnstr, guid, x, z)
    local disableOriginalExecutor = false
    local shouldContinue = true

    -- 暴力 try catch 一下
    for _, module in ipairs(modules) do
        local ok = pcallWithErrorMsg(function()
            if (module.test(fnstr, guid, x, z, env)) then
                local result = module.apply(fnstr, guid, x, z, env)
                result = (type(result) == "table") and result or {}
                if (not result.shouldContinue) then
                    shouldContinue = false
                elseif (result.disableOriginalExecutor) then
                    disableOriginalExecutor = true
                end
            end
        end)
        if (not ok) then
            GLOBAL.TheNet:SystemMessage("故障的模块为 " .. (module.name or "（未命名模块？）"))
        end
        if (not shouldContinue) then
            return
        end
    end


    if (not disableOriginalExecutor) then
        rawExecuteConsoleCommandFn(fnstr, guid, x, z)
    end
end