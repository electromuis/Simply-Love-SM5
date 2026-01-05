local af = Def.ActorFrame {
    InitCommand=function(self)
        SYNCMAN:Join(SYNCMAN:JoinTemporary(GAMESTATE:GetCurrentSong()))
        -- TODO: Handle result
    end,
    SyncStartStartMessageCommand=function(self)
        local top_screen = SCREENMAN:GetTopScreen()
        top_screen:SetNextScreenName(Branch.GameplayScreen()):StartTransitioningScreen("SM_GoToNextScreen")
    end
}

af[#af+1] = LoadActor("./../ScreenEvaluation common/Shared/TitleAndBanner.lua")
af[#af+1] = LoadActor("./../ScreenEvaluation common/Shared/SongFeatures.lua")

af[#af+1] = LoadActor("./PlayerList.lua")
af[#af+1] = LoadActor("./ReadyBanner.lua")

return af