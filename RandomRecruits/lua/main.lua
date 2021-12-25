-- << RandomRecruits/main.lua

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
	if wesnoth.scenario.era then
		for multiplayer_side in helper.child_range(wesnoth.scenario.era, "multiplayer_side") do
			local units = multiplayer_side.recruit or multiplayer_side.leader or ""
			for _, unit in ipairs(split_comma(units)) do
				local unit_type = wesnoth.unit_types[unit]
				if era_set[unit] == nil and unit_type and unit_type.level == 1 then
					era_set[unit] = true
					era_array[#era_array + 1] = unit
				end
			end
		end
		era_set = nil  -- free up memory
	else
		era_array = {
			"Cavalryman", "Horseman", "Spearman", "Fencer", "Heavy Infantryman", "Bowman", "Mage",
			"Merman Fighter", "Elvish Fighter", "Elvish Archer", "Elvish Shaman", "Elvish Scout", "Wose",
			"Merman Hunter", "Orcish Grunt", "Troll Whelp", "Wolf Rider", "Orcish Archer",
			"Orcish Assassin", "Naga Fighter", "Skeleton", "Skeleton Archer", "Ghost", "Dark Adept",
			"Ghoul", "Dwarvish Guardsman", "Dwarvish Fighter", "Dwarvish Ulfserker", "Dwarvish Thunderer",
			"Thief", "Poacher", "Footpad", "Gryphon Rider", "Drake Burner", "Drake Clasher",
			"Drake Glider", "Drake Fighter", "Saurian Skirmisher", "Saurian Augur"
		}
	end
end
if not pcall(init_era) then
	local era_id =	wesnoth.scenario.mp_settings and wesnoth.scenario.mp_settings.mp_era
		or "default_era"
	local msg = "Failed to load Era " .. era_id
	wesnoth.wml_actions.message { caption = "Random Recruits", message = msg }
	wesnoth.message("Random Recruits", msg)
	wesnoth.wml_actions.endlevel { result = "defeat" }
	init_era()
end

local era_unit_rand_string = "1.." .. #era_array
local function random_recruit()
	return era_array[helper.rand(era_unit_rand_string)]
end

local function random_recruit_array(desired_length)
	local result = {}
	local set = {}
	local attempt = 0
	while attempt < 100 and #result < desired_length do
		local unit = random_recruit()
		if set[unit] == nil then
			set[unit] = true
			result[#result + 1] = unit
		end
		attempt = attempt + 1
	end
	return result
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
	if result.enable then
		for _, side in ipairs(wesnoth.sides) do
			if #side.recruit > 0 then
				side.recruit = random_recruit_array(3)
				wesnoth.set_variable("RandomRecruits_enabled_" .. side.side, true)
				side.gold = side.gold - 5
			end
		end
	end
end)

on_event("prerecruit", function()
	local side = wesnoth.sides[wesnoth.current.side]
	if wesnoth.get_variable("RandomRecruits_enabled_" .. side.side) then
		side.recruit = random_recruit_array(3)
	end
end)

-- >>
