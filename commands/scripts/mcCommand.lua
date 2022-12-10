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
---数字比较器格式："1" "1..2" "1.." "..2" ">1" ">=1" "<1" "<=1" "~=1" "!=1"
---    如果数字比较器所比较的是某个简写的组件，那么可以通过加入百分号（随便加在哪里）来改为比较组件的值的百分比。
---    注意：由于数字比较器的开销，传进来之前就得用 numberCmp 转换为函数比较器！！！
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
local filterOverrides = {
    --- 实体prefab是否满足正则
    type = function(regex)
        return function(ent)
            return ent.prefab and ent.prefab:find(regex)
        end
    end,

    --- 实体生命值、理智、饱食度、耐久、新鲜度的值（或其百分比）是否满足范围
    hp = function(arg)
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
filterOverrides.san = filterOverrides.sanity
filterOverrides.use = filterOverrides.finiteuses
filterOverrides.rot = filterOverrides.perishable

local NBTOverrides = {
    hp = function(arg)
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
filterOverrides.san = filterOverrides.sanity
filterOverrides.use = filterOverrides.finiteuses
filterOverrides.rot = filterOverrides.perishable

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
            for i, ent in pairs() do
                if (ent[k] == nil) then
                    ent[k] = {}
                end
            end
            local newStack = shallowcopy(stack)
            table.insert(newStack, k)
            normalFiliter(ents, v, newStack)
        else
            for i, ent in pairs() do
                ent[k] = v
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
            local f = metaFn(filters[k])

            -- 用过滤器晒一遍实体
            for i, v in pairs(ents) do
                if (not f(v)) then
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

--[[
选择器
example：
    @e[c=20 x="..15" y=0 mustTag="edible_SEEDS" cantTag="meat" rot="绿"] 寻找自己20单位（5地皮）内，坐标x小于15，坐标y为0，有种子标签没有肉标签，新鲜度为绿（大于50%）的实体。

    @e[prefab="flower"] 寻找所有的prefab为"flower"的实体（花）
    @e[prefab="flow".."er"] 你可以在选择器里干很多事情，调用 TUNING 或者像mod开发者一样使用 GLOBAL 也是 ok 的
    @e[type="flow.*"] 寻找所有prefab满足正则表达式："flow.*" 的实体

    @e[c={x=10,z=10,range=20}]搜索范围改为 10,0,10 为球心，半径20单位的球。
    @e[c=20] 类似的简写，不过是以你为中心。
    @e[pos=function(x,y,z,player,GLOBAL) return x+y+z=114.514 end] 你可以自定义坐标检查函数，不过每个实体都要被调用一次，所以时间成本会比较高
    @e[x="..10"] 寻找x坐标小于10的实体，由于这不是mc所以实际上不是很好用。

    @e[hp="<10%"]寻找血量小于10%的实体

    @e 所有实体
    @s 命令的执行者
    @p 距离最近的其他玩家
    @r 随机玩家
    @a 所有玩家

选择器参数：一个 lua 可执行文件，类似于 modinfo 的样子。如果是注册的值则需要满足对应规则，如果是没注册的值，则直接寻找对应值进行比较：类型相同直接判断相等，类型不同则尝试数字比较器、函数比较器、布尔比较器来判断
数字比较器格式："1" "1..2" "1.." "..2" ">1" ">=1" "<1" "<=1" "~=1" "!=1"
    如果数字比较器所比较的是某个简写的组件，那么可以通过加入百分号（随便加在哪里）来改为比较组件的值的百分比。
函数比较器： function(对应值) ... return <是否满足条件> end
布尔比较器：为 true 表示对应值必须能被转换为 true；false 同理。

注册的值：
circle/c: table，为提高性能强烈建议填写！包含 x, y(default 0), z, range 四个参数。也可以是数字，表示以玩家为中心的范围搜索，距离单位是墙。
pos: 打包的函数，参数为 (x,y,z,player,GLOBAL)。
x/y/z: 直接与 目标.Transform:GetWorldPosition() 的值比较
canTag：lua table，如果非空，目标必须包含表中至少一个Tag。也可以是字符串
mustTag(或): lua table, 目标必须包含表中全部 tag。也可以是字符串
cantTag: lua table, 目标必须不包含表中任意一个 tag。也可以是字符串

hp/sanity/san/hunger/use/rot: 字符串，目标必须有对应组件且符合数字比较器（同上，下略）。也可以是数字

type：字符串，正则表达式，目标prefab名字必须匹配表达式。如果不希望使用正则，请使用原生 prefab 变量。

sgTag：字符串，目标.sg:HasStateTag() 必须返回 true。
]]


--[[
数据赋值器
对生成的实体进行一些操作的表达式
用花括号包裹的 lua 表达式。类似于选择器，如果是注册的值则根据对应规则来操作，否则直接对实体的对应值进行操作。
最外层的花括号是语法标记，而内层的花括号将被 lua 处理。

请确保内部代码的花括号（{}）数量一致，否则赋值器会无法找到代码的结尾。（也就是转义、注释、字符串中别出现花括号，如果非要用，自己数数量或者使用 \x7b \x7d）
example：
    {planted=true} （花）设置为人工种植的
    {hp=100} 血量设置为 100
    {y=10} 飞天
    {return function(ent) if(math.random>0.5) then ent:Remove() end end} 灭霸（一半概率删掉实体）

赋值器还可以额外返回一个函数，这个函数可以进一步对实体进行操作。

注册的值：
x/y/z: 设置实体的位置，使用 Transform:SetPosition() 设置

hp/sanity/san/hunger/use/rot: 数字，表示将对应组件设置成该值。也可以是以"%"结尾的数字格式的字符串，视为设置对应比例。
]]

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
                local f = loadstring(arg)
                env = genEnv()
                setfenv(f, env)
                local ok, r = pcall(f)
                if (not ok) then
                    -- 函数执行失败 寄
                    TheNet:SystemMessage("实体选择器参数解析失败")
                    TheNet:SystemMessage(tostring(r))
                    return
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
                    local player = Ents[guid]
                    if (not player) then
                        print("error when parse " .. arg .. ": using player as search range, but player(guid=" .. guid .. ")not found.")
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
                    return filter(shallowcopy(Ents), env, Ents[guid]), s
                end
                -- 妈的，起名起长了...
                searchedEnts = TheSim:FindEntities(findEntitiesArg.x, findEntitiesArg.y, findEntitiesArg.z,
                        findEntitiesArg.range,
                        findEntitiesArg.mustTag, findEntitiesArg.cantTag, findEntitiesArg.canTag)
            end
            return filter(searchedEnts, env, Ents[guid]), s
        end
    end,
    nbt = function(str)
        local _, endIndex, found = str:find("^(%b{}) +")
        if (found) then
            local _, _, arg = found:find("^{(.*)}$")
            assert(found, "正则写错了？")
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

local function _fullTestFormat(str, format)
    local currentStr, results = str, {}
    for _, v in ipairs(format) do
        if (type(v) == "string") then
            local result
            result, currentStr = TYPES[v](currentStr)
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
    if (currentStr == "") then
        return results
    end
end
local function _testFormat(str, format)
    local currentStr, results = str, {}
    for _, v in ipairs(format) do
        if (type(v) == "string") then
            local result
            result, currentStr = TYPES[v](currentStr)
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

---argSplitter 拆分参数
---@param str string 参数
---@param formats table Array<FormatObject>
---FormatObject: table，type 的数组。 type 包括 "number" "numbers" "string" "entities" 和 function(string) return <matched str or nil>, <rest str> end
local function argReader(str, formats)
    for _, format in ipairs(formats) do
        local result = _fullTestFormat(str, format)
        if (result) then
            return result, format
        end
    end
end


--[[ todo
help: 打印文档

damage：对实体造成伤害

sink：对实体进行一次沉船杀
kill：杀死实体，如果没有生命值组件则直接删除
remove：删除实体，这会跳过死亡动画
data：获取某个实体的信息（onsave）
clear：清空实体物品栏


item：修改实体的物品栏

locate/find：搜索实体

forceload：将某个实体视为像玩家一样能加载周围的物品

ability：赋予玩家其他角色的能力
gamemode：切换到创造模式（和上帝模式、隐形混合）或者旁观模式（不会溺水，扣血，被沉船，不会被墙挡住，没有碰撞）

give：给玩家物品

playsound：播放音效

alwaysday/alwaysdusk/alwaysnight：全天白天/黄昏/黑夜
weather：下雨/天晴

execute：以一些实体为 "it"，在 global 环境下依次执行 lua 指令

save/s：c_save()的平替
R：c_reset()的平替
stop/shutdown: c_shutdown() 的平替

time：跳过（LongUpdate）一定时间，数字可以加单位：s/h/d/y->秒/小时/天/年 （默认s）

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

local functions = {
    --[[
    tp
        抄袭自 mc。

        传送自己：
            tp <pos> 由两个数字或三个数字组成的坐标
            tp <player name> 传送到某玩家（名字）
            tp <entity> 将自己传送到指定实体

        传送其他玩家：
            tp <player> <pos> 将玩家传送到指定坐标
            tp <player1> <player2> 将玩家1传送到玩家2
            tp <player> <entity> 将玩家传送到指定实体

        传送一群实体：
            tp <entities> <pos> 将多个实体传送到指定坐标
            tp <entities> <player> 将多个实体传送到指定玩家
            tp <entities> <entity> 将多个实体传送到指定实体
    ]]
    tp = function(argStr, guid, x, z, modenv)
        local args, format = argReader(argStr, {
            ARGS.numbers,
            ARGS.string,
            ARGS.entities,

            ARGS.str_nums,
            ARGS.two_string,
            ARGS.str_ent,

            ARGS.ent_num,
            ARGS.ent_str,
            ARGS.two_ent
        })

        -- 超长switch...我应该用table的...但是我懒得重构。
        -- tp <pos>
        if (format == ARGS.numbers) then
            local player = Ents[guid] or (#AllPlayers == 1 and AllPlayers[1] or nil) -- 如果世界上只有一个玩家，则可以通过服务器控制台传送
            if (not player) then
                print("using tp <pos> but \"current player\" not found")
                return
            end

            local numbers = args[1]
            if (#numbers > 3) then
                print("using tp <pos> but too many numbers")
                return
            elseif (#numbers < 2) then
                print("using tp <pos> but not enough numbers")
                return
            elseif (#numbers == 2) then
                -- x, z -> x, y=0, z
                numbers[3] = numbers[2]
                numbers[2] = 0
            end

            player.Transform:SetPosition(numbers[1], numbers[2], numbers[3])


            -- tp <player name>
        elseif (format == ARGS.string) then
            local player = Ents[guid] or (#AllPlayers == 1 and AllPlayers[1] or nil)
            if (not player) then
                print("using tp <player> but \"current player\" not found")
                return
            end

            local targetPlayer = _name2player(args[1])
            if (not targetPlayer) then
                print("using tp <player> but \"target player\" not found")
                return
            end

            player.Transform:SetPosition(targetPlayer.Transform:GetWorldPosition())

            -- tp <entity>
        elseif (format == ARGS.entities) then
            local player = Ents[guid] or (#AllPlayers == 1 and AllPlayers[1] or nil)
            if (not player) then
                print("using tp <entity> but \"current player\" not found")
                return
            end

            local entities = args[1]
            if (#entities == 0) then
                print("using tp <entity> but entity not found")
                return
            elseif (#entities > 1) then
                print("using tp <entity> but nore than 1 entities found")
                return
            end
            local entity = entities[1]
            player.Transform:SetPosition(entity.Transform:GetWorldPosition())



            -- tp <player> <pos>
        elseif (format == ARGS.str_nums) then
            local targetPlayer = _name2player(args[1])
            if (not targetPlayer) then
                print("using tp <player> <pos> but \"target player\" not found")
                return
            end

            local numbers = args[2]
            if (#numbers > 3) then
                print("using tp <player> <pos> but too many numbers")
                return
            elseif (#numbers < 2) then
                print("using tp <player> <pos> but not enough numbers")
                return
            elseif (#numbers == 2) then
                numbers[3] = numbers[2]
                numbers[2] = 0
            end

            targetPlayer.Transform:SetPosition(numbers[1], numbers[2], numbers[3])


            -- tp <player1> <player2>
        elseif (format == ARGS.two_string) then
            local targetPlayer1 = _name2player(args[1])
            if (not targetPlayer1) then
                print("using tp <player1> <player2> but player 1 not found")
                return
            end

            local targetPlayer2 = _name2player(args[2])
            if (not targetPlayer2) then
                print("using tp <player1> <player2> but player 2 not found")
                return
            end

            player1.Transform:SetPosition(player2.Transform:GetWorldPosition())


            -- tp <player> <entity>
        elseif (format == ARGS.str_ent) then
            local name = args[1]
            local targetPlayer = _name2player(args[1])
            if (not targetPlayer) then
                print("using tp <player> <entity> but \"target player\" not found")
                return
            end

            local entities = args[2]
            if (#entities == 0) then
                print("using tp <player> <entity> but entity not found")
                return
            elseif (#entities > 1) then
                print("using tp <player> <entity> but nore than 1 entities found")
                return
            end
            local entity = entities[1]

            targetPlayer.Transform:SetPosition(entity.Transform:GetWorldPosition())



            -- tp <entities> <pos>
        elseif (format == ARGS.ent_nums) then
            local movingEntities = args[1]
            if (#movingEntities == 0) then
                print("using tp <entities> <player2> but entities(arg1) not found")
                return
            end

            local numbers = args[2]
            if (#numbers > 3) then
                print("using tp <player> <pos> but too many numbers")
            elseif (#numbers < 2) then
                print("using tp <player> <pos> but not enough numbers")
            elseif (#numbers == 2) then
                numbers[3] = numbers[2]
                numbers[2] = 0
            end

            for _, v in ipairs(movingEntities) do
                v.Transform:SetPosition(numbers[1], numbers[2], numbers[3])
            end


            -- tp <entities> <player2>
        elseif (format == ARGS.ent_str) then

            local movingEntities = args[1]
            if (#movingEntities == 0) then
                print("using tp <entities> <player2> but entities(arg1) not found")
                return
            end

            local targetPlayer = _name2player(args[2])
            if (not targetPlayer) then
                print("using tp <entities> <player2> but player 2 not found")
                return
            end

            for _, v in ipairs(movingEntities) do
                v.Transform:SetPosition(targetPlayer.Transform:GetWorldPosition())
            end


            -- tp <entities> <entity>
        elseif (format == ARGS.two_ent) then

            local movingEntities = args[1]
            if (#movingEntities == 0) then
                print("using tp <entities> <entity> but entities(arg1) not found")
                return
            end

            local _entities = args[2]
            if (#_entities == 0) then
                print("using tp <entities> <entity> but entity(arg2) not found")
                return
            elseif (#_entities > 1) then
                print("using tp <entities> <entity> but more than 1 entities(arg2) found")
                return
            end
            local entity = _entities[1]

            for _, v in ipairs(movingEntities) do
                v.Transform:SetPosition(entity.Transform:GetWorldPosition())
            end
        end


    end,

    --[[
    summon
        抄袭自mc
            summon <prefab> <参数...>
        参数可以为：
            at <pos> （如果没有与 count 参数相邻，则 at 可以省略）
            offset <relative pos>
            <count>
            <nbt>
    ]]
    summon = function(argStr, guid, input_x, input_z, modenv)
        local arg = argStr
        local prefab
        local x, y, z, count, nbtFn

        local result, newStr = _testFormat(arg, ARGS.string)
        if (result) then
            prefab = result[1]
            arg = newStr
        else
            print("参数解析失败，必须以prefab开头：", argStr)
            return
        end

        while (true) do
            local result, newStr = nil, nil
            result, newStr = _testFormat(arg, ARGS.str_nums)
            if (result) then
                local dx, dy, dz = 0, 0, 0
                if (result[1] == "offset") then
                    if (input_x and input_z) then
                        dx = input_x
                        dz = input_z
                    elseif (Ents[guid]) then
                        dx, dy, dz = Ents[guid].Transform:GetWorldPosition()
                    elseif (#AllPlayers == 1) then
                        dx, dy, dz = AllPlayers[1].Transform:GetWorldPosition()
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

            result, newStr = nil, nil
            result, newStr = _testFormat(arg, ARGS.numbers)
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

            result, newStr = nil, nil
            result, newStr = _testFormat(arg, ARGS.number)
            if (result) then
                count = result[1]

                arg = newStr
            end

            result, newStr = nil, nil
            result, newStr = _testFormat(arg, ARGS.nbt)
            if (result) then
                nbtFn = result[1]
                arg = newStr
            end

            if (arg == "") then
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

    time = function(argStr, guid, input_x, input_z, modenv)
        if (argStr == "" or argStr:find("^ +$") or argStr:find("^ *query *$")) then
            if (math.random() < 0.1) then
                TheNet:SystemMessage('为什么不直接看右上角？' .. TheWorld.state.cycles + TheWorld.state.time .. '')
            else
                TheNet:SystemMessage('当前世界时间："' .. TheWorld.state.cycles + TheWorld.state.time .. '"')
            end
            print(TheWorld.state.cycles + TheWorld.state.time)
            return
        end
        local args, format = argReader(argStr, { ARGS.str_num , ARGS.two_string})
        if(args[1]=="set")then
            if(format==ARGS.str_num)then
                if(args[2]<=TheWorld.state.cycles + TheWorld.state.time)then
                    TheNet:SystemMessage('无法时间倒流... 当前世界时间："' .. TheWorld.state.cycles + TheWorld.state.time .. '"')
                else
                    LongUpdate(TUNING.TOTAL_DAY_TIME * (args[2] - (TheWorld.state.cycles + TheWorld.state.time)))
                end
            else

            end
        end
    end
}

return {
    priority = 0,
    test = function(fnstr, guid, x, z, modenv)
        if (fnstr:sub(1, 1) == "/") then
            return true
        end
        return false
    end,
    apply = function(fnstr, guid, x, z, modenv)
        local str = fnstr:sub(2)
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