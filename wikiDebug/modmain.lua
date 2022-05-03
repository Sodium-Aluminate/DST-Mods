
local function startsWith(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

local function endsWith(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end
local find=GLOBAL.string.find

GLOBAL.global("alpt_printAllFoodtypeList")

GLOBAL.alpt_printAllFoodtypeList = function()
	--print("log 1")
	local types={}
	local buffer={
		v="",
		_p=function(self, str)
			self.v = self.v .. str .. "\n"
		end,
		p=function(self, str)
			self:_p(str)
			--print(str)
		end
	}
	buffer:p("\n\n== alpt_printAllFoodtypeList ==\n")
	
		for k, v in GLOBAL.pairs(GLOBAL.Prefabs) do
			if 
				startsWith(k,"quagmire") or
				startsWith(k,"reticulearc") or
				startsWith(k,"lavaarena_") or
				startsWith(k,"trails") or
				startsWith(k,"reticulearc") or
				startsWith(k,"rhinodrill") or
				startsWith(k,"lavaarenastage_") or
				startsWith(k,"cave_entrance") or
				startsWith(k,"peghook") or
				endsWith(k,"buff") or
				endsWith(k,"_network") or
				endsWith(k,"_projectile") or
				find(k,"_fx") or
				find(k,"_fx_") or
				k=="cave" or
				k=="world" or
				k=="forest" or
				k=="lavaarena" or
				k=="global" or
				
				k=="boarrior" or
				k=="spear_lance" or
				k=="fireballstaff" or

				k=="wintersfeastoven_fire" or
				k=="spellmasteryorbs" or
				k=="wathgrithr_bloodlustbuff_other" or
				k=="waxwell_shadowstriker" or
				k=="turtillus" or
				k=="explosivehit" or
				k=="damagenumber" or
				k=="healingstaff" or
				k=="rock_light" or
				k=="eyeofterror" or
				k=="turtillus" or
				k=="turtillus" or
				k=="turtillus" or
				k=="turtillus" or
				k=="turtillus" or
				
				
				false
			then
				--print("skip "..k)
			else
				if not (v.fn == nil) then 
					--print(" tring "..k)
					local status, p = GLOBAL.pcall(GLOBAL.SpawnPrefab,k)
						if(status and p and p.components and p.components.edible)then
							local foodtype = ""
							local secondaryfoodtype = ""
							if p.components.edible.foodtype then
								foodtype=p.components.edible.foodtype
							end
							if p.components.edible.secondaryfoodtype then
								secondaryfoodtype=p.components.edible.secondaryfoodtype
							end
							
							print("alpt_got:\t"..k.."\t"..foodtype.."\t"..secondaryfoodtype)
						end
					if(status and p and p.Remove) then
						p:Remove()
					end
				end
			end
		end
	
	--buffer:p(GLOBAL.json.encode(types))
	
	buffer:p("\n== alpt_printAllFoodtypeList ==")
	
	print("all prefabs(without skiped) have tried.")
	--print(buffer.v)
end


local ls = function(t, buffer)
	if not (type(t)=="table") then
		error "not a table"
	end
	for k, v in GLOBAL.pairs(t) do
		buffer:p(GLOBAL.tostring(k)..":\t\t"..GLOBAL.tostring(v))
	end
end

GLOBAL.global("alpt_ls")

GLOBAL.alpt_ls = function(t)
	
	
	local buffer={
		v="",
		_p=function(self, str)
			self.v = self.v .. str .. "\n"
		end,
		p=function(self, str)
			self:_p(str)
			print(str)
		end
	}
	buffer:p("\n\n== alpt_ls ==\n")
	
	if(t==nil) then
		buffer:p("nil")
	else
		if(GLOBAL.type(t) == "table") then

			local ok, exception = GLOBAL.pcall(ls, t, buffer)
			if(ok) then
				
			else
				buffer:p("err: "..exception)
			end
		else
			buffer:p(GLOBAL.tostring(t))
		
		end
	end
	
	
	buffer:p("\n== alpt_ls ==\n\n")
	
	print(buffer.v)
end

