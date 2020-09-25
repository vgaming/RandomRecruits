-- << afterlife/main_defense

local wesnoth = wesnoth
local ipairs = ipairs
local gmatch = string.gmatch
local on_event = wesnoth.require("lua/on_event.lua")
local helper = wesnoth.require("lua/helper.lua")

local function split_comma(str)
	local result = {}
	local n = 1
	for s in gmatch(str or "", "%s*[^,]+%s*") do
		if s ~= "" and s ~= "null" then
			result[n] = s
			n = n + 1
		end
	end
	return result
end

local era_array = {}
local era_set = {}

local function init_era()
	for multiplayer_side in helper.child_range(wesnoth.game_config.era, "multiplayer_side") do
		local units = multiplayer_side.recruit or multiplayer_side.leader or ""
		for _, unit in ipairs(split_comma(units)) do
			if era_set[unit] == nil and wesnoth.unit_types[unit] then
				era_set[unit] = true
				era_array[#era_array + 1] = unit
			end
		end
	end
end
if not pcall(init_era) then
	local msg = "Failed to load Era " .. wesnoth.game_config.mp_settings.mp_era
	wesnoth.wml_actions.message { caption = "Random Recruits", message = msg }
	wesnoth.message("Random Recruits", msg)
	wesnoth.wml_actions.endlevel { result = "defeat" }
	init_era()
end

local era_unit_rand_string = "1.." .. #era_array
local function random_recruit()
	return era_array[helper.rand(era_unit_rand_string)]
end

local function find_leader(side)
	for _, leader in ipairs(wesnoth.get_units { canrecruit = true, side = side.side }) do
		if wesnoth.get_terrain_info(wesnoth.get_terrain(leader.x, leader.y)).keep then
			return leader
		end
	end
end

local function generate_units(side)
	if not wesnoth.get_variable("RandomRecruits_enabled") then
		return
	end
	side = side.side and side or wesnoth.sides[wesnoth.current.side]
	side.recruit = {};
	local leader = find_leader(side)
	if leader == nil then
		return
	end
	while true do
		local recruit_type = random_recruit()
		if side.gold >= wesnoth.unit_types[recruit_type].cost then
			local unit = wesnoth.create_unit { type = recruit_type, side = side.side }
			local x, y = wesnoth.find_vacant_tile(leader.x, leader.y, unit)
			wesnoth.put_unit(unit, x, y)
			side.gold = side.gold - wesnoth.unit_types[recruit_type].cost
		else
			break
		end
	end
end

on_event("start", function()
	local options = {
		{
			text = "Activate, make recruits random!",
			image = "units/random-dice.png",
			enable = true
		}, {
			text = "Deactivate, use standard recruits",
			image = "misc/red-x.png",
			enable = false
		},
	}
	local label = "Activate RandomRecruits add-on?"
	local result = randomrecruits.show_dialog { label = label, options = options, can_cancel = false }
	result = options[result.index]
	wesnoth.set_variable("RandomRecruits_enabled", result.enable)
	if result.enable then
		for _side_number, side in ipairs(wesnoth.sides) do
			generate_units(side)
		end
	end
end)

on_event("turn refresh", generate_units)

-- >>
