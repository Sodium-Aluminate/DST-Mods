---
--- Generated by Luanalysis
--- Created by sodiumaluminate.
--- DateTime: 2021/12/18 下午6:54
---
GLOBAL = GLOBAL;
------------------------------------------------
-- [初始配置部分]
------------------------------------------------
local jsonUtil = require "json"

------ 获取配置文件并拼接为 url ------
mode = GetModConfigData("mode")
if mode == 0 then
    _h = "http://127.0.0.1:"
    --[[
    这里不写 localhost 是防止离谱设备(或者docker）连 /etc/hosts 都没写。
    或者因为没有 nsswitch.conf 导致 lookup 顺序都搞不清楚。
            参见某 golang 惨案: https://lailin.xyz/post/localhost.html
    ]]
end
if mode == 1 then
    _h = "http://dstMessageServer:"
end
if mode == 2 then
    _h = "https://dstMessageServer:"
end
if mode == -1 then
    _h = "https://localhost:"
end



local host = _h .. GetModConfigData("port")

--发消息 URL
local SendUrl = host .. "/sendMessage";
--收消息 URL
local getUrl = host .. "/getMessage?serverPasswd=" .. string.format(GLOBAL.TheNet:GetDefaultServerPassword()); -- serverPasswd 是给消息服务器鉴权的，如果服务器没有



------ 消息前缀配置 ------
prefixType = GetModConfigData("prefix")

------ 转义配置 ------
allowEscape = GetModConfigData("escape")

------ 获取世界名字 ------
RoomName = GLOBAL.TheNet:GetServerName() or ""

------------------------------------------------
-- [发送消息部分]
------------------------------------------------
------ 转义 # 和 @ 字符以防注入（认真的？你要做一个重新区分名字和科雷 id 的后端？） ------
---坏蛋#ku -> 坏蛋\#ku     // 名字中带有井号的全都加一个引号来区分分隔符
---后端读取的方法是 寻找第一个非转义分隔符，也就是第一个前面转义符"\"的数量为偶数的分隔符。然后把所得的前半段每的"\"删掉（每删一个都放过下一个）
---转义的目的是为了确保精心设计的用户名不会妨碍你快速 ban 某个用户，如果你的服务端有这个功能的话。

escape = function(str, targetChar)
    if(allowEscape) then
        -- lua 没有转义轮子真 tm 难受！
        return str:gsub(targetChar,[[\]]..targetChar):gsub([[\]],[[\\]]):gsub([[\]]..targetChar,targetChar)
    end
    return str;
end


------ 发消息函数本体 ------
sendGroupMsg = function(userid, name, message)
    print("fn sendGroupMsg: ", userid, name, message)

    -- 萌新#KU_114514@萌新的世界: 生命值：1/150...保管好我的财产！
    -- 名字#klei id@serverName: text
    toSend = escape(name,"#") .. "#" ..

            -- @Java GLOBAL.ThePlayer != null ? GLOBAL.ThePlayer.userid : userid  // lua 三元运算符真的丑
            escape(GLOBAL.ThePlayer and (GLOBAL.ThePlayer.userid) or userid, "@") ..

            -- 如果你想开启转义，请确保你有 RoomName
            (RoomName and ("@" .. RoomName) or "") ..

            ": \n" .. message

    GLOBAL.TheSim:QueryServer(SendUrl, onSendResult, "POST", toSend)
end


------ hook Networking_Say 来检查玩家说了啥 ------
hookNetwork = function(inst)
    local oldFn = GLOBAL.Networking_Say
    GLOBAL.Networking_Say = function(guid, userid, name, prefab, message, colour, whisper, isemote)
        if GLOBAL.TheNet and GLOBAL.TheNet:GetIsServer() and inst.ismastershard then

            if (prefixType == 0) then
                sendGroupMsg(userid, name, message)
            end
            if (prefixType == -1) then
                if not (string.sub(message, 1, 1) == ":") then
                    sendGroupMsg(userid, name, message)
                end
            end
            if (prefixType == 1) then
                if (string.sub(message, 1, 1) == ":") then
                    message = string.sub(message, 2)
                    sendGroupMsg(userid, name, message)
                end
            end

        end
        return oldFn(guid, userid, name, prefab, message, colour, whisper, isemote);
    end
end
AddPrefabPostInit("world", hookNetwork);


------ 解析发送群组消息结果 ------ // 没啥用东西，后端可以完全不做
function onSendResult(result, isSuccessful, resultCode)

    if ( isSuccessful and resultCode == 200 ) then
        print("发送消息成功");
    else
        print("发送消息失败");
    end
end


------------------------------------------------
-- [收到消息部分]
--[[ 服务端可以以以下任一格式给消息：
1. 直接怼纯文本，简单粗暴，稳定性好。
{
  "asStr": "群熊大，时不时被拉去砍树：我先吃个饭"
}
2. 以某变质聊天软件的 api 作为输出
{
  "message": {
    "from": {
      "first_name": "小杜",
      "last_name": "先生"
    },
    "chat": {
      "title": "杜先生的群"
    },
    "text": "****可能会倒闭，单永远不会变质"
  }
}
请注意：以下消息会被忽略：没有 from，from 没有 first_name(可以没有 last_name)，没有 text。
因此服务端应处理 channelPost，并将图片转为纯文本"[图片] 图片描述"的样子。
]]
------------------------------------------------


------ 解析结果 ------
onGetGroupMsgResult = function (result, isSuccessful, resultCode)
    if isSuccessful and string.len(result) > 1 and resultCode == 200 then
        local r = jsonUtil.decode(result)
        if r.asStr then
            GLOBAL.TheNet:SystemMessage(r.asStr);
        else if r.message and r.message.from and r.message.from.first_name and r.message.text then
            local chatName = r.message.chat and r.message.chat.title
            chatName = chatName and "@".. chatName or ""
            local senderName = r.message.from["last_name"] and (r.message.from["first_name"] .. " " ..r.message.from["last_name"]) or r.message.from["first_name"]
            r.asStr = senderName..chatName..": "..r.message.text;
            GLOBAL.TheNet:SystemMessage(r.asStr);
        else
            print("服务端发送了不合法的消息："..result)
        end end

    end
end

------ 获取消息初始化 ------
AddSimPostInit(function(inst)
    if GLOBAL.TheNet and GLOBAL.TheNet:GetIsServer() then
        -- 每 0.5 秒拉取一次消息
        GLOBAL.TheWorld:DoPeriodicTask(0.5, function(inst)
            if inst.ismastershard then
                GLOBAL.TheSim:QueryServer(getUrl, onGetGroupMsgResult, "GET")
            end
        end)
    end
end)
