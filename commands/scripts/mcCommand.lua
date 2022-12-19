local IGNORE_WALKABLE_PLATFORM_TAGS_ON_REMOVE = { "ignorewalkableplatforms", "ignorewalkableplatformdrowning", "activeprojectile", "flying", "FX", "DECOR", "INLIMBO", "player" }

local function startsWith(scr, target)
    assert(type(scr) == "string" and type(target) == "string")
    return scr:sub(1, #target) == target
end

local function _insertStr(t, str, allowEmpty)
    if (allowEmpty or (str and #str > 0)) then
        table.insert(t, str)
    end
end
local function split(str, pattern, limit, allowEmpty)
    if (limit < 2 and limit >= 0) then
        return { str }
    end
    local l = {}
    local endIndex = str:len()
    local currentIndex = 1
    while currentIndex <= endIndex do
        if (#l + 1 == limit) then
            _insertStr(l, str:sub(currentIndex, endIndex), allowEmpty)
            break
        end

        local i, e = str:find(pattern, currentIndex)
        if i == nil then
            _insertStr(l, str:sub(currentIndex, endIndex), allowEmpty)
            break
        end
        _insertStr(l, str:sub(currentIndex, i - 1), allowEmpty)
        if e == endIndex then
            _insertStr(l, "", allowEmpty)
            break
        end
        currentIndex = e + 1
    end
    return l
end
local function isEmptyArg(arg)
    return arg == nil or arg == "" or arg:find("^ +$")
end
local function isValidEnt(ent)
    return ent and ent.IsValid and ent:IsValid()
end

local function getCurrentPlayer(guid)
    return guid and Ents[guid] or (#AllPlayers == 1 and AllPlayers[1] or nil)
end
local function getLang()
    -- todo 判断服务器语言
    return "zh"
end
local function getDefaultLang()
    return "en"
end

-- todo 使用 metatable 替换掉当前策略
-- todo 使用 metatable 将 prefab=flower 中未赋值的 flower 变成 "flower" 字符串
---genEnv
---@return table 一个类似科雷 modmain 的 env
local function genEnv()
    local env = {
        -- lua
        pairs = pairs,
        ipairs = ipairs,
        print = print,
        math = math,
        table = table,
        type = type,
        string = string,
        tostring = tostring,
        require = require,
        assert = assert,
        pcall = pcall,
        Class = Class,

        -- runtime
        TUNING = TUNING,

        -- worldgen
        LEVELCATEGORY = LEVELCATEGORY,
        GROUND = GROUND,
        WORLD_TILES = WORLD_TILES,
        LOCKS = LOCKS,
        KEYS = KEYS,
        LEVELTYPE = LEVELTYPE,

        -- utility
        GLOBAL = _G,
        DataDumper = DataDumper,
        SpawnPrefab = SpawnPrefab,
        TheNet = TheNet,

        -- const
        COLLISION = COLLISION,
    }
    env.env = env
    return env
end
local _env = genEnv()

---clearEnv 将环境清空
---@param env table 运行代码后的env
local function clearEnv(env)
    for k, _ in pairs(_env) do
        env[k] = nil
    end
end

local fn = {
    FALSE = function()
        return false
    end,
    TRUE = function()
        return true
    end,
    DUMMY = function()
    end
}
local XYZ = { "x", "y", "z" }

---数字比较器格式："1" "1..2" "1.." "..2" ">1" ">=1" "<1" "<=1" "~=1" "!=1"
---    如果数字比较器所比较的是某个简写的组件，那么可以通过加入百分号（随便加在哪里）来改为比较组件的值的百分比。

---@exampleUsage: numberCmp("1..2")
---@exampleReturn function cmp(num)
---     return num>1 and num<2
---end
local NumberCmp = {
    {
        pattern = "^" .. "[+-]?%d*%.?%d+" .. "$",
        cmp = function(str)
            return function(num)
                return num == tonumber(str)
            end
        end
    }, {
        pattern = "^" .. "[+-]?%d*%.?%d+" .. "%.%." .. "$",
        cmp = function(str)
            return function(num)
                return num >= tonumber(str:sub(1, #str - 2))
            end
        end
    }, {
        pattern = "^" .. "%.%." .. "[+-]?%d*%.?%d+" .. "$",
        cmp = function(str)
            return function(num)
                return num <= tonumber(str:sub(3))
            end
        end
    }, {
        pattern = "^" .. "[+-]?%d*%.?%d+" .. "%.%." .. "[+-]?%d*%.?%d+" .. "$",
        cmp = function(str)
            local s = split(str, "%.%.")
            return function(num)
                return num >= tonumber(s[1]) and num <= tonumber(s[2])
            end
        end
    }, {
        pattern = "^" .. "[<>=~!]=?" .. "[+-]?%d*%.?%d+" .. "$", -- 有点过度匹配但是我懒得精确匹配了
        cmp = function(str)
            --todo 重写以防用户输入是错的
            str:gsub("!", "~")
            local ok, result = pcall(loadstring("return function(num) num" .. str .. " end"))
            return ok and result or fn.FALSE
        end
    }
}
setmetatable(NumberCmp, { __call = function(str)
    if (type(str) == "string") then
        local isPercent = not not (str:find("%%"))
        for _, v in ipairs(NumberCmp) do
            if (str:find(v.pattern)) then
                return v.cmp(str:gsub("%%", "")), isPercent
            end
        end
    end
end })

---nlp 中的 “是”，处理 “1.5 是 大于一的数”这样的判断
---处理选择器
---注意：由于数字比较器的开销，传进来之前就得用 numberCmp 转换为函数比较器！！！
---函数比较器： function(对应值) ... return <是否满足条件> end
---布尔比较器：为 true 表示对应值必须能被转换为 true；false 同理。
---
---@param a ? 被比较的对象
---@param b ? 比较器
---@param a_component table a所处的组件，如果有。
local function a_is_b(a, b, a_component)
    if (a == b) then
        return true
    end
    if (type(b) == "function") then
        return b(a, a_component)
    end
    if (type(b) == "boolean") then
        return (not b) == (not a) -- 滥用类型转换
    end
end

---部分自定义过滤器（实体组件、实体prefab、sgTag）
---key：自定义名字，如 @e[type="flo.*"] 中 type 为自定义名字
---value：一个生成函数的函数：
---     函数传参：原过滤器中对应的值：如上文的 "flo.*"
---     函数返回：另一个判断实体是否满足要求的函数：
---         函数传参：实体
---         函数返回：该实体是否满足要求
local filterOverrides
filterOverrides = {
    --- 实体生命值、理智、饱食度、耐久、新鲜度的值（或其百分比）是否满足范围
    health = function(arg)
        local numCmp, isPercent = NumberCmp(arg)
        return function(ent)
            if not (ent and ent.components and ent.components.health) then
                return false
            end
            local component = ent.components.health
            return a_is_b(
                    isPercent and component:GetPercent() * 100 or component.currenthealth,
                    numCmp or arg,
                    component
            )
        end
    end,
    sanity = function(arg)
        local numCmp, isPercent = NumberCmp(arg)
        return function(ent)
            if not (ent and ent.components and ent.components.sanity) then
                return false
            end
            local component = ent.components.sanity
            return a_is_b(
                    isPercent and component:GetPercent() * 100 or component.current,
                    numCmp or arg,
                    component
            )
        end
    end,
    hunger = function(arg)
        local numCmp, isPercent = NumberCmp(arg)
        return function(ent)
            if not (ent and ent.components and ent.components.hunger) then
                return false
            end
            local component = ent.components.hunger
            return a_is_b(
                    isPercent and component:GetPercent() * 100 or component.current,
                    numCmp or arg,
                    component
            )
        end
    end,
    finiteuses = function(arg)
        local numCmp, isPercent = NumberCmp(arg)
        return function(ent)
            if not (ent and ent.components and ent.components.finiteuses) then
                return false
            end
            local component = ent.components.finiteuses
            return a_is_b(
                    isPercent and component:GetPercent() * 100 or component:GetUses(),
                    numCmp or arg,
                    component
            )
        end
    end,
    perishable = function(arg)
        if (arg == "green" or "绿") then
            arg = "50%.."
        elseif (arg == "yellow" or "黄") then
            arg = "20%..50%"
        elseif (arg == "red" or "红") then
            arg = "..20%"
        end
        local numCmp, isPercent = NumberCmp(arg)
        return function(ent)
            if not (ent and ent.components and ent.components.perishable) then
                return false
            end
            local component = ent.components.perishable
            return a_is_b(
                    isPercent and component:GetPercent() * 100 or component.perishremainingtime,
                    numCmp or arg,
                    component
            )
        end
    end,
    sgTag = function(arg)
        return function(ent)
            return ent.sg:HasStateTag(arg)
        end
    end
}
for alias, raw in pairs({ hp = "health", san = "sanity", use = "finiteuses", rot = "perishable" }) do
    filterOverrides[alias] = filterOverrides[raw]
end
local NBTOverrides
NBTOverrides = {
    health = function(arg)
        if (type(arg) == "number") then
            return function(ent)
                if (ent and ent.components and ent.components.health) then
                    ent.components.health:SetVal(arg, "console command")
                end
            end
        elseif (type(arg) == "string" and arg:sub(#arg) == "%") then
            local num = tonumber(arg:sub(1, #arg - 1))
            if (num) then
                return function(ent)
                    if (ent and ent.components and ent.components.health) then
                        ent.components.health:SetPercent(num / 100, "console command")
                    end
                end
            end

        end
        return fn.DUMMY
    end,

    sanity = function(arg)
        if (type(arg) == "number") then
            return function(ent)
                if (ent and ent.components and ent.components.sanity) then
                    local sanity = ent.components.sanity
                    local data = { current = arg }
                    data.mode = sanity.mode
                    sanity:OnLoad(data) -- 你们科雷都不写一个 SetVal 接口吗？
                end
            end
        elseif (type(arg) == "string" and arg:sub(#arg) == "%") then
            local num = tonumber(arg:sub(1, #arg - 1))
            if (num) then
                return function(ent)
                    if (ent and ent.components and ent.components.sanity) then
                        ent.components.sanity:SetPercent(num / 100)
                    end
                end
            end

        end
        return fn.DUMMY
    end,
    hunger = function(arg)
        if (type(arg) == "number") then
            return function(ent)
                if (ent and ent.components and ent.components.hunger) then
                    ent.components.hunger:OnLoad({ hunger = arg })
                end
            end
        elseif (type(arg) == "string" and arg:sub(#arg) == "%") then
            local num = tonumber(arg:sub(1, #arg - 1))
            if (num) then
                return function(ent)
                    if (ent and ent.components and ent.components.hunger) then
                        ent.components.hunger:SetPercent(num / 100)
                    end
                end
            end
        end
        return fn.DUMMY
    end,

    finiteuses = function(arg)
        if (type(arg) == "number") then
            return function(ent)
                if (ent and ent.components and ent.components.finiteuses) then
                    ent.components.finiteuses:SetUses(arg)
                end
            end
        elseif (type(arg) == "string" and arg:sub(#arg) == "%") then
            local num = tonumber(arg:sub(1, #arg - 1))
            if (num) then
                return function(ent)
                    if (ent and ent.components and ent.components.finiteuses) then
                        ent.components.finiteuses:SetPercent(num / 100)
                    end
                end
            end
        end
        return fn.DUMMY
    end,
    perishable = function(arg)
        if (type(arg) == "number") then
            return function(ent)
                if (ent and ent.components and ent.components.perishable) then
                    ent.components.perishable:SetPerishTime(arg)
                end
            end
        elseif (type(arg) == "string" and arg:sub(#arg) == "%") then
            local num = tonumber(arg:sub(1, #arg - 1))
            if (num) then
                return function(ent)
                    if (ent and ent.components and ent.components.perishable) then
                        ent.components.perishable:SetPercent(num / 100)
                    end
                end
            end
        end
        return fn.DUMMY
    end,
}
for alias, raw in pairs({ hp = "health", san = "sanity", use = "finiteuses", rot = "perishable" }) do
    NBTOverrides[alias] = NBTOverrides[raw]
end

local function _readEntity(ent, stack)
    if (#stack == 0) then
        return ent
    end
    local e = ent
    for i = 1, #stack do
        if (type(e) ~= "table") then
            -- 本应该继续取值 但是已经不是 table 了
            return nil
        end
        e = e[stack[i]]
    end
    return e
end

---normalFiliter 将实体表中的实体删除（不会向前移动，即，会留下空洞）
---@param ents table 实体表
---@param filters table 过滤表，实体的数据必须“是”(表归属，a_is_b）过滤表中的数据所描述的样子
---@param stack table 递归时用，当前检查到过滤表的哪一层了。
local function normalFiliter(ents, filters, stack)
    for k, v in pairs(filters) do
        if (type(v) == "table") then
            local newStack = shallowcopy(stack)
            table.insert(newStack, k)
            normalFiliter(ents, v, newStack)
        else
            local filter = NumberCmp(v) or v
            for ent_i, ent in pairs(ents) do
                if (not a_is_b(_readEntity(ent, stack)[k], filter)) then
                    ents[ent_i] = nil
                end
            end
        end
    end
end

---“复制，粘贴；是否合并文件夹？是；是否替换已有内容？是。”
local function normalNBT(ents, nbt, stack)
    for k, v in pairs(nbt) do
        if (type(v) == "table") then
            for _, ent in pairs() do
                if (isValidEnt(ent) and ent[k] == nil) then
                    ent[k] = {}
                end
            end
            local newStack = shallowcopy(stack)
            table.insert(newStack, k)
            normalFiliter(ents, v, newStack)
        else
            for _, ent in pairs(ents) do
                if(isValidEnt(ent))then
                    ent[k] = v
                end
            end
        end
    end
end

---@param ents table 被筛选的实体，注意：此表会被破坏
---@param filters table 筛选器
local function filter(ents, filters, player)

    local sort = tostring(filters.sort)
    local limit = type(filters.limit) == "number" and filters.limit or nil
    filters.sort = nil
    filters.limit = nil

    -- 预定义过滤器筛选
    if (filters.prefab) then
        -- 先过一遍 prefab，节约性能
        for i, v in pairs(ents) do
            if (v.prefab ~= filters.prefab) then
                ents[i] = nil
            end
        end
        -- 输入的过滤器删掉
        filters.prefab = nil
    end
    -- type 是正则格式的 prefab，复制粘贴
    if (filters.type) then
        for i, v in pairs(ents) do
            if (v.prefab and v.prefab:find(filters.type)) then
                ents[i] = nil
            end
        end
        filters.type = nil
    end

    if (filters.x or filters.y or filters.z or filters.pos) then
        for _, k in ipairs(XYZ) do
            local t = NumberCmp(filters[k])
            if (t) then
                filters[k] = t
            end
        end
        for i, v in pairs(ents) do
            if (not v.Transform) then
                ents[i] = nil
            else
                local x, y, z = v.Transform:GetWorldPosition()
                if (filters.x and not a_is_b(x, filters.x))
                        or (filters.y and not a_is_b(y, filters.y))
                        or (filters.z and not a_is_b(z, filters.z))
                        or (not filters.pos(x, y, z, player, _G))
                then
                    ents[i] = nil
                end
            end
        end

        -- 输入的过滤器删掉
        for _, k in ipairs(XYZ) do
            filters[k] = nil
        end
        filters.pos = nil
    end
    for k, metaFn in pairs(filterOverrides) do
        if (filters[k]) then
            -- 生成过滤器
            local newFilter = metaFn(filters[k])

            -- 用过滤器晒一遍实体
            for i, v in pairs(ents) do
                if (not newFilter(v)) then
                    ents[i] = nil
                end
            end

            -- 输入的过滤器删掉
            filters[k] = nil
        end
    end

    -- 其他过滤器筛选
    normalFiliter(ents, filters, {})

    -- 重新整理顺序
    local t = {}
    for _, v in pairs(ents) do
        if (sort == "random") then
            table.insert(t, math.random(1, #t + 1), v)
        else
            table.insert(t, v)
        end
    end

    if (sort == "nearest" or sort == "furthest" and player) then
        -- 没有玩家作为原点（控制台输入）则无法排序
        local distances = {}
        for _, v in ipairs(t) do
            distances[v] = v:GetDistanceSqToInst(player)
        end

        if (sort == "nearest") then
            table.sort(t, function(a, b)
                return distances[a] < distances[b]
            end)
        else
            table.sort(t, function(a, b)
                return distances[a] > distances[b]
            end)
        end
    end

    -- 数量限制
    if (limit and #t >= limit) then
        local t_ = {}
        for i = 1, limit do
            t_[i] = t[i]
        end
        return t_
    else
        return t
    end
end

local function applyNBT2Ents(ents, nbt, returnedFn)

    --x/y/z: 设置实体的位置
    for _, k in pairs(XYZ) do
        -- 位置必须是数字
        if (type(nbt[k]) ~= "number") then
            nbt[k] = nil
        end
    end
    if (nbt.x or nbt.y or nbt.z) then
        if (nbt.x and nbt.y and nbt.z) then
            for _, ent in pairs(ents) do
                if (ent.Transform) then
                    ent.Transform:SetPosition(nbt.x, nbt.y, nbt.z)
                end
            end
        else
            for _, ent in pairs(ents) do
                if (ent.Transform) then
                    local x, y, z = ent.Transform:GetWorldPosition()
                    x = nbt.x or x
                    y = nbt.y or y
                    z = nbt.z or z
                    ent.Transform:SetPosition(x, y, z)
                end
            end
        end
    end
    for _, k in pairs(XYZ) do
        nbt[k] = nil
    end

    --hp/sanity/san/hunger/use/rot: 数字，表示将对应组件设置成该值。也可以是以"%"结尾的数字格式的字符串，视为设置对应比例。
    for k, metaFn in pairs(NBTOverrides) do
        if (nbt[k]) then
            -- 生成过滤器
            local f = metaFn(nbt[k])

            -- 用过滤器晒一遍实体
            for _, v in pairs(ents) do
                f(v)
            end

            -- 输入的过滤器删掉
            nbt[k] = nil
        end
    end

    -- 其他设置
    normalNBT(ents, nbt, {})

    if (type(returnedFn) == "function") then
        for _, v in pairs(ents) do
            returnedFn(v)
        end
    end
end

--------------------
--- 命令格式判断 ---
--------------------
local TYPES = {
    number = function(str)
        local _, endIndex, number = str:find("^(%d+) +")
        if (not number) then
            return
        end
        return tonumber(number), str:sub(endIndex + 1)
    end,
    numbers = function(str)
        local nums = {}
        local s = str
        while (true) do
            local _, endIndex, number = s:find("^(%d+) +")
            if (not number) then
                if (#nums == 0) then
                    return
                else
                    return nums, s
                end
            end
            table.insert(nums, tonumber(number))
            s = s:sub(endIndex + 1)
        end
    end,
    string = function(str)
        if (str:sub(1, 1) == "@" or str:sub(1, 1) == "{") then
            return
        end
        local _, endIndex, found = str:find("^([^ ]+) +")
        if (not found) then
            return
        end
        return found, str:sub(endIndex + 1)
    end,
    entities = function(str, guid)
        local s = str
        local _, endIndex, selector = str:find("^@([espra])")
        local _, arg_endIndex, arg = str:find("^@[espra]%[([^%]]*)%] +")
        if (selector) then
            print("实体解析器尝试解析：", selector, arg)
            -- 提前处理好后事
            s = s:sub((arg_endIndex or endIndex) + 1)

            local env = {}
            if (arg) then
                local f, err = loadstring(arg)
                if(not f)then
                    TheNet:SystemMessage("命令执行解析失败，不符合 lua 语法: ")
                    TheNet:SystemMessage(tostring(err))
                    error(tostring(err))
                end
                env = genEnv()
                setfenv(f, env)
                local ok, r = pcall(f)
                if (not ok) then
                    -- 函数执行失败 寄
                    TheNet:SystemMessage("实体选择器参数解析失败")
                    TheNet:SystemMessage(tostring(r))
                    error(tostring(r))
                end
                clearEnv(env)
            end

            if (not arg and selector == "e") then
                -- 选择所有实体
                return shallowcopy(Ents), s
            end

            local searchedEnts = {}

            if (selector == "s") then
                -- @s 命令的执行者
                table.insert(searchedEnts, Ents[guid])
            else
                if (("pra"):find(selector)) then
                    --[[ @p 距离最近的其他玩家
                         @r 随机玩家
                         @a 所有玩家]]
                    if (env.mustTag == nil) then
                        env.mustTag = {}
                    elseif (type(env.mustTag) ~= "table") then
                        env.mustTag = { env.mustTag }
                    end
                    table.insert(env.mustTag, "player")

                    if (selector == "r") then
                        env.sort = "random"
                        env.limit = 1
                    elseif (selector == "p") then
                        env.sort = "nearest"
                        env.limit = 1
                    end
                else
                    -- @e 所有实体
                    assert(selector == "e")
                end

                --alias c=circle
                env.circle = env.circle or env.c
                env.c = nil

                local circle = env.circle
                env.circle = nil
                local findEntitiesArg = { x = 0, y = 0, z = 0, range = 9001 } --既然科雷认为9001是世界极限 那我也跟风写bug咯

                -- 处理 circle 参数
                if (type(circle) == "number") then
                    local player = getCurrentPlayer(guid)
                    if (not player) then
                        print("error when parse " .. arg .. ": using player as search range, but player(guid=" .. tostring(guid) .. ")not found.")
                        print("using slow search.")
                    else
                        local x, y, z = player.Transform:GetWorldPosition()
                        findEntitiesArg = { x = x, y = y, z = z, range = circle }
                    end
                elseif (type(circle) == "table" and circle.x and circle.z and circle.range) then
                    findEntitiesArg = { x = circle.x, y = circle.y or 0, z = circle.z, range = circle.range }
                end

                -- 处理tag参数
                for _, k in ipairs({ "mustTag", "cantTag", "canTag" }) do
                    local value = env[k]
                    findEntitiesArg[k] = value and (type(value) == table and value or { value })
                    env[k] = nil
                end

                if (findEntitiesArg.range >= 9001 and
                        ((not findEntitiesArg.mustTag) or #findEntitiesArg.mustTag == 0) and
                        ((not findEntitiesArg.cantTag) or #findEntitiesArg.cantTag == 0) and
                        ((not findEntitiesArg.canTag) or #findEntitiesArg.canTag == 0)) then
                    -- 找个锤子，全都满足
                    return filter(shallowcopy(Ents), env, getCurrentPlayer(guid)), s
                end
                -- 妈的，起名起长了...
                searchedEnts = TheSim:FindEntities(findEntitiesArg.x, findEntitiesArg.y, findEntitiesArg.z,
                        findEntitiesArg.range,
                        findEntitiesArg.mustTag, findEntitiesArg.cantTag, findEntitiesArg.canTag)
            end
            return filter(searchedEnts, env, getCurrentPlayer(guid)), s
        end
    end,
    nbt = function(str)
        local _, endIndex, found = str:find("^(%b{}) +")
        if (found) then
            local _, _, arg = found:find("^{(.*)}$")
            assert(arg, "正则写错了？")
            local f = loadstring(arg)
            local env = genEnv()
            setfenv(f, env)
            local ok, r = pcall(f)
            if (not ok) then
                -- 函数执行失败 寄
                TheNet:SystemMessage("数据赋值器参数解析失败")
                TheNet:SystemMessage(tostring(r))
                return
            end
            clearEnv(env)
            return function(ents)
                applyNBT2Ents(ents, env, r)
            end, str:sub(endIndex + 1)
        end
    end
}

local function _testFormat(str, format, guid)
    local currentStr, results = str, {}
    for _, v in ipairs(format) do
        if (type(v) == "string") then
            local result
            result, currentStr = TYPES[v](currentStr, guid)
            if (result) then
                table.insert(results, result)
            else
                return
            end
        elseif (type(v) == "function") then
            local result
            result, currentStr = v(currentStr)
            if (result) then
                table.insert(results, result)
            else
                return
            end
        end
    end
    return results, currentStr
end


--[[ todo
help: 打印文档

damage：对实体造成伤害

locate/find：搜索实体
remove：删除实体，这会跳过死亡动画
data：获取某个实体的信息（onsave）
clear：清空实体物品栏

item：修改实体的物品栏

forceload：将某个实体视为像玩家一样能加载周围的物品 -- 不会写

ability：赋予玩家其他角色的能力
gamemode：切换到创造模式（和上帝模式、隐形混合）或者旁观模式（不会溺水，扣血，被沉船，不会被墙挡住，没有碰撞）

give：给玩家物品

playsound：播放音效

alwaysday/alwaysdusk/alwaysnight：全天白天/黄昏/黑夜 -- 不会写 有空看天体
weather：下雨/天晴 -- 垃圾青蛙雨 根本没接口

execute：以一些实体为 "it"，在 global 环境下依次执行 lua 指令

tag：管理某个实体的标签
]]
local ARGS = {
    number = { "number" },
    numbers = { "numbers" },
    string = { "string" },
    entities = { "entities" },
    nbt = { "nbt" },

    str_num = { "string", "number" },
    str_nums = { "string", "numbers" },
    two_string = { "string", "string" },
    two_ent = { "entities", "entities" },
    str_ent = { "string", "entities" },
    ent_str = { "entities", "string" },
    ent_num = { "entities", "number" },
    ent_nums = { "entities", "numbers" },
}
local function _name2player(name)
    for _, v in ipairs(AllPlayers) do
        if (v.name == name or v.userid == name or v.name:gsub(" ", "_") == name) then
            -- 怎么有玩家名字带空格啊... 哦我自己就是，那没事儿了
            return v
        end
    end
end

local _timeLength = { s = 1, h = TUNING.SEG_TIME, d = TUNING.TOTAL_DAY_TIME, y = (15 + 20 + 15 + 20) * 30 * 16 }
if (TUNING.AUTUMN_LENGTH and TUNING.WINTER_LENGTH and TUNING.SPRING_LENGTH and TUNING.SUMMER_LENGTH) then
    _timeLength.y = TUNING.AUTUMN_LENGTH + TUNING.WINTER_LENGTH + TUNING.SPRING_LENGTH + TUNING.SUMMER_LENGTH
end
local _dayPhase = { "day", "dusk", "night" }
local _seasonPhase = { "spring", "summer", "autumn", "winter" }
for _, p in ipairs({ _dayPhase, _seasonPhase }) do
    for i, v in ipairs(p) do
        _seasonPhase[v] = i
    end
    for i, _ in ipairs(p) do
        _seasonPhase[i] = nil
    end
end

--todo 英文文档
local ARG_MANUAL = {
    zh = {
        nbt = [[nbt tags

使用 lua 语法对实体进行操作。

格式：{lua commands} (内部花括号必须成对匹配)
在代码中声明的变量将被赋予对应实体，如果变量名满足特定条件，则将实体的对应组件进行相应操作。特殊条件已经在实例中全部举出。
代码可以在最后返回一个函数，此函数也将被应用于目标实体。（函数输入参数为被操作的实体）。

Example:
    将花朵实体赋予“人工种植”标签
    {planted=true}

    将耐久设置为 10 次
    {use=10}

    将实体的生命值、理智值、饱食度、耐久度、新鲜度全部设置为一半
    {hp="50%" san="50%" hunger="50%" use="50%" rot="50%"}

    将x轴位置设置为 10
    {x=10}

    （对于每个实体）一半的概率移除实体：
    {return function(ent) if(math.random()>0.5)then ent:Remove() end end}
]],
        filter = [[实体选择器

使用 lua 语法选择世界上的实体。

格式：@<type>[lua commands] (内部不能包含方括号)
在代码中声明的变量将被用于检查实体是否满足要求，如果变量名满足特定条件，进行对应的特殊检查。
使用 /help filter alias 来列出所有的特定条件（简写）。

Example:
    当前玩家
    @s

    距离最近的其他玩家
    @p

    随机玩家
    @r

    所有玩家
    @a

    所有实体
    @e

    玩家附近 20 格内的所有实体。使用 c 参数将显著提高搜索速度。
    @e[c=20]

    以 10,0,10 为中心 20 格内的所有实体
    @e[c={x=10,z=10,range=20}]

    所有带有种子食物标签但不带肉类食物标签的实体
    @e[mustTag="edible_SEEDS" cantTag="meat"]

    prefab 名为 flower 的实体
    @e[prefab="flower"]

    prefab 以 flow 开头的实体
    @e[type="^flow.*"]

    y 坐标大于 1 的实体（也可使用类似 Minecraft 的省略号）
    @e[y=">1"]
    @e[y="1.."]

    x 和 z 坐标都在 -517 到 517 的实体
    @e[x="-517..517" z="-517..517"]

    所有血量小于10的实体（使用带有比较符号的字符串可以选择一定范围）
    @e[hp="<10"]
    @e[hp="..10"]

    所有血量小于等于10%的实体（使用百分号改为检测组件的百分比）
    @e[hp="<=10%"]

    所有新鲜度为绿色的实体（只有新鲜度可以用红绿黄来简写）
    @e[rot="绿"]
]],
        ["filter alias"] = [[
circle/c
    table 或 number
    为提高性能强烈建议填写！
    作为 table 时，包含 x, y(default 0), z, range 四个参数；
    作为数字时，表示 range，并默认玩家坐标为 xyz。
    距离单位是墙。
pos
    函数，参数为 (x,y,z,player,GLOBAL)，返回值为该实体是否满足条件。
x/y/z
    直接与坐标（inst.Transform:GetWorldPosition()）进行比较。
canTag/mustTag/cantTag
    table 或 string
    作为 table，目标“必须包含一个”/“必须全部包含”/“必须不包含”表中的 Tag；
    作为 string，视为包含该字符串的表；

hp/sanity/san/hunger/use/rot:
    number 或 function 或 string
    作为 number，对应组件的值必须与该数字相等；
    作为 function，目标组件的值作为参数传入后返回值必须是 true。
    作为 string，对应组件的值或百分比必须符合对应不等式；
    不等式的格式参见 /help numcmp

type
    string
    正则表达式，目标prefab名字必须匹配表达式。如果不希望使用正则，请使用 prefab 替代 type。

sgTag
    string
    对应实体的状态必须有这个标签 （inst.sg:HasStateTag() 必须返回 true）。
]],
        numcmp = [[数字比较器

数字比较器是一个字符串，用于判断数字是否满足条件
格式有如下两种：
1. Minecraft 格式：
    使用两个英文句号做分隔，目标数字必须大于左侧的数字且小于右侧的数字；
    两个都可以留空表示无穷小/无穷大，但不能同时留空。
2. 不等式格式
    使用一个不等号接一个数字，当目标数字与此式拼接后组成的数学命题需成立。
    如：">3"表示目标数字需要大于 3。
    不等号包括 > >= < <= ~= !=，其中最后两种意义相同，均表示不等于。

如果被比较对象是一个组件，则可以加入百分比符号（%）来比较其百分比。
]]
    }
}

local FUNCTION_MANUAL = {
    zh = {

        tp = [[tp

Usage:
    tp [<source>] [<target>]

<source>
    被传送的目标，可以是玩家名字（以下划线替换空格）、实体选择器、也可以留空表示传送自己。注意：不允许只选择 source 而不选择 target。

<target>
    目标位置，可以是 x,z、x,y,z 或者玩家名字、返回一个实体的实体选择器、也可以留空表示传送到鼠标位置。
]],
        summon = [[summon

Usage:
    summon <prefab> [<count>] (at|offset) [<pos>] [<nbt>]
    summon <prefab> <pos> [<nbt>]

<prefab>
    需要生成的实体名字

<count>
    需要生成的数量

<pos>
    生成的位置，使用 "at" 表示使用绝对坐标，使用 "offset" 表示使用以鼠标位置（或服务器内唯一玩家）为原点的相对坐标。

<nbt>
    需要对实体进行的操作，参见 /help nbt。
]],
        seed = [[seed

显示世界种子

Usage:
    seed [忽略一切参数]
]],

        save = [[save

存档。

Usage:
    save [忽略一切参数]
    s [忽略一切参数]
]],
        reset = [[reset

使用 c_reset() 或 c_rollback() 读档。

Usage:
    reset [<count>]
    R [<count>]

<count>
    回档次数。
    根据科雷注释：留空或为 0 时将返回最后一个存档；
    若为 1 则返回除去 30 秒内的最近存档；
    若为 其他值则相当于连续回档多次。
]],
        shutdown = [[shutdown

关闭服务器。

Usage:
    shutdown [<should-save>]
    stop [<should-save>]

<should-save>
    若为 false，则关闭服务器前不会存档，若为空，则正常存档。
]],

        time = [[time

显示或更改时间

Usage:
    time
    time query 等同于 time
    time (set|add) <days>
    time (set|add) [<years>y][<days>d][<hours>h][<seconds>s]
    time set (day|dusk|night)
    time set (spring|summer|autumn|winter)
]],

        kill = [[kill

Usage:
    kill [<target>]

<target>
    被杀死的目标，可以是玩家名字（以下划线替换空格）、实体选择器、也可以留空表示自杀。
]],
        remove = [[remove

Usage:
    remove [<target>]

<target>
    被移除的目标，可以是玩家名字（以下划线替换空格）、实体选择器、也可以留空表示移除玩家实体。
    注意，移除玩家可能会产生非预期的问题，特别是在一些有模组的服务器中。
]],
        damage = [[damage

Usage:
    damage [<target>] [<number>|<percent>%]

<target>
    被伤害的目标，可以是玩家名字（以下划线替换空格）、实体选择器、也可以留空表示对自己造成伤害。
<number>
    造成的伤害值，如果以百分号结束则视为百分比；留空则造成等同于实体血量的伤害
]],
        locate = [[locate

Usage:
    locate [<target>]
    find [<target>]

<target>
    要寻找的目标，可以是玩家名字（以下划线替换空格）、实体选择器、也可以留空表示寻找自己。
]],
        sink = [[sink

Usage:
    sink [<target>]

<target>
    被沉船杀的目标，可以是玩家名字（以下划线替换空格）、实体选择器、也可以留空表示沉掉自己。
]],
    }
}


-- 指定实体的单参数命令
local function _actForEnts(commandName, entFn, argStr, guid, x, z, modenv, isDangerous)
    local restArg
    local targets
    if (isEmptyArg(argStr)) then
        local player = getCurrentPlayer(guid)
        if (not player) then
            print('using "' .. commandName .. '" without argument, but "current player" not found')
            return {}
        end
        targets = { player }
    end

    if (not targets) then
        local results, newStr = _testFormat(argStr, ARGS.string, guid)
        if (results) then
            restArg = newStr
            local player = _name2player(results[1])
            if (not player) then
                print("player \"" .. results[1] .. "\" not found")
                return {}
            end
            targets = { player }
        end
    end

    if (not targets) then
        local results, newStr = _testFormat(argStr, ARGS.entities, guid)
        if (results) then
            restArg = newStr
            if (#results[1] == 0) then
                print("no entity found")
                return results[1]
            end
            targets = results[1]
        end
    end

    local force = false
    if (restArg:gsub(" ", ""):lower() == "fuck") then
        restArg = ""
        force = true
    end
    if (not isEmptyArg(restArg) or (not targets)) then
        print("unknown args: ")
        print(argStr)
    end

    if (isDangerous) then
        -- 别手欠执行了 /kill @e
        if (#targets > 100 and (not force)) then
            TheNet:SystemMessage('too many ents to kill! if you really want execute it, append " fuck" for command to force it.')
            return targets
        end
    end

    for _, ent in pairs(targets) do
        -- DestroyEntity
        if isValidEnt(ent) then
            if (ent == TheWorld and isDangerous) then
                if (force) then
                    TheNet:SystemMessage("oh, look~ \"TheWorld\" included...")
                    entFn(ent)
                else
                    TheNet:SystemMessage("trying to modify \"TheWorld\" ent, skipped, use \" fuck\" to force it")
                end
            else
                entFn(ent)

            end
        end
    end

    return targets
end
local functions -- 分离变量方便重名调用
functions = {
    tp = function(argStr, guid, x, z, modenv)
        local a = {}
        local arg = argStr
        local argFormats = { ARGS.numbers, ARGS.string, ARGS.entities }
        while (true) do
            local l = #a
            for _, argFormat in ipairs(argFormats) do
                print(argFormat[1])
                local results, newStr = _testFormat(arg, argFormat, guid)
                if (results) then
                    table.insert(a, { format = argFormat, result = results[1] })
                    arg = newStr
                end
            end
            if (l == #a) then
                if (isEmptyArg(arg)) then
                    break
                else
                    print("can't parse command: " .. arg)
                    return
                end
            end
        end

        -- format a:?
        if (not a[2]) then
            a[2] = a[1]
            a[1] = nil
        end
        if (not a[1]) then
            local player = getCurrentPlayer(guid)
            if (not player) then
                print("using tp without <source> argument, but \"current player\" not found")
                return
            end
            a[1] = { format = ARGS.entities, result = { player } }
        end
        if (not a[2]) then
            if (x and z and (x ~= 0 or z ~= 0)) then
                a[2] = { format = ARGS.numbers, result = { x, 0, z } }
            else
                print("using tp without <target> argument, but \"mouse pos\" not working")
                return
            end
        end

        -- format a: {{?},{?}} (str/ent/nums) (result key ignored)

        -- name2player
        for i, v in pairs(a) do
            if (v.format == ARGS.string) then
                local player = _name2player(v.result)
                if (not player) then
                    print("using tp but player \"" .. v.result .. "\" not found")
                    return
                end
                a[i] = { format = ARGS.entities, result = { player } }
            end
        end

        -- format a: {{?},{?}} (ent/nums)


        if (a[1].format == ARGS.numbers) then
            print("using tp but <source> argument is numbers")
            return
        end

        -- format a: {{ent},{?}} (ent/nums)

        if (a[2].format ~= ARGS.numbers) then
            assert(a[2].format == ARGS.entities, "代码写错了？")
            local ents = a[2].result
            if (#ents ~= 1) then
                print('using tp but "' .. #ents .. '" <target> found')
                return
            end
            if (not ents[1].Transform) then
                print("没有 Transform 的实体?")
                return
            end
            local x, y, z = ents[1].Transform:GetWorldPosition()
            a[2] = { format = ARGS.numbers, result = { x, y, z } }
        end

        -- format a: {{ent},{nums}}

        if (#a[2].result == 2) then
            table.insert(a, 2, 0)
        end

        if (#a[2].result ~= 3) then
            print('using tp but <target> have ' .. #a[2].result .. 'numbers."')
            return
        end

        -- format a: {{ent},{x,y,z}}

        local p = a[2].result
        for i, ent in pairs(a[1].result) do
            if (ent.Transform) then
                ent.Transform:SetPosition(p[1], p[2], p[3])
            else
                print("found entity without Transform: ")
                print(ent)
            end
        end
    end,
    summon = function(argStr, guid, input_x, input_z, modenv)
        local arg = argStr
        local prefab
        local x, y, z, count, nbtFn

        local result, newStr = _testFormat(arg, ARGS.string, guid)
        if (result) then
            prefab = result[1]
            arg = newStr
        else
            print("参数解析失败，必须以prefab开头：", argStr)
            return
        end

        local player = getCurrentPlayer(guid)

        while (true) do
            local result, newStr = nil, nil
            -- offset x,y,z 相对坐标
            result, newStr = _testFormat(arg, ARGS.str_nums, guid)
            if (result) then
                local dx, dy, dz = 0, 0, 0
                if (result[1] == "offset") then
                    if (input_x and input_z) then
                        dx = input_x
                        dz = input_z
                    elseif (player) then
                        dx, dy, dz = player.Transform:GetWorldPosition()
                    end
                elseif (result[1] ~= "at") then
                    print("参数解析失败，不认识的字符串：", arg)
                    return
                end
                if (#result[2] > 3) then
                    print("数字参数太多")
                    return
                elseif (#result[2] < 2) then
                    print("数字参数太多")
                    return
                end
                if (#result[2] == 2) then
                    result[2][3] = result[2]
                    result[2][2] = 0
                end
                x = result[2][1] + dx
                y = result[2][2] + dy
                z = result[2][3] + dz

                arg = newStr
            end

            -- 绝对坐标
            result, newStr = nil, nil
            result, newStr = _testFormat(arg, ARGS.numbers, guid)
            if (result) then
                local result = result[1]
                if (#result > 3) then
                    print("数字参数太多")
                    return
                elseif (#result < 2) then
                    print("数字参数太多")
                    return
                end
                if (#result == 2) then
                    result[3] = result[2]
                    result[2] = 0
                end
                x = result[1] + dx
                y = result[2] + dy
                z = result[3] + dz

                arg = newStr
            end

            -- 数量
            result, newStr = nil, nil
            result, newStr = _testFormat(arg, ARGS.number, guid)
            if (result) then
                count = result[1]

                arg = newStr
            end

            -- nbt
            result, newStr = nil, nil
            result, newStr = _testFormat(arg, ARGS.nbt, guid)
            if (result) then
                nbtFn = result[1]
                arg = newStr
            end

            if (arg == "" or arg == " ") then
                break
            end

        end

        local spawnedEnts = {}
        TheSim:LoadPrefabs({ prefab })
        if Prefabs[prefab] ~= nil and not Prefabs[prefab].is_skin and Prefabs[prefab].fn then
            for i = 1, count do
                local inst = SpawnPrefab(prefab)
                if inst ~= nil then
                    table.insert(spawnedEnts, inst)
                    if (inst.Transform) then
                        inst.Transform:SetPosition(x, y, z)
                    end
                end
            end
            nbtFn(spawnedEnts)
        else
            print("生成实体失败：\"" .. prefab .. "\" 是正常的实体吗？")
        end

    end,
    seed = function(argStr, guid, input_x, input_z, modenv)
        TheNet:SystemMessage('当前世界种子："' .. TheWorld.meta.seed .. '"')
    end,

    save = function(argStr, guid, input_x, input_z, modenv)
        c_save()
    end,
    reset = function(argStr, guid, input_x, input_z, modenv)
        if (isEmptyArg(argStr)) then
            c_reset()
        else
            local num = tonumber(argStr)
            if (num) then
                c_rollback(num)
            else
                print("not a number: ", argStr)
            end
        end
    end,
    r = function(argStr, guid, input_x, input_z, modenv)
        TheNet:SystemMessage("to avoid mistake, use uppercase 'R' to reset.")
    end,
    shutdown = function(argStr, guid, input_x, input_z, modenv)
        if (argStr:gsub(" ", "") == "false") then
            c_shutdown("false")
        elseif (isEmptyArg(argStr)) then
            c_shutdown()
        else
            print("unknown args: ", argStr)
        end
    end,

    time = function(argStr, guid, input_x, input_z, modenv)

        local results, newStr = _testFormat(argStr, ARGS.string, guid)
        if (isEmptyArg(argStr) or results[1] == "query") then
            local day = TheWorld.state.cycles + math.floor(TheWorld.state.time * 100) / 100
            local seconds = math.floor(TheWorld.state.time * _timeLength.d * 100) / 100
            TheNet:SystemMessage("current time: " .. day .. " days(" .. TheWorld.state.cycles .. " day and " .. seconds .. " seconds)")

            -- 乐
            if (math.random() < 0.01) then
                TheNet:SystemMessage('为什么不直接看右上角？')
            end

            print("cycles&time: ")
            print(TheWorld.state.cycles, TheWorld.state.time)
            return
        end

        local timeStr = newStr:gsub(" ", ""):lower()
        if (results[1] == "set") then
            --[[
        --    time set <seconds>
        --    time set [<days>d][<hours>h][<seconds>s]
        ]]
            if (_dayPhase[timeStr]) then
                if (not TheWorld and TheWorld.state) then
                    print("world state error(not ready?)")
                    return
                end
                for phase, i in pairs(_dayPhase) do
                    if (TheWorld.state["is" .. phase]) then
                        local deltaPhases = _dayPhase[timeStr] - i
                        while (deltaPhases < 0) do
                            deltaPhases = deltaPhases + #_dayPhase
                        end
                        for i = 1, deltaPhases do
                            TheWorld:PushEvent("ms_nextphase")
                        end
                        return
                    end
                end
            end
            if (_seasonPhase[timeStr]) then
                if (not TheWorld) then
                    print("world error(not ready?)")
                    return
                end
                TheWorld:PushEvent("ms_setseason", timeStr)
                return
            end
        end
        if (results[1] == "set" or results[1] == "add") then
            local seconds
            local d = tonumber(timeStr)
            if (d) then
                if (results[1] == "set") then
                    d = d - (TheWorld.state.cycles + TheWorld.state.time)
                end
                seconds = d * _timeLength.d
            else
                seconds = (results[1] == "set") and (_timeLength.d * (0 - (TheWorld.state.cycles + TheWorld.state.time))) or 0
                local _timeStr = timeStr
                while (true) do
                    local s, e, n, u = _timeStr:find("([+-]?[0-9%.]+)([ydhs])")
                    n = tonumber(n)
                    if (s ~= 1 or (not n)) then
                        print("unable to parse " .. timeStr)
                        return
                    end
                    _timeStr = _timeStr:sub(e + 1)
                    seconds = seconds + (n * _timeLength[u])
                    if (_timeStr == "") then
                        break
                    end
                end
            end

            if (seconds < 0) then
                TheNet:SystemMessage("无法时间倒流...")
                return
            else
                LongUpdate(seconds)
                return
            end
        end

    end,

    kill = function(argStr, guid, x, z, modenv)
        _actForEnts("kill", function(ent)
            local health = ent.components and ent.components.health
            if health ~= nil then
                if not health:IsDead() then
                    health:Kill()
                end
            else
                ent:Remove()
            end
        end, argStr, guid, x, z, modenv, true)
    end,
    remove = function(argStr, guid, x, z, modenv)
        _actForEnts("remove", function(ent)
            ent:Remove()
        end, argStr, guid, x, z, modenv, true)
    end,
    damage = function(argStr, guid, x, z, modenv)
        local startIndex, _, num, isPercent = argStr:find(" ([%+-%d%.]+)(%%?) ?$")
        isPercent = (isPercent == "%")
        num = tonumber(num)

        local s = argStr:split(1, startIndex)

        _actForEnts("damage", function(ent)
            local health = ent.components and ent.components.health
            if health ~= nil then
                if not health:IsDead() then
                    if (num) then
                        if (isPercent) then
                            local percent = health:GetPercent()
                            health:SetPercent(percent - (num / 100), nil, "damage command")
                        else
                            health:DoDelta(num, "damage command")
                        end
                    else
                        health:DoDelta(health.currenthealth or 0, nil, "damage command")
                    end
                end
            end
        end, s, guid, x, z, modenv, false)
    end,
    locate = function(argStr, guid, x, z, modenv, aliasname)
        -- todo 这命令没啥用啊...
        local ents = _actForEnts((aliasname or "locate"), fn.DUMMY, argStr, guid, x, z, modenv)

        if (#ents == 0) then
            TheNet:SystemMessage('no entity matched (arg: "' .. argStr .. '").')
            return
        end
        if (#ents == 1) then
            local ent = ents[1]
            TheNet:SystemMessage('only 1 entity matched (arg: "' .. argStr .. '").')
            if (isValidEnt(ent)) then
                local X, Y, Z = ent.Transform:GetWorldPosition() -- 避开arg同名
                local pos = (Y == 0) and (X .. ", " .. Z) or (X .. ", " .. Y .. ", " .. Z)
                TheNet:SystemMessage('position: ' .. pos)
            end
            return
        end
        TheNet:SystemMessage('found' .. #ents .. ' entities. (arg: "' .. argStr .. '").')
    end,
    sink = function(argStr, guid, x, z, modenv)

        local sinkSource = getCurrentPlayer(guid) or TheWorld

        --WalkablePlatform:DestroyObjectsOnPlatform
        if not TheWorld.ismastersim then
            TheNet:SystemMessage("沉船杀只应该发生在主世界")
            return
        end
        local shore_pt
        _actForEnts("sink", function(ent)

            -- WalkablePlatform:OnRemoveEntity
            if ent.components.drownable ~= nil then
                if shore_pt == nil then
                    shore_pt = Vector3(FindRandomPointOnShoreFromOcean(sinkSource.Transform:GetWorldPosition()))
                end
                ent:PushEvent("onsink", { boat = self.inst, shore_pt = shore_pt })
            else
                ent:PushEvent("onsink", { boat = self.inst })
            end

            --WalkablePlatform:DestroyObjectsOnPlatform
            if (isValidEnt(ent) and (not ent:HasOneOfTags(IGNORE_WALKABLE_PLATFORM_TAGS_ON_REMOVE))) then
                local v = ent
                if v.entity:GetParent() == nil and v.components.amphibiouscreature == nil and v.components.drownable == nil then
                    if v.components.inventoryitem ~= nil then
                        v.components.inventoryitem:SetLanded(false, true)
                    else
                        DestroyEntity(v, self.inst, true, true)
                    end
                end
            end
        end, argStr, guid, x, z, modenv, true)
    end,

    help = function(argStr, guid, x, z, modenv)
        if (isEmptyArg(argStr)) then
            local lang = getLang()
            local commands = ""
            for k, _ in pairs(FUNCTION_MANUAL[lang] or {}) do
                commands = commands .. ' "' .. k .. '"'
            end
            commands = commands:sub(2)

            local args = ""
            for k, _ in pairs(ARG_MANUAL[lang] or {}) do
                args = args .. ' "' .. k .. '"'
            end
            args = args:sub(2)

            TheNet:SystemMessage("available command manuals: " .. commands .. ".\n available arg manuals: " .. args .. ".\nuse /help <command or arg> for help.")
            return
        end
        local arg = argStr:gsub(" ", ""):lower()



        -- 缩 进 大 师 屎 山 代 码
        for _, lang in ipairs({ getLang(), getDefaultLang() }) do
            for _, manual in ipairs({ FUNCTION_MANUAL, ARG_MANUAL }) do
                if (manual[lang]) then
                    for k, v in pairs(manual[lang]) do
                        if (k:gsub(" ", ""):lower() == arg) then
                            TheNet:SystemMessage(v)
                            return
                        end
                    end
                end
            end
        end
    end
}

for aliasName, originalName in ipairs({ s = "save", R = "reset", stop = "shutdown", find = "locate" }) do
    assert(functionAlias[originalName] and not functions[aliasName])
    functions[aliasName] = function(argStr, guid, x, z, modenv)
        return functions[originalName](argStr, guid, x, z, modenv, aliasName)
    end
    for lang, manual in pairs(FUNCTION_MANUAL) do
        assert(manual[originalName] and not manual[aliasName])
        manual[aliasName] = manual[originalName]
    end
end

local MC_COMMAND_PREFIX = "/"
return {
    priority = 0,
    test = function(fnstr, guid, x, z, modenv)
        if (startsWith(fnstr, MC_COMMAND_PREFIX)) then
            return true
        end
        return false
    end,
    apply = function(fnstr, guid, x, z, modenv)
        local str = fnstr:sub(#MC_COMMAND_PREFIX + 1)
        local tmp = split(str, " ", 2)
        local command = tmp[1]
        local args = tmp[2] and tmp[2] .. " " or " " -- 接个空格方便写正则

        local commandFn = functions[command]
        if (commandFn) then
            local r = commandFn(args, guid, x, z, modenv)
            return r or {
                shouldContinue = false,
                disableOriginalExecutor = true
            }
        else
            TheNet:SystemMessage('command "' .. command .. '" not found. check mcCommands.lua for all commands.')
        end
    end
}