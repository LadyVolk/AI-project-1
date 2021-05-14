local Class = require "extra_libs.hump.class"
local COLOR = require "classes.color.color"
local ELEMENT = require "classes.primitives.element"

local TemperatureBackground = Class{
  __includes = {ELEMENT},
  init = function(self, _division, _w, _h)
    ELEMENT.init(self)
    self.division = _division
    self.tp = "temperature_background"
    self.w = _w
    self.h = _h
    self.hot = COLOR.new(1, 0, 0, 0.2)
    self.cold = COLOR.new(0, 0, 1, 0.2)
  end
}

function TemperatureBackground:draw()
  COLOR.set(self.cold)
  love.graphics.rectangle("fill", 0, 0, self.w, self.division)

  COLOR.set(self.hot)
  love.graphics.rectangle("fill", 0, self.division, self.w, self.h-self.division)

end

return TemperatureBackground
