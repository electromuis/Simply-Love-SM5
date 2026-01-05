local animationSpeed = 1

local af = Def.ActorFrame {
    InitCommand=function(self)
        self:xy(SCREEN_CENTER_X, SCREEN_HEIGHT * 0.23)
        self:valign(0)
        self:visible(true)
        self.showing = false
    end,
    OnCommand=function(self)
        self:queuecommand("SyncStartLobbyUpdateMessageCommand")
    end,
    SyncStartLobbyUpdateMessageCommand=function(self)
        local players = SYNCMAN:GetCurrentPlayers()
        for i, player in ipairs(players) do
            if not player.ready then
                self.showing = false
                self:playcommand("Hide")
                return
            end
        end
        self.showing = true
        self:queuecommand("Loop")
        self:playcommand("Show")
    end,
    LoopCommand=function(self)
        self:linear(1/animationSpeed):diffusealpha(0.7):linear(1/animationSpeed):diffusealpha(0.9)
        if self.showing then self:queuecommand("Loop") end
    end
}

af[#af+1] = Def.Quad{ -- Bottom Mask
    InitCommand=function(self) self:zoomto(SCREEN_WIDTH, 100):y(-50):horizalign(center):valign(0):MaskSource() end,
    ShowCommand=function(self) self:linear(0.1):zoomy(0):MaskSource() end,
    HideCommand=function(self) self:linear(0.1):zoomy(100):MaskSource() end,
}

af[#af+1] = Def.Quad{ -- Top Mask
    InitCommand=function(self) self:zoomto(SCREEN_WIDTH, 100):y(50):horizalign(center):valign(1):MaskSource() end,
    ShowCommand=function(self) self:linear(0.1):zoomy(0):MaskSource() end,
    HideCommand=function(self) self:linear(0.1):zoomy(100):MaskSource() end,
}

-- Banner
af[#af+1] = Def.Quad{ InitCommand=function(self) self:zoomto(SCREEN_WIDTH, 100):horizalign(center):diffuse(Color.Black):MaskDest() end }
af[#af+1] = Def.Quad{ InitCommand=function(self) self:zoomto(SCREEN_WIDTH, 8):horizalign(center):y(35):diffuse(Color.White):MaskDest() end }
af[#af+1] = Def.Quad{ InitCommand=function(self) self:zoomto(SCREEN_WIDTH, 8):horizalign(center):y(-35):diffuse(Color.White):MaskDest() end }


af[#af+1] = Def.BitmapText {
    Font="Miso/_miso light",
    Text="READY TO PLAY",
    InitCommand=function(self)
        self:diffuse(Color.White)
        self:zoom(3)
        self:MaskDest()
    end
}

return af