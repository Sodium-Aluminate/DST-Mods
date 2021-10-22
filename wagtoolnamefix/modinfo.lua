local applied_lang = (locale == "en" or locale == "zhr") and "en" or "zh"


local mname = {
	zh = "瓦格斯塔夫工具名称显示",
	en = "wagstaff tool names fix"
}
name = mname[applied_lang]

local mdescription = {
	zh = "让你看得懂瓦格斯塔夫想你索要的工具名字。",
	en = "let you understand which tool Wagstaff asking."
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
