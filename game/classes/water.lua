local Class = require "extra_libs.hump.class"
local SUPPLY = require "classes.supply"

local Water = Class{
  __includes = {SUPPLY},
  init = function(self, x, y, r, division)
    SUPPLY.init(self, x, y, r, division)

    self.tp = "water"
  end
}

function Water:draw()
  love.graphics.setColor(0, 0.5, 1)
  love.graphics.circle("fill", self.pos.x, self.pos.y, self.r)
end

return Water
