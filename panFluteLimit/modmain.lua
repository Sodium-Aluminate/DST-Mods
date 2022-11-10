
assert = GLOBAL.assert
DataDumper = GLOBAL.DataDumper
local randomUsageLogic = GetModConfigData("RANDOM_USAGE_LOGIC")
local minUsage = GetModConfigData("MIN_USAGE")
local maxUsage = randomUsageLogic == "ALWAYS_MIN" and minUsage or GetModConfigData("MAX_USAGE")

assert(maxUsage >= minUsage, "最大次数不能小于最小次数")

local function randomBreakWhenUsage(inst_prefab, musician)

end

local hookLogic = {}

hookLogic.RANDOM_WHEN_GEN = function(panFlutePrefab)
    local finiteuses = panFlutePrefab.components.finiteuses
    finiteuses:SetMaxUses(math.random(minUsage, maxUsage))
    if(finiteuses:GetPercent()>1)then
        finiteuses:SetPercent(1)
    end
end

hookLogic.ALWAYS_MIN = hookLogic.RANDOM_WHEN_GEN

hookLogic.RANDOM_WHEN_USAGE = function(panFlutePrefab)
    local finiteuses = panFlutePrefab.components.finiteuses
    finiteuses:SetMaxUses(maxUsage)
    if(finiteuses:GetPercent()>1)then
        finiteuses:SetPercent(1)
    end
    local oldUseFn = finiteuses.Use
    function finiteuses:Use(num)
        local _num = num or 1
        if (
                self.current <= (maxUsage - minUsage) -- 耐久进入随机损坏阶段
                        and math.random() < (_num / (self.current)) -- 随机损坏判定成功
                --[[
                    example1：最少十次，最多十五次，当前剩余次数为六
                        期望损坏为“物品在第10-15次使用时损坏的概率相同”，因此此时有 1/6 的概率损坏
                    example2：最少十次，最多十五次，当前剩余次数为五。由于已经判过一次了，因此此时有 1/5 的概率损坏
                    example3：最少十次，最多十五次，当前剩余次数为六，但本次使用次数为2，此时有 2/6 的概率损坏
                ]]
        ) then
            _num = self.current -- 直接用光
        end
        oldUseFn(self, _num)
    end
end


AddPrefabPostInit("panflute", function(panFlutePrefab)
    if(not (GLOBAL.TheWorld and GLOBAL.TheWorld.ismastersim))then
        return
    end
    if(panFlutePrefab.components and panFlutePrefab.components.finiteuses)then
        hookLogic[randomUsageLogic](panFlutePrefab)
    else
        print("排箫prefab没有耐久组件？")
        local data, ref = panFlutePrefab:GetPersistData()
        print(DataDumper(data))
    end
end)
