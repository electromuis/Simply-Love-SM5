local Font = "Common Normal"

local MAX_PLAYER_COUNT = 8

local yPos = SCREEN_HEIGHT*0.85
local rowHeight = 22
local boxHeight = rowHeight * MAX_PLAYER_COUNT

local af = Def.ActorFrame {
    InitCommand=function(self)
        
        self:xy(SCREEN_CENTER_X, yPos)
        self:valign(0)
        
    end
}



for i = 1, MAX_PLAYER_COUNT do
    local playerIndex = i

    af[#af+1] = Def.Quad {
        InitCommand=function(self)
            self:zoomto(200, rowHeight)
            self:y(((i - 1) * rowHeight) - boxHeight)
            self:halign(0.5)
            if i % 2 == 0 then
                self:diffuse(Color.White):diffusealpha(0.4)
            else
                self:diffuse(Color.White):diffusealpha(0.45)
            end
        end
    }

    af[#af+1] = Def.BitmapText {
        Font=Font,
        Text="",
        InitCommand=function(self)
            self:valign(0.5)
            self:y(((i - 1) * rowHeight) - boxHeight)
            self:x(-100)
            self:halign(0)
            self:diffuse(Color.White)
            self:visible(false)
            self.playerIndex = playerIndex
        end,
        OnCommand=function(self)
            self:queuecommand("SyncStartLobbyUpdateMessageCommand")
        end,
        SyncStartLobbyUpdateMessageCommand=function(self)
            local players = SYNCMAN:GetCurrentPlayers()

            if #players >= self.playerIndex then
                local player = players[self.playerIndex]
                self:settext(" - " .. player.name)
                self:visible(true)
            else
                self:visible(false)
            end
        end
    }

    af[#af+1] = Def.BitmapText {
        Font=Font,
        Text="",
        InitCommand=function(self)
            self:valign(0.5)
            self:y(((i - 1) * rowHeight) - boxHeight)
            self:x(70)
            self:halign(1)
            self:diffuse(Color.White)
            self:visible(false)
            self.playerIndex = playerIndex
        end,
        OnCommand=function(self)
            self:queuecommand("SyncStartLobbyUpdateMessageCommand")
        end,
        SyncStartLobbyUpdateMessageCommand=function(self)
            local players = SYNCMAN:GetCurrentPlayers()

            if #players >= self.playerIndex then
                local player = players[self.playerIndex]
                self:settext(player.ping .. " ms")
                self:visible(true)
            else
                self:visible(false)
            end
        end
    }

    af[#af+1] = Def.BitmapText {
        Font=Font,
        Text="✔",
        InitCommand=function(self)
            self:valign(0.5)
            self:y(((i - 1) * rowHeight) - boxHeight)
            self:x(100)
            self:halign(1)
            self:visible(false)
            self.playerIndex = playerIndex
        end,
        OnCommand=function(self)
            self:queuecommand("SyncStartLobbyUpdateMessageCommand")
        end,
        SyncStartLobbyUpdateMessageCommand=function(self)
            local players = SYNCMAN:GetCurrentPlayers()

            if #players >= self.playerIndex then
                local player = players[self.playerIndex]
                if player.ready == true then
                    self:visible(true)
                else
                    self:visible(false)
                end
            else
                self:visible(false)
            end
        end
    }

    af[#af+1] = Def.Quad{
		InitCommand=function(self)
			local spacing = 2
            local yPos = ((i - 1) * rowHeight) - boxHeight
            
            self:halign(1)
            self:zoomto(rowHeight, rowHeight)
            self:xy(-100, yPos)
            self:visible(false)
            self.playerIndex = playerIndex
		end,
        OnCommand=function(self)
            self:queuecommand("SyncStartLobbyUpdateMessageCommand")
        end,
        SyncStartLobbyUpdateMessageCommand=function(self)
            local players = SYNCMAN:GetCurrentPlayers()

            if #players >= self.playerIndex then
                local player = players[self.playerIndex]
                self:visible(true)
                self:diffuse(DifficultyColor(player.diffType))
            else
                self:visible(false)
            end
        end
	}

    af[#af+1] = LoadFont("Common Bold")..{
		InitCommand=function(self)
			local spacing = 2
            local yPos = ((i - 1) * rowHeight) - boxHeight
            
            self:halign(0.5)
            self:zoom(0.35)
            self:xy(-100 - (rowHeight/2), yPos)
            self:visible(false)
            self.playerIndex = playerIndex
		end,
        OnCommand=function(self)
            self:queuecommand("SyncStartLobbyUpdateMessageCommand")
        end,
        SyncStartLobbyUpdateMessageCommand=function(self)
            local players = SYNCMAN:GetCurrentPlayers()

            if #players >= self.playerIndex then
                local player = players[self.playerIndex]
                self:visible(true)
                self:settext(player.diffLevel)
            else
                self:visible(false)
            end
        end
	}
end

return af