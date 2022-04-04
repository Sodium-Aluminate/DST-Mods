Assets = {
    Asset( "ATLAS", "images/emptyroad.xml")
}

local emptyroadtex = GLOBAL.resolvefilepath("images/emptyroad.tex")

GLOBAL = GLOBAL.setmetatable(GLOBAL, { __newindex = function(t, k, v)
	if (k=="RoadManager") then
		print("catch RoadManager")
		local OldSetStripTextures = v.SetStripTextures
		local road_manager_index = GLOBAL.getmetatable(v).__index
		road_manager_index.SetStripTextures = function() print("NoRoadLog: function SetStripTextures hooked") end
		road_manager_index.SetStripTextures = function(self, roadType, mask, normal, mini)
			
			print("NoRoadLog: self, roadType, mask, normal, mini: \n",self, roadType, mask, normal, mini)
			OldSetStripTextures(self, roadType, mask, emptyroadtex, emptyroadtex)
			
		end
		--[[ 原调用为：
			RoadManager:SetStripTextures(
				ROAD_STRIPS.CENTER,
				resolvefilepath("images/square.tex"),
				resolvefilepath("images/roadnoise.tex") ,
				resolvefilepath("images/roadnoise.tex")
			)
		]]

	end
	
	GLOBAL.rawset(GLOBAL, k, v)
end })

