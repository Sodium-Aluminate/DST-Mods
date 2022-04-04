local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local FONT_NAME = "normalfont_outline"

table.insert(DEFAULT_FALLBACK_TABLE, 1, FONT_NAME)
table.insert(DEFAULT_FALLBACK_TABLE_OUTLINE, 1, FONT_NAME)
table.insert(FONTS, { filename = ENV.MODROOT.."font/normal_outline.zip", alias = FONT_NAME, disable_color = true })
