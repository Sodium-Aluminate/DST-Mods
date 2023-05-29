-- 感谢 chatgpt，帮我编出了官方都没来得及翻译的东西（管他对不对呢.jpg）

local strs = {
	en = {
		name = "blow up the rift",
		description = "Use a brightshade Bomb to prevent rift generation",
	},
	fr = {
		name = "faire exploser la faille",
		description = "Utilisez une bombe lumineuse pour empêcher la génération de failles",
	},
	es = {
		name = "hacer explotar la grieta",
		description = "Usa una bomba de brillo para evitar la generación de grietas",
	},
	de = {
		name = "die Kluft sprengen",
		description = "Verwende eine Helligkeitsbombe, um die Bildung von Kluften zu verhindern",
	},
	it = {
		name = "far esplodere la fessura",
		description = "Usa una bomba luminosa per impedire la generazione di fessure",
	},
	pt = {
		name = "explodir a fenda",
		description = "Use uma bomba brilhante para evitar a geração de fendas",
	},
	pl = {
		name = "wybuchnij szczelinę",
		description = "Użyj jasnobomby, aby zapobiec generowaniu szczelin",
	},
	ru = {
		name = "взорвать рифт",
		description = "Используйте яркую бомбу, чтобы предотвратить образование рифтов",
	},
	ko = {
		name = "분화로 눈깜짝할 새에 찢어버려라",
		description = "밝은그림자 폭탄을 사용하여 분화 생성 방지",
	},
	zh = {
		name = "炸裂隙",
		description = "使用亮茄炸弹让裂隙不再生成",
	},
	zht = {
		name = "炸裂隙",
		description = "使用亮茄炸彈讓裂隙不再生成",
	}
}

local str = strs[locale] or strs.en

name = str.name
description = str.description
author = "NaAlOH4"
version = "0.1"
forumthread = ""
api_version = 10

dont_starve_compatible = false
reign_of_giants_compatible = false
dst_compatible = true
all_clients_require_mod = false
client_only_mod = false

-- icon = "xs.tex"

