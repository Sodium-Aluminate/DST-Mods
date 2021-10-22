local applied_lang = (locale == "en" or locale == "zhr") and "en" or "zh"


local mname = {
    ["zh"] = "种子备注显示",
    ["en"] = "seed names fix"
}
name = mname[applied_lang]

local mdescription = {
	["zh"] = "帮你猜测种子叫啥。",
	["en"] = "help you understand what the unknown seed is."
}
description = mdescription[applied_lang]


author = "t.me/NaAlOH4"
version = "1.0"

api_version = 10
priority = -9000
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
dst_compatible = true

all_clients_require_mod = false
client_only_mod = true

icon_atlas = "Modicon.xml"
icon = "Modicon.tex"


server_filter_tags = {}

configuration_options = {}
