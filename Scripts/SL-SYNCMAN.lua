SYNCMAN = {
    lobby = nil,
    rooms = {},
    readyState = {
        P1 = nil,
        P2 = nil
    },
    ws = nil,
    connected = false,
    inGame = false,
    startAt = 0,
	connected = false,
	errorMsg = nil,
}

local knownDisconnectScreens = {
	["ScreenTitleMenu"] = true,
	["ScreenGameOver"] = true,
	["ScreenNameEntryTraditional"] = true,
	["ScreenOptionsService"] = true,
}

local scoreScreens = {"ScreenGameplay", "ScreenEvaluationStage"}

local protocol = "wss"
local host = "online.itgeurocup.com"
-- local host = "localhost"
local port = 443

SYNCMAN.handlers = {
    lobbyState = function(data)
        SYNCMAN.lobby = data
		MESSAGEMAN:Broadcast("OnlineLobbyState", data or {})
    end,
    temporaryLobbiesUpdate = function(data)
        SYNCMAN.rooms = data.lobbies
        MESSAGEMAN:Broadcast("SyncStartRoomsChanged")
    end,
    lobbySearched = function(data)
        SYNCMAN.rooms = data.lobbies
        MESSAGEMAN:Broadcast("SyncStartRoomsChanged", {
			lobbies = data and data.lobbies or {}
		})
    end,
    selectSong = function(data)
        MESSAGEMAN:Broadcast("SongSelected", data)
    end,
    startSong = function(data)
        if data.phase == "ScreenGameplayWaiting" then -- Load song
            MESSAGEMAN:Broadcast("SyncStartStart")
        end
        if data.phase == "ScreenGameplay" then -- Start song
            MESSAGEMAN:Broadcast("SyncStartSong")
        end
    end,
    time = function(data)
        SYNCMAN:Send("time", {time=GetTimeSinceStart()})
    end,
    responseStatus = function(data)
		local event = (data['event']:gsub("^%l", string.upper))
        MESSAGEMAN:Broadcast("SyncStartResponse" .. data['event'], data)
    end,
}

function SYNCMAN:Connect()
    if not SYNCMAN.ws then

        local httpWhitelist = PREFSMAN:GetPreference("HttpAllowHosts")
        if not string.find(httpWhitelist, host) then
            SM("You must add " .. host .. " to your Preferences.ini -> HttpAllowHosts")
        end

        SYNCMAN.ws = NETWORK:WebSocket{
            url=protocol .. "://" .. host .. ":" .. port,
            handshakeTimeout=3,
            pingInterval=5,
            automaticReconnect=true,
            onMessage=function(msg)
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
                    SYNCMAN.connected = true
					SYNCMAN:Reset(true)
                    MESSAGEMAN:Broadcast("SyncStartConnected")
                elseif msgType == "Close" then
                    SYNCMAN.connected = false
					SYNCMAN:Reset(true)
                    MESSAGEMAN:Broadcast("SyncStartDisconnected")
                    Trace("WebSocket closed: " .. msg.reason)
				elseif msgType == "Error" then
					SYNCMAN.errorMsg = msg.reason
                else
                    Trace("ITGO Unknown message type: " .. JsonEncode(msg))
                end
            end,
        }
    end

    return SYNCMAN.ws
end

function SYNCMAN:Disconnect()
	if not SYNCMAN.ws then
		return
	end

	SYNCMAN.ws:Close()
	SYNCMAN.ws = nil
	SYNCMAN.connected = false
	SYNCMAN:Reset()
end

function SYNCMAN:SelectSong()
	local song = GAMESTATE:GetCurrentSong()
	-- GetSongDir returns /Songs/<Group>/<Song>/
	-- We convert it to: <Group>/<Song>
	local songPath = song:GetSongDir()
	songPath = songPath:sub(8, #songPath-1)

	SYNCMAN:Send("selectSong", {
		songInfo = {
			songPath=songPath,
			title=song:GetDisplayFullTitle(),
			artist=song:GetDisplayArtist(),
			songLength=song:MusicLengthSeconds()
		}
	})
end

function SYNCMAN:PlayerOptionsOnline()
    if not SYNCMAN:IsReady() then
        return false
    end

    if ThemePrefs.Get("EnableITGOnline") ~= "Yes" then
        return false
    end

    if SYNCMAN.lobby ~= nil and SYNCMAN.lobby.temporary == false then
        return false
    end

    return true
end

function SYNCMAN:IsLinked()
    if not SYNCMAN:IsReady() then
        return false
    end

    if not SYNCMAN.lobby then
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

    if SYNCMAN.connected == false then
        return false
    end

    return true
end

function SYNCMAN:GetCurrentPlayers()
    if SYNCMAN.lobby == nil then
        return {}
    end

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

    local ws = SYNCMAN:Connect()

    local encoded = JsonEncode({
        event = event,
        data = data
    })
    
    ws:Send(encoded, false)

    return true
end

function SYNCMAN:JoinTemporary(song)
    local players = {}

    for player in ivalues( PlayerNumber ) do
        if GAMESTATE:IsHumanPlayer(player) then
            local steps = GAMESTATE:GetCurrentSteps(player)
            players[#players+1] = {
                profileName = SYNCMAN:PlayerName(player),
                diffLevel = steps:GetMeter(),
                diffType = steps:GetDifficulty()
            }
        end
    end

    SYNCMAN:Send(
        "joinTemporaryLobby",
        {songInfo = SYNCMAN:SongInfo(song), machine=SYNCMAN:GetMachineState()}
    )
end

function SYNCMAN:Reset(full)
    if SYNCMAN.lobby ~= nil and SYNCMAN.lobby.temporary == true then
        SYNCMAN:Send("leaveLobby")
        SYNCMAN.lobby = nil
    end

    SYNCMAN.scores = {}
    SYNCMAN.inGame = false
    SYNCMAN.startAt = 0
    SYNCMAN.readyState = {
        P1 = nil,
        P2 = nil
    }
	SYNCMAN.errorMsg = nil

	if full then
		SYNCMAN.lobby = nil
		MESSAGEMAN:Broadcast("OnlineLobbyState", data or {})
	end

	SYNCMAN:SendUpdate()
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
				SYNCMAN:Send("startSong", {phase = "ScreenGameplayWaiting"})
            end

            if list[2] == true then
                SYNCMAN:SendUpdate()
                SYNCMAN:Send("startSong", {phase = "ScreenGameplayWaiting"})
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
        {machine = SYNCMAN:GetMachineState()}
    )
end

function SYNCMAN:GetPlayerState(player)
	if SCREENMAN == nil or SCREENMAN:GetTopScreen() == nil then
		return {}
	end

    local screenName = SCREENMAN:GetTopScreen():GetName()

	local name = SYNCMAN:PlayerName(player)		
                
	local judgments = nil
	local score = nil
	local exScore = nil
	local health = nil
	local diffLevel = nil
	local diffType = nil
	local failed = nil
	local songProgression = nil

	if screenName == "ScreenGameplay" or screenName == "ScreenEvaluationStage" or screenName == "ScreenGameplayWaiting" then
		local steps = GAMESTATE:GetCurrentSteps(player)
		diffLevel = steps:GetMeter()
		diffType = steps:GetDifficulty()
	end
	
	if screenName == "ScreenGameplay" or screenName == "ScreenEvaluationStage" then
		if SYNCMAN.inGame == true then
			judgments = SYNCMAN:GetJudgmentCounts(player)
		end
		local ss = STATSMAN:GetCurStageStats()
		local pss = ss:GetPlayerStageStats(player)
		local dance_points = pss:GetPercentDancePoints()
		local percent = FormatPercentScore( dance_points ):gsub("%%", "")
		score = tonumber(percent)
		exScore = CalculateExScore(player)
		failed = pss:GetFailed()
		local currentTime = 0

		if screenName == "ScreenGameplay" and SYNCMAN.inGame then
			health = pss:GetCurrentLife() * 100
			currentTime = ss:GetGameplaySeconds()
		end

		songProgression = {
			currentTime = currentTime,
			totalTime = GAMESTATE:GetCurrentSong():GetLastSecond()
		}
	end

	local pn = ToEnumShortString(player)
	
	return {
		playerId = pn,
		profileName = name,
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

function SYNCMAN:GetMachineState()
	if SCREENMAN == nil or SCREENMAN:GetTopScreen() == nil then
		return {}
	end

	local players = {}
    local screenName = SCREENMAN:GetTopScreen():GetName()	
	local machineName = PREFSMAN:GetPreference("MachineName")


	for player in ivalues(GAMESTATE:GetEnabledPlayers()) do
		players[#players+1] = SYNCMAN:GetPlayerState(player)
	end

	return {
		screenName=screenName,
		machineName=machineName,
		players = players
	}
end

function SYNCMAN:CreateOnlineHandler()
	if not SYNCMAN:IsEnabled() or not SYNCMAN.connected then
		return nil
	end

	Def.ActorFrame{
		Name="OnlineWebsocketHandler",
		InitCommand=function(self)
		-- ?
		end,
		ScreenChangedMessageCommand=function(self)
			if SYNCMAN.connected == true then
				local screen = SCREENMAN:GetTopScreen()
				local screenName = screen and screen:GetName() or "NoScreen"

				if knownDisconnectScreens[screenName] then
					SYNCMAN:Disconnect()
				end
			end
		end
	}
end