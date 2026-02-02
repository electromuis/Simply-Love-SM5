local AlphabetWheel = {}

---------------------------------------------------------------------------
AlphabetWheel = setmetatable({}, sick_wheel_mt)
AlphabetWheel["text"] = ""
AlphabetWheel["isOpen"] = false
---------------------------------------------------------------------------
-- Add the reusable metatable for a generic alphabet character
local alphabet_character_mt = LoadActor("./AlphabetCharacterMT.lua")

---------------------------------------------------------------------------
-- Alphanumeric Characters available to our players for highscore name use
local PossibleCharacters = {
	"&BACK;", "&OK;",
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
	"N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "?", "!"
}
---------------------------------------------------------------------------
-- Primary ActorFrame
local t = Def.ActorFrame {
	name="Password",
	InitCommand=function(self)
		self:visible(false)
		self:queuecommand("CaptureInput")
	end,
	OpenKeyboardMessageCommand=function(self)
		if AlphabetWheel.isOpen == false then
			self:visible(true)
			AlphabetWheel.isOpen = true
			
		end
	end,
	CloseKeyboardMessageCommand=function(self)
		if AlphabetWheel.isOpen == true then
			self:visible(false)
			AlphabetWheel.isOpen = false
		end
	end,
	CaptureInputCommand=function(self)
		local topscreen = SCREENMAN:GetTopScreen()
		-- -- if a profile is in use and has a HighScoreName, make the starting index 2 ("ok"); otherwise, 3 ("A")
		-- local StartingCharIndex = (profile and (profile:GetLastUsedHighScoreName() ~= "") and 2) or 3
		AlphabetWheel:set_info_set(PossibleCharacters, 0)
		-- actually attach the InputHandler function to our screen
		topscreen:AddInputCallback( LoadActor("InputHandler.lua", {self, AlphabetWheel}) )
	end,
	AttemptToFinishCommand=function(self)
		if AlphabetWheel.isOpen then
			self:playcommand("Finish")
		end
	end,
	FinishCommand=function(self)
		-- Value: SL[ToEnumShortString(player)].HighScores.Name

		-- manually transition to the next screen (defined in Metrics)
		-- SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
		MESSAGEMAN:Broadcast("TextEntered", { text = AlphabetWheel.text } )
	end,
	Def.Quad{
		Name="TextBackground",
		InitCommand=function(self) 
			self:y(50)
			self:diffuse(0,0,0,0.9)
			self:zoomto(_screen.w, 80)
		end
	},
	LoadFont("Wendy/_wendy white")..{
		Name="TextField",
		InitCommand=function(self) self:zoom(0.75):halign(0):xy(-80,60) end,
		OnCommand=function(self)
			self:settext( AlphabetWheel.text )
		end,
		SetCommand=function(self)
			self:settext( AlphabetWheel.text )
		end
	}
}

-- Things that are constantly on the screen (fallback banner + masks)
t[#t+1] = Def.ActorFrame {

	--fallback banner
	-- LoadActor(GetFallbackBanner())..{
	-- 	OnCommand=function(self) self:xy(_screen.cx, 121.5):zoom(0.7) end
	-- },

	-- Def.Quad{
	-- 	Name="LeftMask",
	-- 	InitCommand=function(self) self:horizalign(left) end,
	-- 	OnCommand=function(self) self:xy(0, _screen.cy):zoomto(_screen.cx-272, _screen.h):MaskSource() end
	-- },

	-- Def.Quad{
	-- 	Name="CenterMask",
	-- 	OnCommand=function(self) self:Center():zoomto(110, _screen.h):MaskSource() end
	-- },

	-- Def.Quad{
	-- 	Name="RightMask",
	-- 	InitCommand=function(self) self:horizalign(right) end,
	-- 	OnCommand=function(self) self:xy(_screen.w, _screen.cy):zoomto(_screen.cx-272, _screen.h):MaskSource() end
	-- }
}

t[#t+1] = AlphabetWheel:create_actors( "AlphabetWheel", 7, alphabet_character_mt, 0, 0)

-- ActorSounds
t[#t+1] = LoadActor( THEME:GetPathS("", "_change value"))..{    Name="delete",  IsAction=true, SupportPan=true }
t[#t+1] = LoadActor( THEME:GetPathS("Common", "start"))..{      Name="enter",   IsAction=true, SupportPan=true }
t[#t+1] = LoadActor( THEME:GetPathS("MusicWheel", "change"))..{ Name="move",    IsAction=true, SupportPan=true }
t[#t+1] = LoadActor( THEME:GetPathS("common", "invalid"))..{    Name="invalid", IsAction=true, SupportPan=true }

--
return t
