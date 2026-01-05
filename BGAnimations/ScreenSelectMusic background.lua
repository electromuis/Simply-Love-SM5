SYNCMAN:WS() -- Initialize the WebSocket connection

return Def.ActorFrame{
	OnCommand=function(self)
		SYNCMAN:Reset()
		self:sleep(0.5):queuecommand("ListRooms")
	end,

	ListRoomsCommand=function(self)
		SYNCMAN:Send("searchLobby", {temporary = true})
	end,
	
	Def.Quad{
		InitCommand=function(self) self:FullScreen():Center():diffuse( Color.White ) end
	},

	LoadActor( THEME:GetPathB("", "_shared background") ),

	Def.Quad{
		InitCommand=function(self)
			self:diffuse((ThemePrefs.Get("VisualStyle") == "SRPG6") and Color.Black or Color.White)
				:Center()
				:FullScreen()
				:sleep(0.6):linear(0.5):diffusealpha(0)
				:queuecommand("Hide")
		end,
		HideCommand=function(self) self:visible(false) end
	}
}
