SYNCMAN = {
    lobby = {},
    rooms = {},
    readyState = {
        P1 = false,
        P2 = false
    },
    ws = nil,
    wsReady = false,
    inGame = false,
    startAt = 0,
    startPhase = 0
}

SYNCMAN.handlers = {
    lobbyState = function(data)
        SYNCMAN.lobby = data
        MESSAGEMAN:Broadcast("SyncStartLobbyUpdate")
        -- SM(data)
    end,
    temporaryLobbiesUpdate = function(data)
        SYNCMAN.rooms = data.lobbies
        MESSAGEMAN:Broadcast("SyncStartRoomsChanged")
    end,
    startSong = function(data)
        if data.phase == 2 then
            SYNCMAN.startPhase = 2
            MESSAGEMAN:Broadcast("SyncStartStart")
        end
        if data.phase == 4 then
            SYNCMAN.startPhase = 4
            MESSAGEMAN:Broadcast("SyncStartSong")
        end
        -- SYNCMAN.startAt = data.start_at or 0
    end,
    time = function(data)
        SYNCMAN:Send("time", {time=GetTimeSinceStart()})
    end,
    responseStatus = function(data)
        MESSAGEMAN:Broadcast("SyncStartResponse" .. data['event'], data)
    end,
}

function SYNCMAN:WS()
    if not SYNCMAN.ws then

        local itgOnlineServer = "online.itgeurocup.com"
        local httpWhitelist = PREFSMAN:GetPreference("HttpAllowHosts")
        if not string.find(httpWhitelist, itgOnlineServer) then
            SM("You must add " .. itgOnlineServer .. " to your Preferences.ini -> HttpAllowHosts")
        end

        SYNCMAN.ws = NETWORK:WebSocket{
            -- url="ws://192.168.2.33:8765",
            -- url="ws://itgonline.electromuis.nl",
            -- url="ws://localhost:3000",
            url="ws://" .. itgOnlineServer,
            handshakeTimeout=3,
            pingInterval=5,
            automaticReconnect=true,
            sendThreaded=true,
            onMessage=function(msg)
                -- SM(msg)
                local msgType = ToEnumShortString(msg.type)

                if msgType == "Message" then
                    local decoded = JsonDecode(msg.data)
                    if not decoded then
                        Trace("ITGO: Could not decode: " .. msg.data)
                        return
                    end

                    local handler = SYNCMAN.handlers[decoded.event]
                    if not handler then
                        Trace("ITGO: No handler for: " .. decoded.event)
                        return
                    end
                    handler(decoded.data)
                elseif msgType == "Open" then
                    SYNCMAN.wsReady = true
                    MESSAGEMAN:Broadcast("SyncStartConnected")
                elseif msgType == "Close" then
                    SYNCMAN.wsReady = false
                    MESSAGEMAN:Broadcast("SyncStartDisconnected")
                    Trace("WebSocket closed: " .. msg.reason)
                else
                    Trace("ITGO Unknown message type: " .. JsonEncode(msg))
                end
            end,
        }
    end

    return SYNCMAN.ws
end

function SYNCMAN:IsInGame()
    if not SYNCMAN:IsReady() then
        return false
    end

    if not SYNCMAN.inGame then
        return false
    end
    
    return true
end

function SYNCMAN:IsEnabled()
    if ThemePrefs.Get("EnableITGOnline") == "No" then
        return false
    end

    return true
end

function SYNCMAN:IsReady()
    if not SYNCMAN:IsEnabled() then
        return false
    end

    if not SYNCMAN.ws then
        return false
    end

    if SYNCMAN.wsReady == false then
        return false
    end

    return true
end

function SYNCMAN:GetCurrentPlayers()
    return SYNCMAN.lobby.players
end

function SYNCMAN:SongInfoMatch(songInfo1, songInfo2)
    return songInfo1.songPath == songInfo2.songPath
end

function SYNCMAN:SongInfo(song)
    if song == nil then
        song = GAMESTATE:GetCurrentSong()
    end
    -- GetSongDir returns /Songs/<Group>/<Song>/
    -- We convert it to: <Group>/<Song>
    local songPath = song:GetSongDir()
    songPath = songPath:sub(8, #songPath-1)

    return {
        songPath=songPath,
        title=song:GetDisplayFullTitle(),
        artist=song:GetDisplayArtist(),
        songLength=song:MusicLengthSeconds()
    }   
end

function SYNCMAN:RoomActive(song)
    for s in ivalues(SYNCMAN.rooms) do
        if s.joinable == true then
            if SYNCMAN:SongInfoMatch(s.songInfo, SYNCMAN:SongInfo(song)) then
                return true
            end
        end
    end
    
    return false
end

function SYNCMAN:Send(event, data)
    if not SYNCMAN:IsReady() then
        return false
    end

    local ws = SYNCMAN:WS()
    -- if not ws then
    --     return
    -- end

    local encoded = JsonEncode({
        event = event,
        data = data
    })
    -- SM("SYNCMAN:Send: " .. encoded)
    -- local result = ws:Send(encoded, false)
    ws:Send(encoded, false)
    -- if not result then
    --     Trace("SYNCMAN:Send failed")
    --     return false
    -- end

    return true
end

function SYNCMAN:JoinTemporary(song)
    local players = {}

    for player in ivalues( PlayerNumber ) do
        if GAMESTATE:IsHumanPlayer(player) then
            local steps = GAMESTATE:GetCurrentSteps(player)
            -- playerNames[#playerNames+1] = SYNCMAN:PlayerName(player)
            players[#players+1] = {
                name = SYNCMAN:PlayerName(player),
                diffLevel = steps:GetMeter(),
                diffType = steps:GetDifficulty()
            }
        end
    end

    SYNCMAN:Send(
        "joinTemporaryLobby",
        {songInfo = SYNCMAN:SongInfo(song)}
    )

    -- if res then
        SYNCMAN.inGame = true
    -- end
end

function SYNCMAN:Reset()
    SYNCMAN.scores = {}
    SYNCMAN.lobby = {}
    SYNCMAN.inGame = false
    SYNCMAN.startAt = 0
    SYNCMAN.readyState = {
        P1 = false,
        P2 = false
    }
    SYNCMAN.startPhase = 0
    SYNCMAN:Send("leaveLobby")
end

function SYNCMAN:GetSyncOptionRow()
    return {
		Name = "SyncOption",
		Choices = {"Ready", "Play", "Back"},
		LayoutType = "ShowAllInRow",
		SelectType = "SelectOne",
		OneChoiceForAllPlayers = false,
		ExportOnChange = false,
		LoadSelections = function(self, list, pn)
			list[1] = true  -- Default to "Play"
            return list
		end,
		SaveSelections = function(self, list, p)
            local top_screen = SCREENMAN:GetTopScreen()

            if list[1] == true then
                local pn = ToEnumShortString(p)
                SYNCMAN.readyState[pn] = true
                
                SYNCMAN:SendUpdate()
                MESSAGEMAN:Broadcast("SyncStartLobbyUpdate")
            end

            if list[2] == true then
                SYNCMAN.startPhase = 1
                SYNCMAN:SendUpdate()
                SYNCMAN:Send("startSong", {phase = 1})
            end

            if list[3] == true then
                local prev_screen_name = top_screen:GetPrevScreenName()
                top_screen:SetNextScreenName(prev_screen_name):StartTransitioningScreen("SM_GoToNextScreen")
            end
		end,
	}
end

function SYNCMAN:PlayerName(player)
    local pn = ToEnumShortString(player)
    local gsName = SL[pn].GrooveStatsUsername
    if string.len(gsName) > 0 then
        return gsName
    end

    if (PROFILEMAN:IsPersistentProfile(player) and
				PROFILEMAN:GetProfile(player)) then
        return PROFILEMAN:GetProfile(player):GetDisplayName()
    end

    return "NoName"
end

function SYNCMAN:GetJudgmentCounts(player)
	local counts = GetExJudgmentCounts(player)
	local translation = {
		["W0"] = "fantasticPlus",
		["W1"] = "fantastics",
		["W2"] = "excellents",
		["W3"] = "greats",
		["W4"] = "decents",
		["W5"] = "wayOffs",
		["Miss"] = "misses",
		["totalSteps"] = "totalSteps",
		["Mines"] = "minesHit",
		["totalMines"] = "totalMines",
		["Holds"] = "holdsHeld",
		["totalHolds"] = "totalHolds",
		["Rolls"] = "rollsHeld",
		["totalRolls"] = "totalRolls"
	}

	local judgmentCounts = {}

	for key, value in pairs(counts) do
		if translation[key] ~= nil then
			judgmentCounts[translation[key]] = value
		end
	end

	return judgmentCounts
end

function SYNCMAN:SendUpdate()
    SYNCMAN:Send(
        "updateMachine",
        SYNCMAN:GetMachineState()
    )
end

function SYNCMAN:GetMachineState()
	local players = {}
    local screenName = SCREENMAN:GetTopScreen():GetName()

	for player in ivalues(GAMESTATE:GetEnabledPlayers()) do
		local name = SYNCMAN:PlayerName(player)		
                
        local judgments = nil
		local score = nil
		local exScore = nil
        local health = nil
        local diffLevel = nil
        local diffType = nil
        local failed = nil

        if screenName == "ScreenGameplay" or screenName == "ScreenEvaluationStage" or screenName == "ScreenGameplayWaiting" then
            local steps = GAMESTATE:GetCurrentSteps(player)
            diffLevel = steps:GetMeter()
            diffType = steps:GetDifficulty()
        end
        
		if screenName == "ScreenGameplay" or screenName == "ScreenEvaluationStage" then
			if SYNCMAN.startPhase == 4 then
                judgments = SYNCMAN:GetJudgmentCounts(player)
            end
            local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
			local dance_points = pss:GetPercentDancePoints()
			local percent = FormatPercentScore( dance_points ):gsub("%%", "")
			score = tonumber(percent)
			exScore = CalculateExScore(player)
            failed = pss:GetFailed()

            if screenName == "ScreenGameplay" then
                health = pss:GetCurrentLife() * 100
            end
		end

		local pn = ToEnumShortString(player)
		players[#players+1] = {
			playerId = pn,
			name = name,
			ready=SYNCMAN.readyState[pn],

            diffLevel = diffLevel,
            diffType = diffType,

			judgments = judgments,
			score = score,
			exScore = exScore,
            health = health
			-- TODO(teejusb): Add song progression.
		}
	end

	return {
		machine = {
            screenName=screenName,
            startPhase = SYNCMAN.startPhase,
			players = players
		}
	}
end