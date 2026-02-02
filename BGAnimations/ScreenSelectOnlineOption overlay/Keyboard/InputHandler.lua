-- a reference to the primary ActorFrame
local args = ...
local t = args[1]
local AlphabetWheel = args[2]

-- the highscore name character limit
local CharacterLimit = 12

-- Define the input handler
local InputHandler = function(event)

	if not event.PlayerNumber or not event.button or not AlphabetWheel.isOpen then
		return false
	end

	-- a local function to delete a character from a player's highscore name
	local function RemoveLastCharacter()
		if AlphabetWheel.text:len() > 0 then
			-- remove the last character
			AlphabetWheel.text = AlphabetWheel.text:sub(1, -2)
			-- update the display
			t:GetChild("TextField"):queuecommand("Set")
			-- play the "delete" sound
			t:GetChild("delete"):play()
		else
		 	-- there's nothing to delete, so play the "invalid" sound
			-- t:GetChild("invalid"):play()
			MESSAGEMAN:Broadcast("CloseKeyboard")
		end
	end


	if event.type ~= "InputEventType_Release" then
		local pn = ToEnumShortString(event.PlayerNumber)

		if event.GameButton == "MenuRight" then
			-- scroll this player's AlphabetWheel right by 1
			AlphabetWheel:scroll_by_amount(1)
			t:GetChild("move"):play()

		elseif event.GameButton == "MenuLeft" then
			-- scroll this player's AlphabetWheel left by 1
			AlphabetWheel:scroll_by_amount(-1)
			t:GetChild("move"):play()

		elseif event.GameButton == "Start" then

			-- This gets us the value selected out of the PossibleCharacters table
			local SelectedCharacter = AlphabetWheel:get_info_at_focus_pos()

			if SelectedCharacter == "&OK;" then
				
				
				-- SL[pn].HighScores.EnteringName = false
				-- hide this player's cursor
				-- t:GetChild("PlayerNameAndDecorations_"..pn):GetChild("Cursor"):queuecommand("Hide")
				-- hide this player's AlphabetWheel
				-- t:GetChild("AlphabetWheel_"..pn):queuecommand("Hide")
				-- play the "enter" sound
				t:GetChild("enter"):play()

			elseif SelectedCharacter == "&BACK;" then
				RemoveLastCharacter(pn)

			else -- it must be a normal character
				if AlphabetWheel.text:len() < CharacterLimit then
					-- append the new character
					AlphabetWheel.text = AlphabetWheel.text .. SelectedCharacter
					-- update the display
					t:GetChild("TextField"):queuecommand("Set")
					-- play the "enter" sound
					t:GetChild("enter"):playforplayer(event.PlayerNumber)
				else
					t:GetChild("invalid"):playforplayer(event.PlayerNumber)
				end

				if AlphabetWheel.text:len() >= CharacterLimit then
					AlphabetWheel:scroll_to_pos(2)
				end

			end

			-- check if we're ready to save scores and proceed to the next screen
			t:queuecommand("AttemptToFinish")

		elseif event.GameButton == "Select" then
			RemoveLastCharacter()
		end
	end

	return true
end

return InputHandler
