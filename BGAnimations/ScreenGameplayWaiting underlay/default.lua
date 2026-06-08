local af = Def.ActorFrame {
    InitCommand=function(self)
		SYNCMAN.readyState.P1 = "Unknown"
		SYNCMAN.readyState.P2 = "Unknown"
    end,
	OnCommand=function(self)
		if SYNCMAN.lobby == nil then
            SYNCMAN:JoinTemporary(GAMESTATE:GetCurrentSong())
        else
            SYNCMAN:SendUpdate()
			if SYNCMAN.lobby.temporary == false then
				SYNCMAN:SelectSong()
			end
        end

		if PREFSMAN:GetPreference("MenuTimer") then
			self:queuecommand("ListenTimer")
		end
	end,
    SyncStartStartMessageCommand=function(self)
        local top_screen = SCREENMAN:GetTopScreen()
        top_screen:SetNextScreenName(Branch.GameplayScreen()):StartTransitioningScreen("SM_GoToNextScreen")
    end,
    SyncStartResponseJoinTemporaryLobbyMessageCommand=function(self, data)
        if data.success ~= true then
            SM("ITGO error: " .. data.message)
            local top_screen = SCREENMAN:GetTopScreen()
            top_screen:SetNextScreenName(Branch.GameplayScreen()):StartTransitioningScreen("SM_GoTopREVScreen")
        else
            SYNCMAN:SendUpdate()
        end
    end,
	-- ListenTimerCommand=function(self)
	-- 	local topscreen = SCREENMAN:GetTopScreen()
	-- 	local seconds = topscreen:GetChild("Timer"):GetSeconds()

	-- 	if seconds <= 0 then
	-- 		for player in ivalues( PlayerNumber ) do
	-- 			if GAMESTATE:IsHumanPlayer(player) then
	-- 				local pn = ToEnumShortString(player)
	-- 				SYNCMAN.readyState[pn] = true
	-- 			end
	-- 		end	
			
	-- 		SYNCMAN:SendUpdate()
	-- 		MESSAGEMAN:Broadcast("SyncStartLobbyUpdate")
	-- 		SYNCMAN:Send("startSong", {phase = "ScreenGameplayWaiting"})
	-- 	else
	-- 		self:sleep(0.5)
	-- 		self:queuecommand("ListenTimer")
	-- 	end
	-- end,
}

af[#af+1] = LoadActor("./../ScreenEvaluation common/Shared/TitleAndBanner.lua")
af[#af+1] = LoadActor("./../ScreenEvaluation common/Shared/SongFeatures.lua")

af[#af+1] = LoadActor("./PlayerList.lua")
af[#af+1] = LoadActor("./ReadyBanner.lua")

return af