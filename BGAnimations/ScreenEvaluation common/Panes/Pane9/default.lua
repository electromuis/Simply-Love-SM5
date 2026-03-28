-- Pane9 displays a list of High Scores obrained from the ITGonline game that was just played.

local pane = Def.ActorFrame{
	InitCommand=function(self)
		self:y(_screen.cy - 62):zoom(0.8)
	end
}

-- -----------------------------------------------------------------------

-- 22px RowHeight by default, which works for displaying 10 machine HighScores
local args = { RowHeight=22 }

args.NumHighScores = 10
pane[#pane+1] = LoadActor("./HighScoreList.lua", args)

return pane
