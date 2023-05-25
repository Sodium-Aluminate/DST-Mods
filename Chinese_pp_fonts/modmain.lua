local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local ZHFONT = "alpt_zhfont"
local ZHFONT_OUTLINE = "alpt_zhfont_outline"
--local ZHFONT_OUTLINE = ZHFONT
local DISABLE_COLOR = nil

table.insert(DEFAULT_FALLBACK_TABLE, 1, ZHFONT)
table.insert(DEFAULT_FALLBACK_TABLE_OUTLINE, 1, ZHFONT_OUTLINE)
table.insert(FONTS, { filename = ENV.MODROOT .. "fonts/normal.zip", alias = ZHFONT, disable_color = DISABLE_COLOR })
table.insert(FONTS, { filename = ENV.MODROOT .. "fonts/normal_outline.zip", alias = ZHFONT_OUTLINE, disable_color = DISABLE_COLOR })