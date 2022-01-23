--[[
这是一个演示 mod 用于说明如何修改友好果蝇的血量。
因为有人问这个问题：https://www.bilibili.com/read/cv14767820#reply99648155808
]]

local applied_lang = (locale == "en" or locale == "zhr") and "en" or "zh"

mname = {
	en = "friendlyfrultfly health adjust",
	zh = "友好果蝇血量调整"
}
name = mname[applied_lang]

mdescription = {
	en = "change friendlyfrultfly max hp",
	zh = "改变友好果蝇的血量"
}
description = mdescription[applied_lang]

author = "NaAlOH4"
version = "1.0"
api_version = 10
forumthread = "https://gugugu.p.naaloh4.com/kcir"
dst_compatible = true
all_clients_require_mod = true



configuration_options = {}
