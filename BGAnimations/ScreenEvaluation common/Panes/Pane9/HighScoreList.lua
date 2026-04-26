local args = ...
-- the number of HighScores to retrieve, indexed by "NumHighScores"; default to 5 if none is provided
local NumHighScores = args.NumHighScores or 5

local af = Def.ActorFrame{
	Name="HighScoreList",

	OnCommand=function(self)
		SYNCMAN:SendUpdate()
	end,

	InitCommand=function(self)
		self:queuecommand("Update")
	end,

	OnlineLobbyStateMessageCommand=function(self)
		self:queuecommand("Update")
	end,

	UpdateCommand=function(self)
		local scores = SYNCMAN:GetCurrentPlayers()
		for i=1,NumHighScores do
			if scores[i] then
				local score = scores[i]

				self:GetChild("HighScoreEntry"..i):GetChild("Name"):settext(score.profileName)
				self:GetChild("HighScoreEntry"..i):GetChild("Score"):settext(FormatPercentScore(score.score / 100))

				if playerObj then
					self:GetChild("HighScoreEntry"..i):GetChild("Diff"):settext(score.diffLevel)
				end
			else
				self:GetChild("HighScoreEntry"..i):GetChild("Name"):settext("----")
				self:GetChild("HighScoreEntry"..i):GetChild("Score"):settext("------")
				self:GetChild("HighScoreEntry"..i):GetChild("Diff"):settext("----")
			end
		end
	end
}

-- ---------------------------------------------
-- setup involving optional arguments that might have been passed in via a key/value table

local Font = args.Font or "Common Normal"
local row_height = args.RowHeight or 22

-- ---------------------------------------------
-- lower and upper will be used as loop start and end points
-- we'll loop through the the list of highscores from lower to upper indices
-- initialize them to 1 and NumHighScores now; they may change later
local lower = 1
local upper = NumHighScores

-- ---------------------------------------------

for i=lower,upper do
	local row_index = i-lower
	local row = Def.ActorFrame{Name="HighScoreEntry"..(row_index+1)}

	row[#row+1] = LoadFont(Font)..{
		Name="Rank",
		Text=i..". ",
		InitCommand=function(self) self:horizalign(right):xy(-120, row_index*row_height) end,
	}

	row[#row+1] = LoadFont(Font)..{
		Name="Name",
		InitCommand=function(self) self:horizalign(left):xy(-110, row_index*row_height) end,
	}

	row[#row+1] = LoadFont(Font)..{
		Name="Score",
		InitCommand=function(self) self:horizalign(left):xy(-24, row_index*row_height) end,
	}

	row[#row+1] = LoadFont(Font)..{
		Name="Diff",
		InitCommand=function(self) self:horizalign(center):xy(80, row_index*row_height) end,
	}

	af[#af+1] = row

	row_index = row_index + 1
end


return af
