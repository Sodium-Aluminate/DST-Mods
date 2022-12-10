return {
    priority = 0,
    test = function(fnstr, guid, x, z, modenv)
        if(true)then
            return true
        end
        return false
    end,
    apply = function(fnstr, guid, x, z, modenv)
        return{
            shouldContinue=true,
            disableOriginalExecutor=false
        }
    end
}