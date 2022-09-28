local t = {}

t.DataDumper = DataDumper or (GLOBAL and GLOBAL.DataDumper) or function()
    return "can't find DataDumper"
end

function t:loadEnv(env)
    env.log = function(obj, notDump)
        if
        ((type(TUNING.COM_NAALOH4_DEBUG) == "boolean") and TUNING.COM_NAALOH4_DEBUG)
                or (type(TUNING.COM_NAALOH4_DEBUG) == "table" and TUNING.COM_NAALOH4_DEBUG[env.modname:upper()])
                or env.debug
        then
            local objType = type(obj)
            if (notDump or objType == "nil" or objType == "number" or objType == "string") then
                print(obj)
            else
                print(t.DataDumper(obj))
            end
        end
    end
end
function t:setDataDumper(DataDumper)
    t.DataDumper = DataDumper
end

return t