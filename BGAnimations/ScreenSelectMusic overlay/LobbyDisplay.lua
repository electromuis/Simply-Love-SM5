local NoScrollHandler = function(event)
    if event.GameButton == "MenuRight" or event.GameButton == "MenuLeft" then
        return true
    end

    return false
end

local af = Def.ActorFrame{
    InitCommand=function(self)
        -- self:valign(0)
        SYNCMAN:Reset()
        
        self:visible(false)
        self:xy(30, _screen.cy)

        self:queuecommand("Update")
	end,

    SongSelectedMessageCommand=function(self, data)
        local topScreen = SCREENMAN:GetTopScreen()
        if topScreen and topScreen:GetName() == "ScreenSelectMusic" then
            local song = SONGMAN:FindSong(data.songInfo.songPath)
            local wheel = topScreen:GetMusicWheel()
            if song and wheel then
                wheel:SelectSong(song)
                wheel:Move(1)
                wheel:Move(-1)
                wheel:Move(0)

                -- Block user from changing the song
                SCREENMAN:GetTopScreen():AddInputCallback(NoScrollHandler)
            else
                for player in ivalues( PlayerNumber ) do
                    local pn = ToEnumShortString(player)
                    SYNCMAN.readyStatus[pn] = false
                end
                SYNCMAN:SendUpdate()

                SM("Failed to find song: " .. tostring(data.songInfo.title))
            end
        end
	end,

    SyncStartLobbyUpdateMessageCommand=function(self)
        self:queuecommand("Update")
    end,

	ListRoomsCommand=function(self)
		SYNCMAN:Send("searchLobby", {temporary = true})
	end,
    OnCommand=function(self)
        self:sleep(0.5):queuecommand("ListRooms")
        self:queuecommand("Update")
    end,
    UpdateCommand=function(self)
        if SYNCMAN.lobby == nil then
            self:visible(false)
            return
        end

        self:visible(true)
    end,

    LoadFont("Common Bold")..{
        Text="",
        InitCommand=function(self)
            self:zoom(0.4)
        end,
        UpdateCommand=function(self)
            if SYNCMAN.lobby then
                self:settext( SYNCMAN.lobby.code )
            end
        end
    }
}

local Font = "Common Normal"

local MAX_PLAYER_COUNT = 8

local yPos = SCREEN_HEIGHT*0.85
local rowHeight = 12

for i = 1, MAX_PLAYER_COUNT do
    local playerIndex = i

    af[#af+1] = Def.BitmapText {
        Font=Font,
        Text="",
        InitCommand=function(self)
            -- self:valign(0.5)
            self:y((i)*rowHeight)
            -- self:x(-100)
            -- self:halign(0)
            self:zoom(0.5)
            self:diffuse(Color.White)
            self:visible(false)
            self.playerIndex = playerIndex
        end,
        UpdateCommand=function(self)
            local players = SYNCMAN:GetCurrentPlayers()

            if #players >= self.playerIndex then
                local player = players[self.playerIndex]
                self:settext(player.name)
                self:visible(true)
            else
                self:visible(false)
            end
        end
    }
end

return af