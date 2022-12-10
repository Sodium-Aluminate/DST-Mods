--[[
    演示模块
    0. 当你完成自己的模块后，在 moduleList.lua 中加入模块名，或者执行 updateList.sh
    1. 模块分为三部分：
        priority: number，优先级
        test: function，测试函数
        apply: function，执行函数
        （其他值可以被这两个函数引用）
    2. 优先级
        优先级越高的越先执行，相同则根据 moduleList 中的顺序来执行
        默认为 0
        不支持动态修改（在模组读取的时候就排序完成了）
    3. 测试函数
        用于判断该模块是否应该对此控制台指令生效
        返回 false 时，执行函数不会被调用
        不建议在此函数里塞执行的东西
    4. 执行函数
        用于真正执行自定义指令的函数，返回一个 table:result，可以包含两个 boolean 值：
            shouldContinue: 是否继续尝试调用剩余的模块，当为空或false时，后续（优先级较低）的模块将被跳过，原版控制台也不会执行；
            disableOriginalExecutor: 是否禁用原版控制台，当为true时，控制台输入将不会被交给科雷原版控制台。
]]
return {
    -- 此模块演示: 当控制台命令包含 "klei yydsb" 字段时，有 10% 概率崩溃游戏，否则在日志打印/角色发言 "真头痛鸭！"

    --[[
        优先度为 1
        这会比默认优先度的模块更早执行
    ]]
    priority = 1,

    --[[
        测试函数
        使用 string.find 函数来寻找有没有 klei yydsb
        （建议直接 return fnstr:find("klei yydsb")
        前四个参数如同原版调用，最后一个参数是 mod 的环境（便于读取配置之类的）
    ]]
    test = function(fnstr, guid, x, z, modenv)
        if(fnstr:find("klei yydsb"))then
            return true
        end
        return false
    end,
    --[[
        执行函数
    ]]
    apply = function(fnstr, guid, x, z, modenv)
        if (math.random() > 0.9) then
            error("klei yydsb!")
        else
            local player = Ents[guid]
            if(player)then
                player.components.talker:Say("真头痛鸭！")
            end
            print("真头痛鸭！")
        end

        --这个模块不影响其他函数
        return{
            shouldContinue=true,
            disableOriginalExecutor=false
        }
    end
}