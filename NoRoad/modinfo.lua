local l = (locale == "en" or locale == "zhr") and "en" or "zh"

_name = {
	en="hide road",
	zh="隐藏小路"
}
name = _name[l]

_description = {
	en= "hide rode for your OCD(it still exists but just hidden)",
	zh= "为了建家强迫症隐藏小路(只是视觉上隐藏而已)"
}
description = _description[l]


author = "NaAlOH4、Tony、秋一(<-还搞了 tex)"
version = "1.0"

icon_atlas = "modicon.xml"
icon = "modicon.tex"

dst_compatible = true
client_only_mod = true
all_clients_require_mod = false

api_version = 10
