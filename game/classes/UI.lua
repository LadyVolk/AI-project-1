local Class = require "extra_libs.hump.class"
local COLOR = require "classes.color.color"
local ELEMENT = require "classes.primitives.element"

local UI = Class{
  __includes = {ELEMENT},
  init = function(self, _player)
    ELEMENT.init(self)
    self.player = _player
    self.tp = "UI"
    self.bar_w = 200
    self.bar_y = 50
    self.font = love.graphics.newFont("assets/fonts/PottaOne-Regular.ttf", 20)
    self.time_font = love.graphics.newFont("assets/fonts/PottaOne-Regular.ttf", 40)
  end

}

function UI:draw()
  love.graphics.setLineWidth(5)
  love.graphics.setFont(self.font)

  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle("line", 50, 900, self.bar_w, self.bar_y)
  love.graphics.setColor(0, 1, 0)
  love.graphics.rectangle("fill", 50, 900,
                         (self.player.hunger/self.player.max_value)*self.bar_w, self.bar_y)

  love.graphics.print("HUNGER", 50, 950)

  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle("line", 350, 900, self.bar_w, self.bar_y)
  love.graphics.setColor(0, 0.5, 1)
  love.graphics.rectangle("fill", 350, 900,
                         (self.player.thirst/self.player.max_value)*self.bar_w, self.bar_y)
  love.graphics.print("thirst", 350, 950)

  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle("line", 650, 900, self.bar_w, self.bar_y)
  love.graphics.setColor(1, 0, 0)
  love.graphics.rectangle("fill", 650, 900,
                         (self.player.temperature/self.player.max_value)*self.bar_w, self.bar_y)
  love.graphics.print("TEMPERATURE", 650, 950)

  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle("line", 1050, 900, self.bar_w, self.bar_y)
  love.graphics.setColor(0.8, 0.8, 0.8)
  love.graphics.rectangle("fill", 1050, 900,
                         (self.player.health/self.player.max_value)*self.bar_w, self.bar_y)
  love.graphics.print("HEALTH", 1050, 950)

  local time = string.format("%.1f", self.player.time_alive)
  love.graphics.setFont(self.time_font)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("TIME ALIVE: "..time, 50, 50)

  love.graphics.print("Control: "..self.player.control, 500, 50)

  if self.player.control ~= "player" then
    love.graphics.print("State: "..self.player.current_state, 900, 50)
  end
end

return UI
