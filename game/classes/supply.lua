local Class = require "extra_libs.hump.class"
local COLOR = require "classes.color.color"
local CIRC = require "classes.primitives.circ"
local Util = require "util"

local Supply = Class{
  __includes = {CIRC},
  init = function(self, x, y, r, division)
    CIRC.init(self, x, y, r, COLOR.new(1, 0, 0), "fill")

    self.tp = "supply"
    self.quantity = 100
    self.consume_speed = 30
    if y <= division then
      self.temp = "cold"
    else
      self.temp = "hot"
    end
  end
}

function Supply:update(dt)

end

function Supply:collision(player)
  return math.sqrt(math.pow(player.pos.x - self.pos.x, 2) + math.pow(player.pos.y - self.pos.y, 2)) <
         player.r + self.r
end

function Supply:consume(dt)
  self.quantity = self.quantity - self.consume_speed * dt
  if self.quantity <= 0 then
    self:kill()
  end
end

return Supply
