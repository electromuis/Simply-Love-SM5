SYNCMAN = {
    scores = {},
    players = {},
    rooms = {},
    ws = nil,
    wsReady = false,
    inGame = false,
    playerReady = false,
    startAt = 0
}

function SYNCMAN:WS()
    if not SYNCMAN.ws then
        SYNCMAN.ws = NETWORK:WebSocket{
            -- url="ws://192.168.2.33:8765",
            -- url="ws://itgonline.electromuis.nl",
            url="ws://localhost:3000",
            handshakeTimeout=3,
            pingInterval=5,
            automaticReconnect=true,
            sendThreaded=false,
            onMessage=function(msg)
                -- SM(msg)
                local msgType = ToEnumShortString(msg.type)

                if msgType == "Message" then
                    local decoded = JsonDecode(msg.data)
                    if decoded then
                        if decoded.event == "scores" then
                            SYNCMAN.scores = decoded.data.scores
                            MESSAGEMAN:Broadcast("SyncStartPlayerScoresChanged")
                        elseif decoded.event == "players" then
                            SYNCMAN.players = decoded.data.players
                            MESSAGEMAN:Broadcast("SyncStartPlayersChanged")
                        elseif decoded.event == "rooms" then
                            SYNCMAN.rooms = decoded.data.rooms
                            MESSAGEMAN:Broadcast("SyncStartRoomsChanged")
                        elseif decoded.event == "start" then
                            MESSAGEMAN:Broadcast("SyncStartStart")
                            SYNCMAN.startAt = decoded.data.start_at or 0
                        elseif decoded.event == "time" then
                            SYNCMAN:Send({
                                event = "time",
                                data = {
                                    time = GetTimeSinceStart()
                                }
                            })
                        else
                            Trace(JsonEncode(decoded))
                        end
                    end
                elseif msgType == "Open" then
                    SYNCMAN.wsReady = true
                    MESSAGEMAN:Broadcast("SyncStartConnected")
                elseif msgType == "Close" then
                    SYNCMAN.wsReady = false
                    MESSAGEMAN:Broadcast("SyncStartDisconnected")
                    Trace("WebSocket closed: " .. msg.reason)
                else
                    Trace(JsonEncode(msg))
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

function SYNCMAN:GetCurrentPlayerScores()
    return SYNCMAN["scores"]
end

function SYNCMAN:GetCurrentPlayers()
    return SYNCMAN["players"]
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
        if s == SYNCMAN:SongID(song) then
            return true
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
        {songInfo = SongInfo(song)}
    )

    -- if res then
        SYNCMAN.inGame = true
    -- end
end

function SYNCMAN:Reset()
    SYNCMAN.scores = {}
    SYNCMAN.players = {}
    SYNCMAN.inGame = false
    SYNCMAN.playerReady = false
    SYNCMAN.startAt = 0
    SYNCMAN:Send("leaveLobby")
end

function SYNCMAN:GetSyncOptionRow()
    return {
		Name = "SyncOption",
		Choices = {"Ready", "Play", "Back"},
		LayoutType = "ShowAllInRow",
		SelectType = "SelectOne",
		OneChoiceForAllPlayers = true,
		ExportOnChange = false,
		LoadSelections = function(self, list, pn)
			list[1] = true  -- Default to "Play"
            return list
		end,
		SaveSelections = function(self, list, pn)
            local top_screen = SCREENMAN:GetTopScreen()

            if list[1] == true then
                -- SYNCMAN.playerReady = not SYNCMAN.playerReady
                SYNCMAN:Send(
                    "readyUp",
                    {playerId=""}
                )
            end

            if list[2] == true then
                SYNCMAN:Send({
                    action = "start"
                })
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

function SYNCMAN:GetJudgmentCounts()
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
    SYNCMAN:Send({
        action = "updateMachine",
        state = SYNCMAN:GetMachineState()
    })
end

function SYNCMAN:GetMachineState()
	local players = {}
	for player in ivalues(GAMESTATE:GetEnabledPlayers()) do
		local profileName = SYNCMAN:PlayerName(player)		
        local judgments = SYNCMAN:GetJudgmentCounts(player)
        local dance_points = STATSMAN:GetCurStageStats():GetPlayerStageStats(player):GetPercentDancePoints()
        local percent = FormatPercentScore( dance_points ):gsub("%%", "")
        local score = tonumber(percent)
        local exScore = CalculateExScore(player)

		local pn = ToEnumShortString(player)
		players[pn] = {
			playerId = pn,
			profileName = profileName,
			screenName=screenName,
			ready=readyState[pn],

			judgments = judgments,
			score = score,
			exScore = exScore,
			-- TODO(teejusb): Add song progression.
		}
	end

	-- If "P1"/"P2" is missing from players, then the player isn't enabled and the corresponding
	-- player1/player2 key will be nil.
	return {
		machine = {
			player1=players["P1"],
			player2=players["P2"]
		}
	}
end