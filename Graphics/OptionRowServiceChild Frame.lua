local t = Def.ActorFrame{}
local title_bg_width = _screen.w*WideScale(0.18,0.15)

-- a row
t[#t+1] = Def.Quad {
	Name="RowBackgroundQuad",
	InitCommand=function(self) self:zoomto(_screen.w * WideScale(0.475,0.45), _screen.h*0.0625) end
}

-- black quad behind the title
t[#t+1] = Def.Quad {
	Name="TitleBackgroundQuad",
	OnCommand=function(self)
		self:zoomto(title_bg_width, _screen.h*0.0625)
			:x( -WideScale(94,128) )
			:diffuse(Color.Black):diffusealpha( BrighterOptionRows() and 0.75 or 0.25)
	end
}

return t