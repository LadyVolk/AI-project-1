local Class = require "extra_libs.hump.class"
local COLOR = require "classes.color.color"
local CIRC = require "classes.primitives.circ"
local POS = require "classes.primitives.pos"
local Util = require "util"
local Graph = require "classes.graph"

local normalizeVector
local checkDistance

local Survivor = Class{
  __includes = {CIRC},
  init = function(self, x, y, temperature_dif)
    CIRC.init(self, x, y, 20, COLOR.new(1, 1, 1), "fill")

    self.tp = "survivor"
    self.speed = 500
    self.mov_vec = POS(0, 0)
    self.max_value = 100
    self.hunger = 0
    self.thirst = 0
    self.temperature = self.max_value/2
    self.hunger_increase = 7
    self.thirst_increase = 9
    self.temperature_change = 6
    self.temperature_difference = temperature_dif
    self.consume_speed = 20
    self.drinking = false
    self.eating = false
    self.health = self.max_value
    self.time_alive = 0
    self.damage_threshold = 60
    self.temperature_margin = 30
    self.damage_mult = 10
    self.control = "finite"
    self.finite_state_graph = Graph()
    self.fuzzy_state_graph = Graph()
    self.current_state = "idle"
    self.fuzzy_sets = {}
    self.desired_temp = "cold"

    self:setupFiniteStateGraph()
    self:setupFuzzyStateGraph()
    self:setupFuzzySets()
  end
}
---------setups
function Survivor:setupFiniteStateGraph()
  local g = self.finite_state_graph
  g:add_node("idle")
  g:add_node("hungry")
  g:add_node("thirsty")
  g:add_node("hot_cold")

  g:add_connection("idle", "hungry",
    function(args)
      return args.player.hunger > args.player.damage_threshold/2
    end
  )

  g:add_connection("idle", "thirsty",
    function(args)
      return args.player.thirst > args.player.damage_threshold/2
    end
  )

  g:add_connection("idle", "hot_cold",
    function(args)
      local margin = 10
      return args.player.temperature < args.player.temperature_margin + margin or
             args.player.temperature > args.player.max_value - (args.player.temperature_margin + margin)
    end
  )

  g:add_connection("hungry", "idle",
    function(args)
      return args.player.hunger <= 5
    end
  )

  g:add_connection("thirsty", "idle",
    function(args)
      return args.player.thirst <= 5
    end
  )

  g:add_connection("hot_cold", "idle",
    function(args)
      local margin = 10
      return args.player.temperature <= 50 + margin and
             args.player.temperature >= 50 - margin
    end
  )

end

function Survivor:setupFuzzySets()
  self.fuzzy_sets.too_hungry =
    function(hunger)
      if hunger <= 40 then
        return 0
      else
        return math.pow(hunger-40, 2)/3600.0
      end
    end
  self.fuzzy_sets.too_thirsty =
    function(thirst)
      if thirst <= 40 then
        return 0
      else
        return math.pow(thirst-40, 2)/3600.0
      end
    end
  self.fuzzy_sets.unconfortable =
    function(temperature)
      if temperature <= 30 then
        return -(math.pow(temperature, 2))/900.0 + 1
      elseif temperature >= 70 then
        return math.pow(temperature-70, 2)/900.0
      else
        return 0
      end
    end
  self.fuzzy_sets.confortable =
    function(temperature)
      if temperature >= 30 and temperature <=70 then
        return -(math.pow(temperature-50, 2))/400.0 + 1
      else
        return 0
      end
    end
  self.fuzzy_sets.not_thirsty =
    function(thirst)
      if thirst <= 40 then
        return -(math.pow(thirst, 2)/1600) + 1
      else
        return 0
      end
    end
  self.fuzzy_sets.not_hungry =
    function(hunger)
      if hunger <= 40 then
        return -(math.pow(hunger, 2)/1600) + 1
      else
        return 0
      end
    end
end

function Survivor:setupFuzzyStateGraph()
  local g = self.fuzzy_state_graph
  g:add_node("idle")
  g:add_node("hungry")
  g:add_node("thirsty")
  g:add_node("hot_cold")

  g:add_connection("idle", "hungry",
    function(args)

      return args.player:getFuzzyValue("too_hungry", args.player.hunger)
    end
  )

  g:add_connection("idle", "thirsty",
    function(args)
      return args.player:getFuzzyValue("too_thirsty", args.player.thirst)
    end
  )

  g:add_connection("idle", "hot_cold",
    function(args)
      return args.player:getFuzzyValue("unconfortable", args.player.temperature)
    end
  )

  g:add_connection("hungry", "idle",
    function(args)
      return args.player:getFuzzyValue("not_hungry", args.player.hunger)
    end
  )

  g:add_connection("thirsty", "idle",
    function(args)
      return args.player:getFuzzyValue("not_thirsty", args.player.thirst)
    end
  )

  g:add_connection("hot_cold", "idle",
    function(args)
      return args.player:getFuzzyValue("confortable", args.player.temperature)
    end
  )
  --[[
  g:add_connection("thirsty", "hungry",
    function(args)
      print("thirsty hungry")
      return args.player:getFuzzyValue("too_hungry", args.player.hunger) -
             args.player:getFuzzyValue("too_thirsty", args.player.thirst)
    end
  )

  g:add_connection("hungry", "thirsty",
    function(args)
      print("hungry thirsty")
      return args.player:getFuzzyValue("too_thirsty", args.player.thirst) -
             args.player:getFuzzyValue("too_hungry", args.player.hunger)
    end
  )

  g:add_connection("hungry", "hot_cold",
    function(args)
      print("hungry hot_cold")
      return args.player:getFuzzyValue("unconfortable", args.player.temperature) -
             args.player:getFuzzyValue("too_hungry", args.player.hunger)
    end
  )

  g:add_connection("hot_cold", "hungry",
    function(args)
      print("hot_cold hungry")
      return args.player:getFuzzyValue("too_hungry", args.player.hunger) -
             args.player:getFuzzyValue("unconfortable", args.player.temperature)
    end
  )

  g:add_connection("hot_cold", "thirsty",
    function(args)
      print("hot_cold thirsty")
      return args.player:getFuzzyValue("too_thirsty", args.player.thirst) -
             args.player:getFuzzyValue("unconfortable", args.player.temperature)

    end
  )

  g:add_connection("thirsty", "hot_cold",
    function(args)
    print("thirsty hot_cold")
    return args.player:getFuzzyValue("unconfortable", args.player.temperature) -
           args.player:getFuzzyValue("too_thirsty", args.player.thirst)
    end
  )
  ]]
end

------update
function Survivor:update(dt)
  self.time_alive = self.time_alive + dt

  if self.control == "finite" then
    self:updateFiniteLogic()
  elseif self.control == "fuzzy" then
    self:updateFuzzyLogic()
  end

  self.pos.x = self.pos.x + self.mov_vec.pos.x * self.speed * dt
  self.pos.y = self.pos.y + self.mov_vec.pos.y * self.speed * dt

  local supplies = Util.findSubtype("supply")
  self.drinking = false
  self.eating = false
  for supply in pairs(supplies) do
    if supply:collision(self) then
        self:resupply(supply.tp)
        supply:consume(dt)
    end
  end

  if not self.eating then
    self.hunger = math.min(self.hunger + self.hunger_increase * dt, self.max_value)
  else
    self.hunger = math.max(0, self.hunger - self.consume_speed * dt)
  end

  if not self.drinking then
    self.thirst = math.min(self.thirst + self.thirst_increase * dt, self.max_value)
  else
    self.thirst = math.max(0, self.thirst - self.consume_speed * dt)
  end

  self:applyTemperature(dt)
  self:update_health(dt)

end

----------keypressed and released
function Survivor:keypressed(key)
  if self.control == "player" then
    if key == "w"  then
      self.mov_vec.pos.y = self.mov_vec.pos.y - 1
    elseif key == "s" then
      self.mov_vec.pos.y = self.mov_vec.pos.y + 1
    elseif key == "a" then
      self.mov_vec.pos.x = self.mov_vec.pos.x - 1
    elseif key == "d" then
      self.mov_vec.pos.x = self.mov_vec.pos.x + 1
    end
  end
  if key == "1" then
    self.control = "player"
  elseif key == "2" then
    self.control = "finite"
    self.current_state = "idle"
  elseif key == "3" then
    self.control = "fuzzy"
    self.current_state = "idle"
  end
end

function Survivor:keyreleased(key)
  if self.control == "player" then
    if key == "w" then
      self.mov_vec.pos.y = self.mov_vec.pos.y + 1
    elseif key == "s" then
      self.mov_vec.pos.y = self.mov_vec.pos.y - 1
    elseif key == "a" then
      self.mov_vec.pos.x = self.mov_vec.pos.x + 1
    elseif key == "d" then
      self.mov_vec.pos.x = self.mov_vec.pos.x - 1
    end
  end
end

-----------resupply
function Survivor:resupply(type)
  if type == "water" then
    self.drinking = true
  elseif type == "food" then
    self.eating = true
  end
end

---------update health
function Survivor:update_health(dt)
  local damage_factor = 0
  if self.thirst > self.damage_threshold then
    damage_factor = damage_factor + ((self.thirst-self.damage_threshold)/(self.max_value-self.damage_threshold))
  end
  if self.hunger > self.damage_threshold then
    damage_factor = damage_factor + ((self.hunger-self.damage_threshold)/(self.max_value-self.damage_threshold))
  end
  if self.temperature < self.temperature_margin then
    damage_factor = damage_factor + ((self.temperature_margin - self.temperature)/self.temperature_margin)
  elseif self.temperature > self.max_value - self.temperature_margin then
    damage_factor = damage_factor + ((self.temperature - (self.max_value- self.temperature_margin))
                                      /self.temperature_margin)
  end

  self.health = math.max(self.health - damage_factor * self.damage_mult * dt, 0)
end

----------update logics
function Survivor:updateFiniteLogic()
  local node = self.finite_state_graph:get_node(self.current_state)
  local valid_connections = node:get_valid_connections({player = self})
  --updating the state of the survivor, currently only getting the first state
  for i, valid in ipairs(valid_connections) do
    self.mov_vec = POS(0, 0)
    self.current_state = valid.node.id
    break
  end

  self:runCurrentState()

end

function Survivor:updateFuzzyLogic()
  local node = self.fuzzy_state_graph:get_node(self.current_state)
  local valid_connection = node:get_best_fuzzy_connection({player = self})

  --updating the state of the survivor, currently only getting the first state

  if valid_connection then
    self.mov_vec = POS(0, 0)
    self.current_state = valid_connection.node.id
  end

  self:runCurrentState()
end

---------run states
function Survivor:runCurrentState()
  if self.current_state == "thirsty" then
    self:runthirstyState()
  elseif self.current_state == "hungry" then
    self:runHungryState()
  elseif self.current_state == "hot_cold" then
    self:runTemperatureState()
  end
end

function Survivor:runthirstyState()
  local closest_water = self:findClosestSupply("water", self.desired_temp)

  if not closest_water then
    closest_water = self:findClosestSupply("water")
  end

  if closest_water and checkDistance(self.pos, closest_water.pos) > 2 then
    self.mov_vec.pos.x = closest_water.pos.x - self.pos.x
    self.mov_vec.pos.y = closest_water.pos.y - self.pos.y

    self.mov_vec.pos = normalizeVector(self.mov_vec.pos)
  else
    self.mov_vec = POS(0, 0)
  end
end

function Survivor:runHungryState()
  local closest_food = self:findClosestSupply("food", self.desired_temp)

  if not closest_food then
    closest_food = self:findClosestSupply("food")
  end


  if closest_food and checkDistance(self.pos, closest_food.pos) > 2 then
    self.mov_vec.pos.x = closest_food.pos.x - self.pos.x
    self.mov_vec.pos.y = closest_food.pos.y - self.pos.y

    self.mov_vec.pos = normalizeVector(self.mov_vec.pos)
  else
    self.mov_vec = POS(0, 0)
  end
end

function Survivor:runTemperatureState()
  local margin = 50
  if self.pos.y < self.temperature_difference + margin and
     self.temperature < self.temperature_margin then
      self.desired_temp = "hot"
      self.mov_vec.pos.y = 1
      self.mov_vec.pos.x = 0
	elseif self.pos.y > self.temperature_difference - margin and
         self.temperature > self.max_value - self.temperature_margin then
      self.desired_temp = "cold"
      self.mov_vec.pos.y = -1
      self.mov_vec.pos.x = 0
  else
    self.mov_vec.pos.y = 0
    self.mov_vec.pos.x = 0
	end
end

----------apply temperature
function Survivor:applyTemperature(dt)
	if self.pos.y < self.temperature_difference then
		self.temperature = self.temperature - self.temperature_change * dt
	elseif self.pos.y > self.temperature_difference then
		self.temperature = self.temperature + self.temperature_change * dt
	end
	self.temperature = math.min(math.max(0, self.temperature), self.max_value)
end

--------find supply
function Survivor:findClosestSupply(type, temp)
  local closest_supply = false

  for supply in pairs(Util.findSubtype("supply")) do
    if supply.tp == type then
      if not temp or temp == supply.temp then
        if not closest_supply then
          closest_supply = supply
        elseif checkDistance(self.pos, closest_supply.pos) > checkDistance(self.pos, supply.pos) then
          closest_supply = supply
        end
      end
    end
  end
  return closest_supply
end

-------------get fuzzy value
function Survivor:getFuzzyValue(attribute_name, value)
  if self.fuzzy_sets[attribute_name] then
    return self.fuzzy_sets[attribute_name](value)
  else
    error("name does not exist: "..tostring(attribute_name))
  end
end
-------------------local functions

function checkDistance(o1, o2)
  return math.sqrt(math.pow(o1.x - o2.x, 2) + math.pow(o1.y - o2.y, 2))
end

function normalizeVector(vector)
  local magnitude = math.sqrt(math.pow(vector.x, 2) + math.pow(vector.y, 2))
  return {x = vector.x/magnitude, y = vector.y/magnitude}
end


return Survivor
