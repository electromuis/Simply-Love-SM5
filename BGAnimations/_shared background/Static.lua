-- --------------------------------------------------------
-- static background image

local file = ...

local style = ThemePrefs.Get("VisualStyle")

local function Brighten(color, intensity)
	color[1] = math.min(1, color[1] * intensity)
	color[2] = math.min(1, color[2] * intensity)
	color[3] = math.min(1, color[3] * intensity)
	return color
end

local af = Def.ActorFrame {
	InitCommand=function(self)
		self:diffusealpha(0)
		self:visible(style == "SRPG9" or style == "Eurocup")
	end,
	OnCommand=function(self)
		self:accelerate(0.8):diffusealpha(1)
	end,
	VisualStyleSelectedMessageCommand=function(self)
		local style = ThemePrefs.Get("VisualStyle")
		if style == "SRPG9" or style == "Eurocup" then
			self:visible(true)
		else
			self:visible(false)
		end
	end,
	Def.Sprite {
		Name="Background",
		InitCommand= function(self)
			if style ~= "SRPG9" and style ~= "Eurocup" then self:Load(nil) return end

			local video_allowed = ThemePrefs.Get("AllowThemeVideos")
			if video_allowed then
				self:Load(THEME:GetPathG("", "_VisualStyles/" .. style .. "/BackgroundVideo.mp4"))
			else
				self:Load(THEME:GetPathG("", "_VisualStyles/" .. style .. "/SharedBackground.png"))
			end

			if style == "SRPG9" then
				self:xy(_screen.cx, _screen.cy)
					:zoomto(_screen.h * 16 / 9, _screen.h)
					:diffuse(Brighten(GetCurrentColor(true), 3))
				self:visible(true)
			end

			if style == "Eurocup" then
				self:xy(_screen.cx, _screen.cy)
					:zoomto(_screen.h * 16 / 9, _screen.h)
				self:visible(true)
			end
		end,
		ColorSelectedMessageCommand=function(self)
			self:diffuse(Brighten(GetCurrentColor(true), 3))
		end,
		VisualStyleSelectedMessageCommand=function(self)
			if style ~= "SRPG9" and style ~= "Eurocup" then self:Load(nil) return end

			local video_allowed = ThemePrefs.Get("AllowThemeVideos")
			if video_allowed then
				self:Load(THEME:GetPathG("", "_VisualStyles/" .. style .. "/BackgroundVideo.mp4"))
			else
				self:Load(THEME:GetPathG("", "_VisualStyles/" .. style .. "/SharedBackground.png"))
			end

			if style == "SRPG9" then
				self:xy(_screen.cx, _screen.cy)
					:zoomto(_screen.h * 16 / 9, _screen.h)
					:diffuse(Brighten(GetCurrentColor(true), 3))
			end

			if style == "Eurocup" then
				self:xy(_screen.cx, _screen.cy)
					:zoomto(_screen.h * 16 / 9, _screen.h)
			end
		end,
		AllowThemeVideoChangedMessageCommand=function(self)
			if style ~= "SRPG9" and style ~= "Eurocup" then self:Load(nil) return end

			local video_allowed = ThemePrefs.Get("AllowThemeVideos")
			if video_allowed then
				self:Load(THEME:GetPathG("", "_VisualStyles/" .. style .. "/BackgroundVideo.mp4"))
			else
				self:Load(THEME:GetPathG("", "_VisualStyles/" .. style .. "/SharedBackground.png"))
			end
			
			if style == "SRPG9" then
				self:xy(_screen.cx, _screen.cy)
					:zoomto(_screen.h * 16 / 9, _screen.h)
					:diffuse(Brighten(GetCurrentColor(true), 3))
			end

			if style == "Eurocup" then
				self:xy(_screen.cx, _screen.cy)
					:zoomto(_screen.h * 16 / 9, _screen.h)
			end
		end,
	},
	Def.Quad{
		InitCommand=function(self)
			self:FullScreen()
			 :diffuse(Color.Black)
			 :diffusealpha(0.5)
		end,
	}
}

return af
