-- only run in modified stepmania build 
if not SYNCMAN or not SYNCMAN:IsEnabled() then
    return Def.Actor{}
end

local MAX_PLAYER_COUNT = 6
local Y_FROM_BOTTOM = 30

local playerNameTexts = {}
local scoreTexts = {}

local isDouble = GAMESTATE:GetCurrentStyle():GetStyleType() == "StyleType_OnePlayerTwoSides"

local t = Def.ActorFrame{
    OnCommand=function(self)
		SYNCMAN.inGame = false
		SCREENMAN:GetTopScreen():PauseGame(true)

        SYNCMAN:Reset() -- Will send update too
        SYNCMAN:Send("startSong", {phase = "ScreenGameplay"})

        -- if SYNCMAN.startAt > 0 then
        --     local startDelay = SYNCMAN.startAt - GetTimeSinceStart()
        --     -- SM(startDelay)
        --     local networkOffset = ThemePrefs.Get("ITGOnlineOffset")
        --     startDelay = startDelay + networkOffset
        --     self:sleep(startDelay):queuecommand("DoStart")
        -- else
        --     self:queuecommand("DoStart")
        -- end
    end,
    SyncStartSongMessageCommand=function(self)
		SYNCMAN.inGame = true
        SCREENMAN:GetTopScreen():PauseGame(false)
    end,

    JudgmentMessageCommand = function(self, params)
        SYNCMAN:SendUpdate()
    end,
    ExCountsChangedMessageCommand = function(self, params)
        SYNCMAN:SendUpdate()
    end,
    PlayerFailedMessageCommand = function(self, params)
        SYNCMAN:SendUpdate()
    end,
    OffCommand=function(self)
        -- Ensure final state is pushed when leaving gameplay.
        SYNCMAN:SendUpdate()
    end,

    SyncStartLobbyUpdateMessageCommand=function(self)
        local scores = SYNCMAN:GetCurrentPlayers()

        for i = 1, MAX_PLAYER_COUNT do
            local scoreIndex = (i - (MAX_PLAYER_COUNT - #scores))

            if scoreIndex > 0 and scoreIndex <= #scores then
                local score = scores[scoreIndex]
                local color = score.failed and color("1,0.3,0.3,0.4") or color("1,1,1,0.5")
                playerNameTexts[i]:settext(score.name):diffuse(color)
                scoreTexts[i]:settext(FormatPercentScore(score.score / 100):gsub("%%", "")):diffuse(color)
            else
                playerNameTexts[i]:settext("")
                scoreTexts[i]:settextf("")
            end
        end
    end
}

for i = 1, MAX_PLAYER_COUNT do
local playerIndex = MAX_PLAYER_COUNT - i + 1

t[#t+1] = Def.BitmapText{
    Font="Miso/_miso light",
    Text="",
    InitCommand=function(self)
        playerNameTexts[playerIndex] = self
        if isDouble then
            self:x(20)
            self:align(0, 0.5)
        else
            self:CenterX()
            self:align(0.5, 0.5)
        end

        self:zoom(0.75)
        self:y(SCREEN_HEIGHT - (i * 40) - Y_FROM_BOTTOM)
    end
}

t[#t+1] = Def.BitmapText{
    Font="Wendy/_wendy small",
    Text="",
    InitCommand=function(self)
        scoreTexts[playerIndex] = self
        if isDouble then
            self:x(20)
            self:align(0, 0.5)
        else
            self:CenterX()
            self:align(0.5, 0.5)
        end

        self:zoom(0.25)
        self:y(SCREEN_HEIGHT - (i * 40) - Y_FROM_BOTTOM + 15)
    end
}
end
  
return t
