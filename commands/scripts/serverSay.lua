local function startsWith(scr, target)
    return scr:sub(1, #target) == target
end
return {
    priority = 0,
    test = function(fnstr, guid, x, z, modenv)
        return (startsWith(fnstr, ":") or startsWith(fnstr, "："))
    end,
    apply = function(fnstr, guid, x, z, modenv)
        local str -- 我讨厌lua为了偷懒导致的正则没有或符
        if (fnstr:sub(1, 2) == ":") then
            str = fnstr:sub(2)
        else
            str = fnstr:sub(4)
        end
        if (#str == 0) then
            return { shouldContinue = true, disableOriginalExecutor = false }
        end

        TheNet:SystemMessage(str)

        return { shouldContinue = false, disableOriginalExecutor = true }
    end
}