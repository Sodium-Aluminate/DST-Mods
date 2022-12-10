return {
    priority = 0,
    test = function(fnstr, guid, x, z, modenv)
        return (fnstr:sub(1, 2) == ": " or fnstr:sub(1, 4) == "： ")
    end,
    apply = function(fnstr, guid, x, z, modenv)
        local str
        if(fnstr:sub(1,2)==": ") then
            str = fnstr:sub(3)
        else
            str = fnstr:sub(5)
        end
        if(#str==0)then
            return { shouldContinue = true, disableOriginalExecutor = false }
        end

        TheNet:SystemMessage(str)

        return{
            shouldContinue=false,
            disableOriginalExecutor=true
        }
    end
}