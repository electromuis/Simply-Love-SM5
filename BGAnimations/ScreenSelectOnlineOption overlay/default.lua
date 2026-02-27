local active_index = 0
local list_selected = false
local t

local options = {
	{
		Label = "Available Lobbies",
		Handler = function()
			if list_selected == false then
				list_selected = true
				SOUND:PlayOnce(THEME:GetPathS("Common", "Start"))
				t:queuecommand("GainFocus")
				t:queuecommand("Selected")
			else
				t:queuecommand("SelectLobby")
			end
		end
	},
	{
		Label = "Refresh List",
		Handler = function()
			SYNCMAN:Send("searchLobby", {temporary = false})
		end
	},
	{
		Label = "Create Lobby",
		Handler = function()
			t:queuecommand("CreateLobby")
		end
	},
	{
		Label = "Go Back",
		Handler = function()
			SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToPrevScreen")
		end
	}
}

local holding = {
	["MenuRight"]=false,
	["MenuLeft"]=false,
}

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
			if options[active_index+1] and options[active_index+1].Handler then
				options[active_index+1].Handler()
			end
		elseif event.GameButton == "Select" or event.GameButton == "Back" then
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

	return true
end

local af = Def.ActorFrame{
	OnCommand=function(self)
		t=self
		self:Center()
		SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)
		self:queuecommand("Hover")
	end,
	CreateLobbyCommand=function(self)
		MESSAGEMAN:Broadcast("OpenKeyboard", {
			title="Lobby password",
			handler=function(params)
				MESSAGEMAN:Broadcast("CloseKeyboard")
				SYNCMAN:Send("createLobby", {password = params.text, machine=SYNCMAN:GetMachineState()})
			end
		})
	end,
	OpenKeyboardMessageCommand=function(self)
		SCREENMAN:GetTopScreen():RemoveInputCallback(InputHandler)
	end,
	CloseKeyboardMessageCommand=function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)
	end,
	SyncStartResponsejoinLobbyMessageCommand=function(self, data)
		if data.success == true then
			SYNCMAN:SendUpdate()
			SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
		else
			SM("Failed to join lobby")
		end
	end,
	SyncStartResponsecreateLobbyMessageCommand=function(self, data)
		if data.success == true then
			SYNCMAN:SendUpdate()
			SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
		else
			SM("Failed to create lobby")
		end
	end
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
		self:playcommand("UpdateData", {data=SYNCMAN.rooms})
		SYNCMAN:Send("searchLobby", {temporary = false})
	end,
	SyncStartRoomsChangedMessageCommand=function(self)
		self:playcommand("UpdateData", {data=SYNCMAN.rooms})
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
		-- Text="1/"..#candidates,
		Text="",
		InitCommand=function(self)
			self:horizalign(right):x(170):y(-170)
		end,
		UpdateIndexCommand=function(self, params)
			if params.total == 0 then
				self:settext("0")
			else
				self:settext(params.idx .. "/" .. params.total)
			end
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
				Text=option.Label,
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

af[#af+1] = LoadActor("Keyboard/default.lua")

return af