local jsonUtil = require "json"
local function clearTaskCache()
end

------------
--- 配置 ---
------------
local configuration = {}

-- GLOBAL.dstBridgeConf = configuration

-- 检查配置是否有效（必须有服务器地址、本世界名字、服务器密码或服务器无需密码标签）
function configuration:Available()
    return (self.serverAddr
            and self.worldName
            and (self.password or self.passwordDisabled)
    ) and true or false
end

-- 当服务器配置修改后，需要调用此接口来重新进行字符串拼接，从而防止配置失效。
function configuration:_clearCache()
    self._cachedGetUrl = nil
    self._cachedSendUrl = nil
    self._cachedHostUrl = nil
    clearTaskCache()
end

-- 得到类似 https://example.com/ 的字符串。为节约性能，字符串只会拼接一次。
function configuration:_GetHostUrl()
    if self._cachedHostUrl then
        return self._cachedHostUrl
    end
    local scheme = self.noHTTPS and "http" or "https"
    local host = self.serverAddr
    local port = self.port and ("" .. self.port) or nil
    self._cachedHostUrl = port and
            scheme .. "://" .. host .. ":" .. port .. "/" or
            scheme .. "://" .. host .. "/"
    return self._cachedHostUrl
end

-- 得到服务器密码，如果为无需密码则返回 nil。
function configuration:_GetPassword()
    return self.passwordDisabled and nil or self.password
end

local function urlEncode(str)
    str = string.gsub(str, "([^0-9a-zA-Z !'()*._~-])",
            function(c)
                return string.format("%%%02X", string.byte(c))
            end)
    str = string.gsub(str, " ", "+")
    return str
end

-- 获取 http push/pull 操作时所需的 url，如 https://example.com/sendMessage?serverPasswd=1145141919810
function configuration:GetPushUrl()
    if self._cachedSendUrl then
        return self._cachedSendUrl
    end
    local passwd = self:_GetPassword()
    local url = self:_GetHostUrl() .. "sendMessage" .. "?worldName=" .. urlEncode(self.worldName)
    if (passwd) then
        url = url .. "&serverPasswd=" .. urlEncode(passwd)
    end
    self._cachedSendUrl = url
    return url
end
function configuration:GetPullUrl()
    if self._cachedGetUrl then
        return self._cachedGetUrl
    end
    local passwd = self:_GetPassword()
    local url = self:_GetHostUrl() .. "getMessage" .. "?worldName=" .. urlEncode(self.worldName)
    if (passwd) then
        url = url .. "&serverPasswd=" .. urlEncode(passwd)
    end
    self._cachedGetUrl = url
    return url
end

-- 获取世界名字，用于发给服务器
function configuration:GetWorldName()
    return self.worldName
end

function configuration:OnSave()
    local data = {}
    if (not data:Available()) then
        return data;
    end
    data.serverAddr = self.serverAddr
    data.worldName = self.worldName
    if (self.passwordDisabled) then
        data.passwordDisabled = true
    else
        data.password = self.password
    end
    if (self.port) then
        data.port = self.port
    end
    data.noHTTPS = self:_clearCache().noHTTPS
    return data
end
function configuration:OnLoad(data)
    self:_clearCache()
    self.serverAddr = data.serverAddr
    self.worldName = data.worldName
    if (data.passwordDisabled) then
        self.passwordDisabled = true
    else
        self.password = data.password
    end
    if (data.port) then
        self.port = data.port
    end
    self.noHTTPS = data.noHTTPS
end

local SAVE_FILE_PATH = "mod_config_data/NaAlOH4_dst_bridge"
GLOBAL.TheSim:GetPersistentString(SAVE_FILE_PATH, function(read_success, str)
    if read_success then
        local success, data = GLOBAL.RunInSandboxSafe(str)
        if success and str:len() > 0 then
            configuration:OnLoad(data)
        end
    end
end)
local function SaveConf()
    if (configuration:Available()) then
        GLOBAL.SavePersistentString(SAVE_FILE_PATH, GLOBAL.DataDumper(configuration:OnSave(), nil, true))
    end
end

function configuration:SetServerAddr(addr)
    self.serverAddr = addr
    self:_clearCache()
    SaveConf()
end

function configuration:SetWorldName(name)
    self.worldName = name
    self:_clearCache()
    SaveConf()
end

function configuration:SetPasswd(passwd)
    if (passwd) then
        self.password = passwd
        self.passwordDisabled = false
    else
        self.passwordDisabled = true
    end
    self:_clearCache()
    SaveConf()
end

function configuration:SetPort(port)
    self.port = port
    self:_clearCache()
    SaveConf()
end

function configuration:SetNoHTTPS(b)
    self.noHTTPS = b and true or false
    self:_clearCache()
    SaveConf()
end

GLOBAL.b_setServerAddr = function(addr)
    configuration:SetServerAddr(addr)
end
GLOBAL.b_setWorldName = function(name)
    configuration:SetWorldName(name)
end
GLOBAL.b_SetPasswd = function(passwd)
    configuration:SetPasswd(passwd)
end
GLOBAL.b_SetPort = function(port)
    configuration:SetPort(port)
end
GLOBAL.b_SetNoHTTPS = function(b)
    configuration:SetNoHTTPS(b)
end

------------
--- 指令 ---
------------


local commands = { "SetServerAddr", "SetWorldName", "SetPasswd", "SetPort", "SetNoHTTPS" }

for i, v in ipairs(commands) do
    GLOBAL["b_" .. v] = function(value)
        if (GLOBAL.TheWorld and GLOBAL.TheWorld.ismastershard) then
            -- 地表
            configuration[v](configuration, value)
        end
        -- 摆了 转义炸就炸吧...
        if (GLOBAL.TheWorld and not GLOBAL.TheWorld.ismastersim) then
            -- 客户端
            GLOBAL.c_remote("b_" .. v .. "(" .. value .. ")")
        end
    end
end

local function addCommands()
    if (GLOBAL.TheWorld and not GLOBAL.TheWorld.ismastersim) then
        --GLOBAL.ConsoleScreen.console_edit:AddWordPredictionDictionary({ words = commands, delim = "b_", num_chars = 0 })
    end
end
AddPrefabPostInit("world", addCommands)

------------------------
--- 游戏消息到服务器 ---
------------------------

------ 解析发送群组消息结果 ------ // 没啥用东西，后端可以完全不做
local function onSendResult(result, isSuccessful, resultCode)
    if not (isSuccessful and resultCode == 200) then
        print("发送消息失败");
        print(result)
    end
end

------ 发消息到服务器的函数 ------

local confNotReadyAssertUnused = true
local function sendGroupMsg(userid, name, message)
    print("fn sendGroupMsg: ", userid, name, message)

    local data = {}
    data.name = name
    data.text = message
    data.additionalPrefix = userid
    data.worldName = configuration:GetWorldName()

    local jsonData = jsonUtil.encode(data)
    if (configuration:Available()) then
        GLOBAL.TheSim:QueryServer(configuration:GetPushUrl(), onSendResult, "POST", jsonData)
    else
        if (confNotReadyAssertUnused) then
            GLOBAL.TheNet:SystemMessage("未设置消息服务器")
            confNotReadyAssertUnused = false
        end
    end
end

------ hook Networking_Say 来检查玩家说了啥 ------
local function hookNetwork (inst)
    local oldFn = GLOBAL.Networking_Say
    GLOBAL.Networking_Say = function(guid, userid, name, prefab, message, colour, whisper, isemote)
        if GLOBAL.TheNet and GLOBAL.TheNet:GetIsServer() and inst.ismastershard then
            sendGroupMsg(userid, name, message)
        end
        return oldFn(guid, userid, name, prefab, message, colour, whisper, isemote);
    end
end
AddPrefabPostInit("world", hookNetwork);




------------------------------------------------
-- 收到消息部分
-- 收到的是array of messages,越旧的消息放在越前面。
--[[
{
  "worldName": "groupName",
  "text": "message",
  "name": "name",
  "additionalPrefix": "tg"
}
(tg)name@groupName: message
]]

--[[
{
  "worldName": "料理的直播间",
  "text": "message",
  "name": "name"
}
name@料理的直播间: message
]]
------------------------------------------------



------ 拉取消息解析函数，可能会 error 所以套一层 pcall ------
local rawOnGetGroupMsgResult = function(result, isSuccessful, resultCode)
    if isSuccessful and string.len(result) > 1 and resultCode == 200 then
        local datas = jsonUtil.decode(result)
        print(result)
        for _, data in ipairs(datas) do
            local p = data.additionalPrefix and ("(" .. data.additionalPrefix .. ")") or ""
            GLOBAL.TheNet:SystemMessage(
                    p .. data.name ..
                            "@" .. data.worldName ..
                            ": " .. data.text
            )
        end

    else
        print("获取消息失败.\nisSuccess:", isSuccessful, "\nresultcode:", resultCode, "\nresult:", result)
    end
end

local function onGetGroupMsgResult(result, isSuccessful, resultCode)
    GLOBAL.pcall(rawOnGetGroupMsgResult, result, isSuccessful, resultCode)
end

local no_config_err_delay = 10
local task
local pullLoop = function()
end
------ 获取消息循环 ------
AddSimPostInit(function(inst)
    if GLOBAL.TheNet and GLOBAL.TheNet:GetIsServer() then

        function pullLoop(world)
            if (not world.ismastershard) then
                return
            end

            if (configuration:Available()) then
                GLOBAL.TheSim:QueryServer(
                        configuration:GetPullUrl(),
                        function(result, isSuccessful, resultCode)
                            onGetGroupMsgResult(result, isSuccessful, resultCode)
                            if (task == nil) then
                                task = GLOBAL.TheWorld:DoPeriodicTask(
                                        TUNING.COM_NAALOH4_BRIDGE_PULL_DELAY or 1,
                                        pullLoop)
                            end
                        end,
                        "GET")
            else
                print("missing configuration. read readme to get more detail. ")
                no_config_err_delay = no_config_err_delay + 10
                if (no_config_err_delay > 60) then
                    no_config_err_delay = 60
                end
                task = GLOBAL.TheWorld:DoPeriodicTask(
                        no_config_err_delay,
                        pullLoop
                )

            end

        end

        pullLoop(GLOBAL.TheWorld)

    end
end)

function clearTaskCache()
    if (task) then
        task:Cancel()
        task = GLOBAL.TheWorld:DoPeriodicTask(
                1,
                pullLoop
        )
    end
end
