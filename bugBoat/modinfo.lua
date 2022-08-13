---
--- Generated by Luanalysis
--- Created by sodiumaluminate.
--- DateTime: 2021/12/18 下午6:54
---

name = "bug boat"
description = [[
无敌船配置二则
]]
author = "NaAlOH4"
version = "1.0"
forumthread = ""
api_version = 10

dont_starve_compatible = false
reign_of_giants_compatible = false
dst_compatible = true
all_clients_require_mod = false
client_only_mod = false

-- icon = "xs.tex"

configuration_options =
{
    {
        name = "allowBugBoat",
        label = "允许无敌船",
        hover = "是否能通过经典手段获取无敌船",
        options =
        {
            { description = "禁止", data = 0, hover = "正常的获取无敌船手段被修复"},
            { description = "允许", data = 1, hover = "和原版游戏相同"}
        },
        default = 1,
    },
    {
        name = "keepBugBoat",
        label = "保护无敌船",
        hover = "防止读取存档后无敌船沉掉",
        options =
        {
            { description = "禁用", data = 0 , hover = "和原版游戏相同"},
            { description = "启用", data = 1 , hover = "你到底是手残还是想拿船当造家装饰物？"},
        },
        default = 0,
    }
}
