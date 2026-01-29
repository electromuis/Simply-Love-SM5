local af = Def.ActorFrame {
    OnCommand=function(self)
        SYNCMAN:JoinTemporary(GAMESTATE:GetCurrentSong())
    end,
    SyncStartStartMessageCommand=function(self)
        local top_screen = SCREENMAN:GetTopScreen()
        top_screen:SetNextScreenName(Branch.GameplayScreen()):StartTransitioningScreen("SM_GoToNextScreen")
    end,
    SyncStartResponsejoinTemporaryLobbyMessageCommand=function(self, data)
        if data.success ~= true then
            SM("ITGO error: " .. data.message)
            local top_screen = SCREENMAN:GetTopScreen()
            top_screen:SetNextScreenName(Branch.GameplayScreen()):StartTransitioningScreen("SM_GoTopREVScreen")
        else
            SYNCMAN:SendUpdate()
        end
    end
}

af[#af+1] = LoadActor("./../ScreenEvaluation common/Shared/TitleAndBanner.lua")
af[#af+1] = LoadActor("./../ScreenEvaluation common/Shared/SongFeatures.lua")

af[#af+1] = LoadActor("./PlayerList.lua")
af[#af+1] = LoadActor("./ReadyBanner.lua")

return af