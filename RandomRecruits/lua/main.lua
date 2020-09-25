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
		local units = multiplayer_side.recruit or ""
		for _, unit in ipairs(split_comma(units)) do
			if era_set[unit] == nil and wesnoth.unit_types[unit] then
				-- print("importing era unit " .. unit)
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


on_event("turn refresh", function()
	local side = wesnoth.sides[wesnoth.current.side]
	side.recruit = {};
	local start_loc = wesnoth.get_starting_location(side.side)
	while true do
		local recruit_type = random_recruit()
		if side.gold >= wesnoth.unit_types[recruit_type].cost then
			local unit = wesnoth.create_unit { type = recruit_type, side = side.side }
			local x, y = wesnoth.find_vacant_tile(start_loc[1], start_loc[2], unit)
			wesnoth.put_unit(unit, x, y)
			side.gold = side.gold - wesnoth.unit_types[recruit_type].cost
		else
			break
		end
	end
end)

-- >>
