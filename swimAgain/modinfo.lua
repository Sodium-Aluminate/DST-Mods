name = "swim again"
description = [[
《科雷你坏事作尽》
科雷增加了制作物品时不能在溺水状态的限制，也就是玩家在卡海游泳时很多事情都干不了了。
以下选项可以修改制作动作的进入条件。
你可以通过修改服务端 TUNING.COM_NAALOH4_ALLOW_SWIM 和 TUNING.COM_NAALOH4_CRAFT_CONDITION 的值来临时性测试其他的配置。
]]
author = "NaAlOH4"
version = "1.0.1"
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
            { description = "禁止游泳 (true)", data = 0, hover = "与原版一样，如果在溺水状态则无法通过制作物品来打断。" },
            { description = "允许游泳 (true)", data = 1, hover = "与旧版一样，可以通过制作物品来防止自己溺水。" }
        },
        default = 1,
    },
    {
        name = "banBusy",
        label = "禁止解控",
        hover = "制作物品时检查当前状态吗？",
        options = {
            { description = "默认 (\"NOT_HOOK\")", data = -1, hover = "使用原版的检测逻辑，开启此选项等价于关闭模组。" },
            { description = "忽略 (\"DISABLE_CHECK\")", data = 0, hover = "除溺水外其他状态皆不检查，是否可以打断溺水由“游泳配置决定”。" },
            { description = "繁忙 (\"CHECK_BUSY\")", data = 1, hover = "玩家繁忙状态时无法制作物品，当然包括溺水。" },
            { description = "激进 (\"STRICT\")", data = 2, hover = "玩家必须在立定或移动状态才能制作物品，用于特别不希望客户端作弊的情况。" },
        },
        default = 0,
    }
}
