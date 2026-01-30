local active_index = 0
local list_selected = false
local options = { "Available Lobbies", "Refresh List", "Create Lobby", "Go Back" }
local t

local holding = {
	["MenuRight"]=false,
	["MenuLeft"]=false,
}

local candidates = {}
local codes = {
	"AAAA", "BBBB", "CCCC", "DDDD",
	"EEEE", "FFFF", "GGGG", "HHHH"
}
for i=1,8 do
	table.insert(candidates, {
		index=#candidates,
		code=codes[i],
		isPasswordProtected=i % 3 == 0,
		playerCount=i,
		spectatorCount=i < 4 and 0 or 1,
	})
end

local InputHandler = function(event)
  if not event.PlayerNumber or not event.button then return false end

  if event.type == "InputEventType_FirstPress" then
		if event.GameButton == "MenuRight" or event.GameButton == "MenuLeft" then
			holding[event.GameButton] = true
			if holding[event.GameButton == "MenuRight" and "MenuLeft" or "MenuRight"] then
				-- Same as Select below.
				if list_selected then
					list_selected = false
					SOUND:PlayOnce(THEME:GetPathS("Common", "Cancel"))
					t:queuecommand("LoseFocus")
					t:queuecommand("Hover")
				end
			else
				if not list_selected then
					active_index = (active_index + (event.GameButton=="MenuRight" and 1 or -1)) % #options
					SOUND:PlayOnce(THEME:GetPathS("ScreenSelectMaster", "change"))
					t:queuecommand("Hover")
				else
					if event.GameButton == "MenuRight" then
						t:queuecommand("NextLobby")
					else
						t:queuecommand("PrevLobby")
					end
				end
			end
		elseif event.GameButton == "Start" then
			if active_index == 0 then
				list_selected = true
				SOUND:PlayOnce(THEME:GetPathS("Common", "Start"))
				t:queuecommand("GainFocus")
				t:queuecommand("Selected")
			end
		elseif event.GameButton == "Select" then
			if list_selected then
				list_selected = false
				SOUND:PlayOnce(THEME:GetPathS("Common", "Cancel"))
				t:queuecommand("LoseFocus")
				t:queuecommand("Hover")
			end
		end
	elseif event.type == "InputEventType_Release" then
		if event.GameButton == "MenuRight" or event.GameButton == "MenuLeft" then
			holding[event.GameButton] = false
		end
	end
end

local af = Def.ActorFrame{
  OnCommand=function(self)
		t=self
    self:Center()
    SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)
		self:queuecommand("Hover")
  end,
}

af[#af+1] = LoadFont("Common Normal")..{
	Text="&MENULEFT;/&MENURIGHT; to Choose | &START; to Select | &SELECT; or &MENULEFT;+&MENURIGHT; to Return",
	InitCommand=function(self)
		self:y(180)
	end
}

local border = 2

-- Lobby List
af[#af+1] = Def.ActorFrame{
	InitCommand=function(self)
		self:x(-120)
		self.idx = 0
	end,
	OnCommand=function(self)
		self:playcommand("UpdateData", {data=candidates})
	end,

	Def.Quad{
		InitCommand=function(self)
			self:zoomto(360,340):y(-20):diffuse(Color.White)
		end,
		HoverCommand=function(self)
			if not list_selected then
				self:diffuse(active_index == self:GetParent().idx and Color.Yellow or Color.White)
			end
		end,
		SelectedCommand=function(self)
			self:diffuse(active_index == self:GetParent().idx and Color.Green or Color.White)
		end
	},

	Def.Quad{
		InitCommand=function(self)
			self:zoomto(360-border,340-border):y(-20):diffuse(Color.Black)
		end
	},

	Def.Quad{
		InitCommand=function(self)
			self:zoomto(350, 1):y(-150):diffuse(Color.White)
		end
	},

	LoadFont("Common Bold")..{
		Text="Available Lobbies",
		InitCommand=function(self)
			self:horizalign(left):x(-170):y(-170):zoom(0.5)
		end,
		HoverCommand=function(self)
			self:diffuse(active_index == self:GetParent().idx and GetHexColor(SL.Global.ActiveColorIndex) or Color.White)
		end
	},

	LoadFont("Common Normal")..{
		Text="1/"..#candidates,
		InitCommand=function(self)
			self:horizalign(right):x(170):y(-170)
		end,
		UpdateIndexCommand=function(self, params)
			self:settext(params.idx .. "/" .. params.total)
		end
	},

	LoadActor("LobbyInfo.lua")
}

local width = 200
local height = 40
local spacing = 20


for idx, option in ipairs(options) do
	-- Lobby List is special. It's handled above.
	if idx ~= 1 then
		af[#af+1] = Def.ActorFrame{
			InitCommand=function(self) 
				local mid = #options / 2
				self:y((idx - 1 - mid) * (spacing + height))
				self:x(180)
				self.idx = idx - 1
			end,

			Def.Quad{
				InitCommand=function(self)
					self:zoomto(width, height):diffuse(Color.White)
				end,
				HoverCommand=function(self)
					self:diffuse(active_index == self:GetParent().idx and Color.Yellow or Color.White)
				end,
				SelectedCommand=function(self)
					self:diffuse(active_index == self:GetParent().idx and Color.Green or Color.White)
				end
			},

			Def.Quad{
				InitCommand=function(self)
					self:zoomto(width-border, height-border):diffuse(Color.Black)
				end
			},

			LoadFont("Common Bold")..{
				Text=option,
				InitCommand=function(self)
					self:zoom(0.5)
				end,
				HoverCommand=function(self)
					self:diffuse(active_index == self:GetParent().idx and GetHexColor(SL.Global.ActiveColorIndex) or Color.White)
				end
			}
		}
	end
end

af[#af+1] = LoadActor("Keyboard.lua")

return af