name = "swim again"
description = [[
科雷你坏事作尽.jpg
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

configuration_options = {
    {
        name = "allowSwim",
        label = "游泳配置",
        hover = "制作物品时是否检查当前溺水状态",
        options = {
            { description = "禁止游泳", data = 0, hover = "与原版一样，如果在溺水状态则无法通过制作物品来打断" },
            { description = "允许游泳", data = 1, hover = "与旧版一样，可以通过制作物品来防止自己溺水" }
        },
        default = 1,
    },
    {
        name = "banBusy",
        label = "禁止解控",
        hover = "制作物品时检查当前状态吗？",
        options = {
            { description = "默认", data = -1, hover = "使用原版的检测逻辑。" },
            { description = "忽略", data = 0, hover = "除游泳外其他状态皆不检查，可以解除大部分控制" },
            { description = "繁忙", data = 1, hover = "玩家繁忙状态时无法制作物品，溺水时也不能" },
            { description = "激进", data = 2, hover = "玩家必须在立定或移动状态才能制作物品" },
        },
        default = 0,
    }
}