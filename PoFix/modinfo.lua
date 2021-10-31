local applied_lang = (locale == "en" or locale == "zhr") and "en" or "zh"


local mname = {
	zh = "字符串替换",
	en = "Po Fix"
}
name = mname[applied_lang]

local mdescription = {
	zh = "替换游戏内的一些字串。",
	en = "Replace some strings in game."
}
description = mdescription[applied_lang]


author = "t.me/NaAlOH4"
version = "1.0"

api_version = 10
priority = 100
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
