local Util = require "util"
local Draw = require "draw"
local Width = 1920
local Height = 1080
local Division = 500
local which_control = "fuzzy"
local seed = 0
local survivor
local UI
local BackGround
local test_time_finite
local test_time_fuzzy
local total_time_difference = 0
local total_tests = 0
--MODULE FOR THE GAMESTATE: GAME--

local state = {}

--LOCAL VARIABLES--

local _switch --If gamestate should change to another one

--LOCAL FUNCTIONS--

--STATE FUNCTIONS--
function state:enter()
	love.math.setRandomSeed(love.timer.getTime())
	self:restart_simulation()
end

function state:leave()

	Util.destroyAll()

end

function state:restart_simulation()
	if which_control == "fuzzy" then
		if total_tests > 0 then
			print("Test: "..total_tests)
			print("Fuzzy took: "..test_time_fuzzy.." seconds")
			print("finite took: "..test_time_finite.." seconds")
			print("the difference is "..test_time_fuzzy-test_time_finite.." seconds")
			total_time_difference = total_time_difference + test_time_fuzzy-test_time_finite
			if total_time_difference > 0 then
				print("fuzzy on average took longer: "..total_time_difference/total_tests.." seconds")
			else
				print("finite on average took longer: "..-total_time_difference/total_tests.." seconds")
			end
		end

		which_control = "finite"
		seed = love.math.random(0, 10000000)
		total_tests = total_tests + 1
	else
		which_control = "fuzzy"
	end
	self:clean_elements()
	love.math.setRandomSeed(seed)
	Division = love.math.random(400, 700)
	survivor = require "classes.survivor"(500, 500, Division)
	UI = require "classes.UI"(survivor)
	BackGround = require "classes.temperature_background"(Division, Width, Height)
	survivor:register("L2", nil, "survivor")
	survivor.control = which_control
	UI:register("GUI", nil, "UI")
	BackGround:register("BG", nil, "background")
	generate_supply(5, 5)
end

function state:clean_elements()
	if survivor then
		survivor:destroy()
	end
	if UI then
		UI:destroy()
	end
	if BackGround then
		BackGround:destroy()
	end
	if Util.findSubtype("supply") then
		for supply in pairs(Util.findSubtype("supply")) do
			supply:destroy()
		end
	end
end

function state:update(dt)
	local survivor = Util.findId("survivor")
	if survivor then
		survivor:update(dt)
		if survivor.health <= 0 then
			if which_control == "finite" then
				test_time_finite = survivor.time_alive
			else
				test_time_fuzzy = survivor.time_alive
			end
			survivor:kill()
			self:restart_simulation()
		end
	end

	Util.destroyAll()

end

function state:draw()

    Draw.allTables()

end

function state:keypressed(key)
	if Util.findId("survivor") then
		Util.findId("survivor"):keypressed(key)
	end
end

function state:keyreleased(key)
	if Util.findId("survivor") then
		Util.findId("survivor"):keyreleased(key)
	end
end

function generate_supply(water_n, food_n)

	local margin = 20
	for i = 1, water_n do
		local radius = love.math.random(20,50)
		local new_supply = require "classes.water"(0, 0, radius, Division)
		new_supply:register("L1", "supply", nil)
		generate_valid_supply_pos(new_supply, margin)
	end

	for i = 1, food_n do
		local radius = love.math.random(20, 150)
		local new_supply = require "classes.food"(0, 0, radius, Division)
		new_supply:register("L1", "supply", nil)
		generate_valid_supply_pos(new_supply, margin)
	end
end

function generate_valid_supply_pos(new_supply, margin)
	local radius = new_supply.r
	repeat
		local rand_pos = {x = love.math.random(margin+radius, Width-radius-margin),
											y = love.math.random(margin+radius, Height-radius-margin)}
		new_supply:setPos(rand_pos.x, rand_pos.y)
		local is_valid = true
		for supply in pairs(Util.findSubtype("supply")) do
			if supply ~= new_supply and supply:collision(new_supply) then
				is_valid = false
				break
			end
		end
	until is_valid
end


--Return state functions
return state
