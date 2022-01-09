local applied_lang = (locale == "en" or locale == "zhr") and "en" or "zh"


local mname = {
	zh = "藤条反随机",
	en = "MossyVine AntiRNG"
}
name = mname[applied_lang]

local mdescription = {
	zh = "藤条刷在岸上很难，对吗？",
	en = "It's rare for vine to spawn in the land, right?"
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

all_clients_require_mod = true
client_only_mod = false

--icon_atlas = "Modicon.xml"
--icon = "Modicon.tex"


server_filter_tags = {}

configuration_options = {}
