local Class = require "extra_libs.hump.class"
local SUPPLY = require "classes.supply"

local Food = Class{
  __includes = {SUPPLY},
  init = function(self, x, y, r, division)
    SUPPLY.init(self, x, y, r, division)

    self.tp = "food"
  end
}

function Food:draw()
  love.graphics.setColor(0, 1, 0)
  love.graphics.circle("fill", self.pos.x, self.pos.y, self.r)
end

return Food
