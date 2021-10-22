-- I used https://github.com/jupitersh/dst-mod-enhanced-houndius-shootius so the License is gpl v3
-- the source... is here. xd

local applied_lang = (locale == "en" or locale == "zhr") and "en" or "zh"

mname = {
	en = "Droppable Houndius Shootius++",
	zh = "眼球塔掉落++"
}
name = mname[applied_lang]

mdescription = {
	en = "not losing your Houndius Shootius anymore.",
	zh = "不再失去你那宝贵的眼球塔。"
}
description = mdescription[applied_lang]

author = "Koary (edited by NaAlOH4)"
version = "1.2"
api_version = 10
icon_atlas = "modicon.xml"
icon = "modicon.tex"
forumthread = "https://gugugu.p.naaloh4.com/kcir"
dst_compatible = true
all_clients_require_mod = true


yesStr="Enable √"
noStr="Disable ×"

dropLabel = "Drop after death"
dropHover = "Houndius Shootius drops himself after death"

hammerLabel = "Can hammer"
hammerHover = "players can use hammer on Houndius Shootius"

movableLabel = "can be moved"
movableHover = "players can move Houndius Shootius without hammer"

countLabel = "hammer counts"
countHover = "how many times to hammer a Houndius Shootius?"

if (applied_lang == "zh") then
	yesStr = "启用 √"
	noStr = "禁用 ×"
	dropLabel = "死亡掉落"
	dropHover = "眼球塔死亡时掉落其本身"
	hammerLabel = "可敲"
	hammerHover = "使眼球塔可被玩家或熊大敲击成为物品"
	movableLabel = "可移动"
	movableHover = "无需锤子直接带走眼球塔"
	countLabel = "敲击次数"
	countHover = "要敲击多少下可以搬走眼球塔？"
	
end

configuration_options =
{
	{
		name = "drop",
		label = dropLabel,
		hover = dropHover,
		options =	
			{
				{description = noStr, data = 0, hover = ""},
				{description = yesStr, data = 1, hover = ""}
			},
		default = 0,
	},
	{
		name = "hammer",
		label = hammerLabel,
		hover = hammerHover,
		options =	
			{
				{description = noStr, data = 0, hover = ""},
				{description = yesStr, data = 1, hover = ""}
			},
		default = 1,
	},
	{
		name = "movable",
		label = movableLabel,
		hover = movableHover,
		options =	
			{
				{description = noStr, data = 0, hover = ""},
				{description = yesStr, data = 1, hover = ""}
			},
		default = 0,
	},
	{
		name = "count",
		label = countLabel,
		hover = countHover,
		options =	
			{
				{description = "1", data = 1, hover = ""},
				{description = "2", data = 2, hover = ""},
				{description = "3", data = 3, hover = ""},
				{description = "4", data = 4, hover = ""},
				{description = "5", data = 5, hover = ""},
				{description = "10", data = 10, hover = ""},
				{description = "20", data = 20, hover = ""},
				{description = "75", data = 75, hover = ""},
				{description = "86", data = 86, hover = ""}
			},
		default = 3,
	}
}
