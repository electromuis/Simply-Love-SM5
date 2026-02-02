local AlphabetWheel = {}

---------------------------------------------------------------------------
AlphabetWheel = setmetatable({}, sick_wheel_mt)
AlphabetWheel["text"] = ""
AlphabetWheel["isOpen"] = false
AlphabetWheel["title"] = "Entry"
AlphabetWheel["handler"] = nil
AlphabetWheel["actor"] = nil
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

local inputHandler = LoadActor("InputHandler.lua", { AlphabetWheel })
---------------------------------------------------------------------------
-- Primary ActorFrame
local t = Def.ActorFrame {
	name="KeyboardOverlay",
	InitCommand=function(self)
		AlphabetWheel["actor"] = self
		self:visible(false)
		self:queuecommand("CaptureInput")
	end,
	OpenKeyboardMessageCommand=function(self, params)
		if AlphabetWheel.isOpen == false then
			AlphabetWheel["text"] = ""
			AlphabetWheel["title"] = params.title
			self:GetChild("Title"):settext( AlphabetWheel.title )
			AlphabetWheel:set_info_set(PossibleCharacters, 2)
			
			local topscreen = SCREENMAN:GetTopScreen()
			topscreen:AddInputCallback( inputHandler )

			self:visible(true)
			AlphabetWheel.isOpen = true
			
		end
	end,
	CloseKeyboardMessageCommand=function(self)
		if AlphabetWheel.isOpen == true then
			local topscreen = SCREENMAN:GetTopScreen()
			topscreen:RemoveInputCallback( inputHandler )

			self:visible(false)
			AlphabetWheel.isOpen = false
		end
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

		if AlphabetWheel["handler"] then
			AlphabetWheel["handler"]({text = AlphabetWheel.text})
		end
	end,
	Def.Quad{
		Name="TextBackground",
		InitCommand=function(self) 
			self:y(0)
			self:diffuse(0,0,0,0.95)
			self:zoomto(_screen.w, 200)
		end
	},
	LoadFont("Wendy/_wendy white")..{
		Name="Title",
		InitCommand=function(self) self:zoom(0.6):halign(0.5):y(-50) end,
	},
	LoadFont("Wendy/_wendy white")..{
		Name="TextField",
		InitCommand=function(self) self:zoom(0.75):halign(0.5):y(60) end,
		OnCommand=function(self)
			self:settext( AlphabetWheel.text )
		end,
		SetCommand=function(self)
			self:settext( AlphabetWheel.text )
		end
	}
}

t[#t+1] = AlphabetWheel:create_actors( "AlphabetWheel", 9, alphabet_character_mt, 0, 0)

-- ActorSounds
t[#t+1] = LoadActor( THEME:GetPathS("", "_change value"))..{    Name="delete",  IsAction=true, SupportPan=true }
t[#t+1] = LoadActor( THEME:GetPathS("Common", "start"))..{      Name="enter",   IsAction=true, SupportPan=true }
t[#t+1] = LoadActor( THEME:GetPathS("MusicWheel", "change"))..{ Name="move",    IsAction=true, SupportPan=true }
t[#t+1] = LoadActor( THEME:GetPathS("common", "invalid"))..{    Name="invalid", IsAction=true, SupportPan=true }

--
return t
