TUNING.COM_NAALOH4_DEBUG = GetModConfigData("_ALL")
if(not TUNING.COM_NAALOH4_DEBUG) then
    TUNING.COM_NAALOH4_DEBUG = {}
    for _, modname in ipairs({"bugBoat", "swimAgain"})do
        local k = modname:upper()
        TUNING.COM_NAALOH4_DEBUG[k] = GetModConfigData(k)
    end
end