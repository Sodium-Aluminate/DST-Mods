local function _DoTask(taskList, step, attachedEntity)
    local TargetAttachedEntity = attachedEntity or TheWorld or GLOBAL.TheWorld
    if (step > #taskList) then
        return
    end
    local task = taskList[step]
    if (type(task) == "number") then
        TargetAttachedEntity:DoTaskInTime(task, function()
            _DoTask(taskList, step + 1)
        end)
        return
    end
    if (type(task) == "function") then
        task()
        _DoTask(taskList, step + 1)
    end
end

local function DoTask(--[[final]] taskList, attachedEntity)
    assert(type(taskList) == "table")
    _DoTask(taskList, 1,attachedEntity)
end

return DoTask