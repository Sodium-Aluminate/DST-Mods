local DoTask = require("DoTask")
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
DoTask(TaskList, GLOBAL.TheWorld)