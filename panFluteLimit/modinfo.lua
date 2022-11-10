-- klei yydsb，modinfo环境不给我传lua基本函数指针，也不给 GLOBAL。参见 官方代码/modindex.lua:594 (ModIndex:InitializeModInfo)

local l = (locale == "en" or locale == "zhr") and "en" or "zh"

name = ({ en = "pan flute limit", zh = "排箫次数限制" })[l]

description = ({ en = "change the max usage count of pan flute.", zh = "更改排箫使用次数" })[l]

author = "NaAlOH4"
version = "1.0"
api_version = 10
--icon_atlas = "modicon.xml"
--icon = "modicon.tex"
forumthread = ""
dst_compatible = true
all_clients_require_mod = false
client_only_mod = false

local function genNumberOptions(from,to)
	local numberOptions={}
	for i =1,10 do
		numberOptions[i]= {description=i,data=i,hover=""}
	end
	return numberOptions
end


configuration_options = {
	{
		name = "MIN_USAGE",
		label = ({ en = "min usage", zh = "最小耐久" })[l],
		hover = "",
		options = genNumberOptions(1,10),
		default = 3,
	},
	{
		name = "MAX_USAGE",
		label = ({ en = "max usage", zh = "最大耐久" })[l],
		hover = "",
		options = genNumberOptions(1,10),
		default = 5,
	},
	{
		name = "RANDOM_USAGE_LOGIC",
		label = ({ en = "random usage logic", zh = "随机耐久逻辑" })[l],
		hover = "",
		options = {
			{
				description = ({ en = "always min", zh = "使用最小耐久" })[l],
				data = "ALWAYS_MIN",
				hover = ({ en = "ignore \"max usage\" option", zh = "忽略\"最大耐久\"参数" })[l]
			},
			{
				description = ({ en = "random when spawn", zh = "生成时随机耐久" })[l],
				data = "RANDOM_WHEN_GEN",
				hover = ({ en = "player can predict the usage times", zh = "玩家可以预测使用次数" })[l]
			},
			{
				description = ({ en = "random broke when usage", zh = "使用时随机损坏" })[l],
				data = "RANDOM_WHEN_USAGE",
				hover = ({ en = "player can't predict the usage times. it will broke randomly when usage count>min usage", zh = "玩家无法预测使用次数，当使用次数大于最小耐久时就会随机损坏" })[l]
			},
		},
		default = "RANDOM_WHEN_USAGE",
	},
}

