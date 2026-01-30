local candidatesScroller = setmetatable({}, sick_wheel_mt)
local candidateItemMT = {
	__index = {
		create_actors = function(self, name)
			self.name=name

			local af = Def.ActorFrame{
				Name=name,

				InitCommand=function(subself)
					self.container = subself
					subself:MaskDest()
					subself:diffusealpha(0)
				end,
			}

			af[#af+1] = Def.BitmapText{
				Font="Common Bold",
				InitCommand=function(subself)
					self.letter = subself
          subself:horizalign(center)
					-- subself:zoom(0.5)
				end,
			}

			return af
		end,

		transform = function(self, item_index, num_items, has_focus)
      self.container:diffusealpha(1)
      self.container:x(60*item_index)

      local is_emoji = self.letter:GetText() == "✖" or self.letter:GetText() == "✔"
      local zoom = 1
      if has_focus then
        if is_emoji then
          zoom = 1.7
        else
          zoom = 1.1
        end
      end

      self.container:zoom(zoom)
      if not is_emoji then
        self.letter:diffuse(has_focus and GetHexColor(SL.Global.ActiveColorIndex) or Color.White)
      end
		end,

		set = function(self, info)
			if info == nil then self.letter:settext("") return end

      if info.letter ==  "✖" then
        self.letter:zoom(2):y(-22)
      elseif info.letter == "✔" then
        self.letter:zoom(2):y(-22)
      else
        self.letter:zoom(1):y(0)
      end
      self.letter:settext(info.letter)
      DiffuseEmojis(self.letter)
		end
	}
}

local keys = {
  "✖", "✔", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L",
  "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
}
local candidates = {}
for i=1,#keys do
  table.insert(candidates, {
    idx=i,
    letter=keys[i]
  })
end

local af = Def.ActorFrame{
  InitCommand=function(self)
    self:x(-SCREEN_CENTER_X):y(-SCREEN_CENTER_Y)
    candidatesScroller.focus_pos = 4
		candidatesScroller:set_info_set(candidates, 1)
  end

}

af[#af+1] = Def.Quad{
  InitCommand=function(self)
    self:diffuse(Color.Black):diffusealpha(0.8):FullScreen()
  end
}

af[#af+1] = candidatesScroller:create_actors("Candidates", 7, candidateItemMT, SCREEN_CENTER_X/2, SCREEN_CENTER_Y)

return af