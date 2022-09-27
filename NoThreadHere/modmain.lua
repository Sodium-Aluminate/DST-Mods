local TaskList = {
    function()
        print("current time: 0")
    end,
    1.33,
    function()
        print("current time: 1.333")
    end,
    1.33,
    function()
        print("current time: 2.666")
    end,
    1.33,
    function()
        print("current time: 4")
    end,
}

local function _DoTask(taskList, step)
    if (step > #taskList) then
        return
    end
    local task = taskList[step]
    if (type(task) == "number") then
        GLOBAL.TheWorld:DoTaskInTime(task, function()
            _DoTask(taskList, step + 1)
        end)
        return
    end
    if (type(task) == "function") then
        task()
        _DoTask(taskList, step + 1)
    end
end

local function DoTask(--[[final]] taskList)
    assert(type(taskList) == "table")
    _DoTask(taskList, 1)
end

DoTask(TaskList)