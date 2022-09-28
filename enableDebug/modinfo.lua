name = "enable debug"
description = [[
enable other NaAlOH4's mods log
]]
author = "NaAlOH4"
version = "1"
forumthread = ""
api_version = 10

dont_starve_compatible = false
reign_of_giants_compatible = false
dst_compatible = true
all_clients_require_mod = false
client_only_mod = false

-- icon = "xs.tex"

configuration_options = {
    {
        name = "_ALL",
        label = "启用所有 mod log",
        options = {
            { description = "false", data = false },
            { description = "true", data = true }
        },
        default = false
    }, {
        name = "BUGBOAT",
        label = "启用无敌船 mod log",
        options = {
            { description = "false", data = false },
            { description = "true", data = true }
        },
        default = false
    },
    {
        name = "SWIMAGAIN",
        label = "启用游泳 mod log",
        options = {
            { description = "false", data = false },
            { description = "true", data = true }
        },
        default = false
    }
}
