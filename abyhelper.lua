_addon.name    = 'abyhelper'
_addon.author  = 'Mujihina'
_addon.version = '1.01'
_addon.command = 'abyhelper'
_addon.commands = {'ah'}

require ('luau')
texts = require('texts')
packets = require('packets')
require('ui')
aby_data = require('aby_data')

-- Res
zones =			require('resources').zones
key_items =		require('resources').key_items
weapon_skills = require('resources').weapon_skills
spells = 		require('resources').spells
days = 			require('resources').days
items = 		require('resources').items
elements =		require('resources').elements
skills =		require('resources').skills


local menu_objects = T{}
local sub_menu_objects = T{}
local interactive_objects = T{}
local non_interactive_objects = T{}
local pop_chart_objects = T{}
local current_zone_pop_chart = nil
local selected_objects = {
	['menu'] = nil,
	['zone'] = nil,
	['job'] = nil,
	['slot'] = nil,
	['proc_color'] = nil,
	['day'] = nil,
	['pop_chart'] = nil,
}
local results_object = nil
local target_object = nil
local minimized = false
local player_id = 0
local player_name = ''
local target = nil
local quiet_mode = false

--[[
MENUS				SUB MENUS
Abyssite:			Zones (+ Main Story)
Atma:				Zones
+1 (upgrade items): Job + Slot
+2 (upgrade items): Job + Slot
Pop Items:			Zones + Optional selection to search and print owned pops in chatlog.
Procs:				Color (+ Day submenu for Yellow procs only)
]]


---- LOADING FUNCTIONS
function load_defaults()
    -- Do not load anything if we are not logged in
    if (not windower.ffxi.get_info().logged_in) then
    	exit_addon()
    	return
    end
    local player = windower.ffxi.get_player()
	player_id = player.id
	player_name = player.name

	load_zone_sub_menu()
	load_job_sub_menu()
	load_slot_sub_menu()
	load_results()
	load_proc_sub_menu()
	load_day_sub_menu()
	load_menus()
	load_area_pop_charts()
	load_print_pop_items_sub_menu()
	load_target_object()
end

-- Create menu menus and main buttons
function load_menus()
	local pos_x = 20
	local pos_y = 290
	local pad = 10
	local abyssite_menu = new_menu('Abyssite':rpad(' ', pad), pos_x, pos_y, 'menu')
	abyssite_menu.left_click_down = show_abyssite_menu
	menu_objects:append(abyssite_menu)

	pos_y = pos_y + 40
	local atma_menu = new_menu('Atma':rpad(' ', pad), pos_x, pos_y, 'menu')
	atma_menu.left_click_down = show_atma_menu
	menu_objects:append(atma_menu)

	pos_y = pos_y + 40
	local plus_one_menu = new_menu('+1':rpad(' ', pad), pos_x, pos_y, 'menu')
	plus_one_menu.left_click_down = show_plus_one_menu
	menu_objects:append(plus_one_menu)

	pos_y = pos_y + 40
	local plus_two_menu = new_menu('+2':rpad(' ', pad), pos_x, pos_y, 'menu')
	plus_two_menu.left_click_down = show_plus_two_menu
	menu_objects:append(plus_two_menu)

	pos_y = pos_y + 40
	local pops_menu = new_menu('Pop Items':rpad(' ', pad), pos_x, pos_y, 'menu')
	pops_menu.left_click_down = show_pops_menu
	menu_objects:append(pops_menu)

	pos_y = pos_y + 40
	local procs_menu = new_menu('Procs':rpad(' ', pad), pos_x, pos_y, 'menu')
	procs_menu.left_click_down = show_procs_menu
	menu_objects:append(procs_menu)

	pos_y = pos_y + 80
	pos_x = pos_x + 30
	local minimize_button = new_button('Minimize':rpad(' ', pad), pos_x, pos_y, 'visibility')
	minimize_button.left_click_down = minimize_addon
	minimize_button.select = function() end
	minimize_button.text:show()
	menu_objects:append(minimize_button)

	local show_button = new_button('Show abyhelper':rpad(' ', pad), pos_x, pos_y, 'visibility')
	show_button.left_click_down = show_addon
	show_button.type = 'visibility'
	show_button.select = function() end
	menu_objects:append(show_button)

	pos_y = pos_y + 40
	local exit_button = new_button('Exit':rpad(' ', pad), pos_x, pos_y, 'exit')
	exit_button.left_click_down = function() end
	exit_button.left_click_up = exit_addon
	exit_button.text:show()
	menu_objects:append(exit_button)
	
	interactive_objects:extend(menu_objects)
end

-- Create zone sub menu
function load_zone_sub_menu()
	local pos_x = 200
	local pos_y = 340
	
	sub_menu_objects['zones'] = {}
	sub_menu_objects['zones']['title'] = new_title('Select\nArea:', pos_x, pos_y - 50)
	sub_menu_objects['zones']['items'] = T{}

	for j in aby_data.aby_zones:it() do
		local zone = new_menu(zones[j].search:rpad(' ',13), pos_x, pos_y, 'zone')
		zone.zone_id = j
		sub_menu_objects['zones']['items']:append(zone)
		pos_y = pos_y + 25
	end
	interactive_objects:extend(sub_menu_objects['zones']['items'])
	
	-- extra zone (only displayed if Abyssite Menu is selected)
	local zone =  new_menu('Main Story':rpad(' ',13), pos_x, pos_y,'zone')
	zone.zone_id = 999999
	sub_menu_objects['extrazone'] = zone
	interactive_objects:append(zone)
end


-- Create job sub menu
function load_job_sub_menu()
	local pos_x = 200
	local pos_y = 340
	
	sub_menu_objects['jobs'] = {}
	sub_menu_objects['jobs']['title'] = new_title('Select\nJob:', pos_x, pos_y - 50)
	sub_menu_objects['jobs']['items'] = T{}

	for j in aby_data.aby_jobs:it() do
		local job = new_menu(j:rpad(' ',5), pos_x, pos_y, 'job')
		sub_menu_objects['jobs']['items']:append(job)
		pos_y = pos_y + 25
		if pos_y > 565 then
			pos_y = 340
			pos_x = pos_x + 72
		end
	end
	interactive_objects:extend(sub_menu_objects['jobs']['items'])
end

-- Create equipment slot sub menu
function load_slot_sub_menu()
	local pos_x = 200
	local pos_y = 650
	
	sub_menu_objects['slots'] = {}
	sub_menu_objects['slots']['title'] = new_title('Select\nSlot:', pos_x, pos_y - 50)
	sub_menu_objects['slots']['items'] = T{}

	for j in aby_data.aby_slots:it() do
		local slot = new_menu(j:rpad(' ',7), pos_x, pos_y, 'slot')
		sub_menu_objects['slots']['items']:append(slot)
		pos_y = pos_y + 25
	end
	interactive_objects:extend(sub_menu_objects['slots']['items'])
end

-- Create proc sub menu
function load_proc_sub_menu()
	local pos_x = 200
	local pos_y = 340
	
	sub_menu_objects['procs'] = {}
	sub_menu_objects['procs']['title'] = new_title('Select\nProc type:', pos_x, pos_y - 50)
	sub_menu_objects['procs']['items'] = T{}
	
	local colors = L{'Red', 'Blue', 'Yellow'}
	for i in colors:it() do
		local color = new_menu(i:rpad(' ', 10), pos_x, pos_y, 'proc_color')
		sub_menu_objects['procs']['items']:append(color)
		pos_y = pos_y + 25
	end
	interactive_objects:extend(sub_menu_objects['procs']['items'])
end

-- Create day sub menu
function load_day_sub_menu()
	local pos_x = 200
	local pos_y = 470
	
	sub_menu_objects['days'] = {}
	sub_menu_objects['days']['title'] = new_title('Select\nDay/Element:', pos_x, pos_y - 50)
	sub_menu_objects['days']['items'] = T{}
	
	for i, _ in pairs(days) do
		local day = new_menu(days[i].name:rpad(' ', 14), pos_x, pos_y, 'day')
		day.day_id = i
		sub_menu_objects['days']['items']:append(day)
		pos_y = pos_y + 25
	end
	interactive_objects:extend(sub_menu_objects['days']['items'])
end


-- Create text blob used for all menu options except Pop Items
function load_results()
	local pos_x = 500
	local pos_y = 100
	results_object = new_results(pos_x, pos_y)
end

function load_target_object()
	local settings = windower.get_windower_settings()
	local pos_x = settings.x_res / 2 - 100
	local pos_y = settings.y_res - 300
	target_object = new_target(pos_x, pos_y)
	target_object.text:show()
end


-- Create all Area Pop Charts
function load_area_pop_charts()
	local pos_x = 100
	local pos_y = 50

	for zone in aby_data.aby_zones:it() do
		pop_chart_objects[zone] = L{}
		pop_chart_objects[zone]:append(new_title('Pop Item Chart for %s':format(zones[zone].name), pos_x + 288, pos_y + 25))
		for mob in aby_data.pop_chart[zone]:it() do
			local entry = mob.name
			local drop_type = nil
			local item_id = nil
	
			if mob.mob_type ~= 'mob' then
				entry = '(%s) %s':format(mob.mob_type, entry)
			end
			if mob.info then
				entry = entry:append(' (%s)':format(mob.info))
			end
			entry = entry:rpad(' ', 38)
			if mob.drop then
				item_id = mob.drop.item_id
	
				if mob.drop.item_type == 'KI' then
					entry = entry:append("\n${have_it|[ ]} (KI) %s":format(key_items[item_id].name))
					drop_type = 'KI'
				else
					entry = entry:append("\n${have_it|[ ]} %s${container|}":format(items[item_id].name))
					drop_type = 'item'
				end
			else
				-- add extra line for those entries without drops (so all entries have at least 2 lines)
				entry = entry:append('\n ')
			end
			-- Pad it vertically for heights > 1
			if mob.height > 1 then
				entry = entry:append('':rpad('\n', (3 * mob.height) - 2))
			end
	
			local pop_entry_obj = new_pop_entry(entry, pos_x + (mob.grid_x * 288), pos_y + (mob.grid_y * 48))
			pop_entry_obj.drop_type = drop_type
			pop_entry_obj.item_id = item_id
			pop_chart_objects[zone]:append(pop_entry_obj)
			
			local line_count  = entry:split('\n'):length()		
			if mob.drop then
				mob.grid_x = mob.grid_x + 1
				pop_entry_obj.pop_color_obj =  new_pop_color(line_count, pos_x + (mob.grid_x * 288) - 9, pos_y + (mob.grid_y * 48))
			end
		end 
	end
end


-- Create 'Add to Chat' sub menu to print owned pops and locations, if desired.
function load_print_pop_items_sub_menu()
	local pos_x = 200
	local pos_y = 650

	sub_menu_objects['print_pops'] = {}
	sub_menu_objects['print_pops']['title'] = new_title('Click to\nadd to chat:', pos_x, pos_y - 50)
	sub_menu_objects['print_pops']['items'] = T{}

	local all_pops = new_button('All pops':rpad(' ', 13), pos_x, pos_y, 'print_pops')
	all_pops.select = function() end
	all_pops.left_click_down = function()
									log('Currently owned abyssea pop items:')
									local output = ''
									for i in aby_data.aby_zones:it() do
										output = output:append(get_pop_output(i))
									end
									if not output:empty() then
										log(output:trim())
									end
								end
	local zone_pops = new_button('Zone pops':rpad(' ', 13), pos_x, pos_y + 30, 'print_pops')
	zone_pops.select = function() end
	zone_pops.left_click_down = function()
									if selected_objects['zone'] then
										local output = get_pop_output(selected_objects['zone'].zone_id)
										if output:empty() then
											log('You currently do not possed any item pops for %s':format(zones[selected_objects['zone'].zone_id].name:color(261)))
										else
											log(output)
										end
									else
										log('Select a zone first':color(167))
									end
								end
	sub_menu_objects['print_pops']['items']:append(all_pops)
	sub_menu_objects['print_pops']['items']:append(zone_pops)

	interactive_objects:extend(sub_menu_objects['print_pops']['items'])
end



---- VISIBILITY FUNCTIONS: Show/hide sub menus depending on main menu
function show_abyssite_menu()
	clear_results()
	hide_sub_menu('jobs', 'slots',  'procs', 'days')
	show_sub_menu('zones')
end

function show_atma_menu()
	clear_results()
	hide_sub_menu('jobs', 'slots', 'procs', 'days', 'print_pops')
	show_sub_menu('zones')
end

function show_plus_one_menu()
	clear_results()
	hide_sub_menu('zones',  'procs', 'days', 'print_pops')
	show_sub_menu('jobs', 'slots')
end

function show_plus_two_menu()
	clear_results()
	hide_sub_menu('zones',  'procs', 'days', 'print_pops')
	show_sub_menu('jobs', 'slots')
end

function show_pops_menu()
	clear_results()
	hide_sub_menu('jobs', 'slots', 'procs', 'days')
	show_sub_menu('zones', 'print_pops')
end

function show_procs_menu()
	clear_results()
	hide_sub_menu('jobs', 'slots', 'zones', 'print_pops')
	show_sub_menu('procs')
end

function minimize_addon()
	minimized = true
	results_object.text:hide()
	hide_sub_menu('jobs', 'slots', 'procs', 'days', 'print_pops', 'zones')
	for i in menu_objects:it() do
		if i.name == 'Show abyhelper' then
			i.text:show()
		else
			i.text:hide()
		end
	end
	if current_zone_pop_chart then
		hide_area_pop_chart(current_zone_pop_chart)
	end
	sub_menu_objects['extrazone'].text:hide()
end

function show_addon()
	minimized = false
	for i in menu_objects:it() do
		if i.name == 'Show abyhelper' then
			i.text:hide()
		else
			i.text:show()
		end
	end
	results_object.text:show()
	if selected_objects['menu'] then
		selected_objects['menu'].left_click_down()
	end
end


-- Show specified sub menu (including its title text object)
function show_sub_menu(...)
	local sub_menus = L{...}
	if not sub_menus then return end
	
	for i in sub_menus:it() do
		sub_menu_objects[i]['title'].text:show()
		for _, obj in pairs(sub_menu_objects[i]['items']) do
			obj.text:show()
		end
	end
	if current_zone_pop_chart then
		hide_area_pop_chart(current_zone_pop_chart)
	end
end

-- Hide specified sub menu (including its title text object)
function hide_sub_menu(...)
	local sub_menus = L{...}
	if not sub_menus then return end
	
	for i in sub_menus:it() do
		sub_menu_objects[i]['title'].text:hide()
		for _, obj in pairs(sub_menu_objects[i]['items']) do
			obj.text:hide()
		end
	end
end

-- Show pop chart for specified zone, dynamically update colors and possesion checkmarks if pops are owned
function show_area_pop_chart(zone)
	local my_key_items = get_key_items()
	local player_items = windower.ffxi.get_items()

	for obj in pop_chart_objects[zone]:it() do
		if obj.drop_type then
			if obj.drop_type == 'KI' then
				if my_key_items:contains(obj.item_id) then
					obj.text.have_it = '[X]'
					obj.pop_color_obj:green()
				else
					obj.text.have_it = nil
					obj.pop_color_obj:red()
				end
			else
				local search_results = check_containers_for_item(obj.item_id, player_items)
				if search_results.total > 0 then
					obj.text.have_it = '[X]'
					obj.text.container = ' [%s]':format(next(search_results.results:keyset()))
					obj.pop_color_obj:green()
				else
					obj.text.have_it = nil
					obj.text.container = ''
					obj.pop_color_obj:red()
				end
			end
		end
		obj.text:show()
	end
end


-- Hide all elements in pop chart of specified zone
function hide_area_pop_chart(zone)
	for obj in pop_chart_objects[zone]:it() do
		obj.text:hide()
		if obj.pop_color_obj then
			obj.pop_color_obj.text:hide()
		end
	end	
end

-- Update main text blob
function update_results(data)
	results_object.text.data = data
end

-- Clear main text blob
function clear_results()
	if results_object then
		results_object.text.data = ''
	end
end

-- Exit addon
function exit_addon()
--	-- destroy all text objects
--	for _, obj in pairs(non_interactive_objects) do
--		obj.destroy()
--	end
--	for _, obj in pairs(interactive_objects) do
--		obj.destroy()
--	end
--	-- unload
	windower.send_command('lua unload abyhelper')
end


---- UTILS

-- output to tell or pchat.
function send_to_output(msg)
	print('output', msg)
	if quiet_mode then
		windower.send_command('input /tell %s %s':format(player_name, msg))
	else
		windower.send_command('input /p %s':format(msg))
	end
end


-- Create List of KIs
function get_key_items()
	local my_key_items = L{}
	for _, i in ipairs(windower.ffxi.get_key_items()) do
		my_key_items:append(i)
	end
	return my_key_items
end

-- Make current day the default selected day
function auto_select_day(today)
	for _, i in pairs(sub_menu_objects['days']['items']) do
		if i.name == today then
			i.select()
			selected_objects['day'] = i
			return
		end
	end		
end

-- Make current job the default selected day
function auto_select_job()
	local job = windower.ffxi.get_player().main_job
	for _, i in pairs(sub_menu_objects['jobs']['items']) do
		if i.name == job then
			i.select()
			selected_objects['job'] = i
			return
		end
	end		
end

-- Make current zone the selected zone, if it is an aby area
function auto_select_zone()
	local zone = windower.ffxi.get_info().zone
	if aby_data.aby_zones:contains(zone) then
		for _, i in pairs(sub_menu_objects['zones']['items']) do
			if i.zone_id == zone then
				i.select()
				selected_objects['zone'] = i
				return
			end
		end
	end		
end

-- Is current time between range? (range can go over midnight)
function within_time_range(now, start_time, end_time)
	start_time = start_time * 60
	end_time = end_time * 60
	-- Have to deal with ranges like 22:00-06:00
	if end_time > start_time then
		if now >= start_time and now < end_time then
			return true
		end
	else
		if now >= start_time or now < end_time then
			return true
		end
	end
	return false
end

-- Can player cast specific spell?
-- Return true/false
function can_cast_spell(spell_id, my_spells, player)
	-- false if we've never learned it
	if not my_spells[spell_id] then return false end
	local main_job_id = player.main_job_id
	local sub_job_id = player.sub_job_id

	-- Can main cast it?
	if spells[spell_id]['levels'][main_job_id] and player.main_job_level >= spells[spell_id]['levels'][main_job_id] then
		return true
	end
	-- Can sub cast it?
	if spells[spell_id]['levels'][sub_job_id] and player.sub_job_level >= spells[spell_id]['levels'][sub_job_id] then
		return true
	end
	return false
end

-- Does player have specific item? if so, how many total, and where.
-- Return {total, results}
-- total: number
-- results: table with container name as key, with ['total'], a container total;  and ['items'], a text of object's name and stack size.
-- e.g. search for "Whatever" returns total count of 12: 6 in 2 stacks in safe, and 1 stack of 6 in inventory.
--{12,
--	['safe'] = {
--		total=6,
--		items=L{'Whatever (4)', 'Whatever (2)'}
--	},
--	['inventory'] = {
--		total=6,
--		items=L{'Whatever (6)'}
--	}
--}
function check_containers_for_item(item_id, player_items)
	local containers = L{'inventory', 'safe', 'safe2', 'storage', 'locker', 'satchel', 'sack', 'case'}
	-- local player_items = windower.ffxi.get_items()
	local total = 0
	local search_results = T{}
	for i in containers:it() do
		if player_items[i] then
			for _, j in ipairs(player_items[i]) do	
				if j.id > 0 and j.id == item_id then
					if not search_results[i] then
						search_results[i] = {}
						search_results[i]['total'] = 0
						search_results[i]['items'] = L{}
					end
					search_results[i]['total'] = search_results[i]['total'] + j.count
					if j.count > 2 then
						search_results[i]['items']:append('%s (x%d)':format(items[j.id].name, j.count))
					else
						search_results[i]['items']:append('%s':format(items[j.id].name))
					end
					total = total + j.count
				end
			end
		end
	end
	return {total=total, results=search_results}
end

-- Return a formatted string with KI data including:
-- title, column headers, and a list of KI names, where to get it, and whether we have it or not
function generate_key_items_table(title, list_of_ki)
	local my_key_items =  get_key_items()

	local results_string = '%s\n%s\n':format(title, '':rpad('-', title:length()))	
	results_string = results_string:append('    %s %s\n':format('KI':rpad(' ', 33), 'SOURCE'))

	for i in list_of_ki:it() do
		local have_it = '[ ]'
		if my_key_items:contains(i.ki) then
			have_it = '[X]'
		end
		results_string = results_string:append('%s %s %s\n':format(have_it, key_items[i.ki].name:rpad(' ', 33), i.source))
	end
	return results_string:trim()
end

-- Return a formatted string with +1/+2 data for specific job/slot including:
-- title, column headers, how many player relevant +1/+2 has and where, who drops items, and which zone name.
function generate_upgrade_items_table(upgrade_type, job, slot, items_table)
	local results_string = ''
	local item_id = items_table.id
	local header = '%s upgrade item for %s/%s: %s':format(upgrade_type, job, slot, items[item_id].name)
	local player_items = windower.ffxi.get_items()
	results_string = results_string:append('%s\n%s\n\n':format(header, '':rpad('-', header:length())))

	local search_results = check_containers_for_item(item_id, player_items)
	results_string = results_string:append('Currently have: %d/%d\n':format(search_results.total, items_table.need))
	for container, contents in pairs(search_results.results) do
		for item in contents.items:it() do
			results_string = results_string:append('%s: %s\n':format(container:lpad(' ', 13), item))
		end
		
	end

	results_string = results_string:append('\n%s %s %s\n':format('SOURCE':rpad(' ', 22), 'ZONE':rpad(' ', 22), 'INFO'))	
	for i in items_table.locs:it() do
		results_string = results_string:append('%s %s %s\n':format(i.source:rpad(' ', 22), zones[i.zone].name:rpad(' ', 22), i.info))
	end
	return results_string:trim()
end

-- Return a formatted string to be sent to chat including:
-- which items pops player has and where, and which area they are for.
function get_pop_output(zone)
	local output = ''
	local player_items = windower.ffxi.get_items()
	for mob in aby_data.pop_chart[zone]:it() do
		if mob.drop and mob.drop.item_type == 'item' then
			local search_results = check_containers_for_item(mob.drop.item_id, player_items)
			if search_results.total > 0 then
				for container, items in pairs(search_results.results) do
					for i in items.items:it() do
						output = output:append('%s/%s -- Pop for %s\n':format(container:color(259), i:color(258), zones[zone].name:color(261)))
					end
				end
			end
		end
	end
	return output
end


-- Take action based on current menu and sub menu selections
function process_selections()
	if not selected_objects or not selected_objects['menu'] or minimized then
		return
	end	
	clear_results()
	
	-- handle extra zone:
	-- Unselect "Main Story" 'zone' if already selected and main menu is not Abyssite.
	sub_menu_objects['extrazone'].text:hide()
	if selected_objects['zone'] and selected_objects['zone'].name == 'Main Story' and selected_objects['menu'].name ~= 'Abyssite' then
		sub_menu_objects['extrazone'].unselect()
		selected_objects['zone'] = nil
	end

	-- handle pop chart: hide current pop chart if new selections are made
	if current_zone_pop_chart then
		hide_area_pop_chart(current_zone_pop_chart)
		current_zone_pop_chart = nil
	end

	-- Atma: Show list of Atmas and Synthetic atmas for selected zone, and whether player has them
	if selected_objects['menu'].name == 'Atma' then
		if not selected_objects['zone'] then
			auto_select_zone()
		end
		if selected_objects['zone'] then
			local zone_id = selected_objects['zone'].zone_id
			if not zone_id or not aby_data.atma[zone_id] then print('ah error: no atma data found') return end
			local results_string = generate_key_items_table('ATMA (%s)':format(zones[zone_id].name), aby_data.atma[zone_id])

			-- synthetic atmas
			local synthetic_atmas = nil
			local aby_expansion = nil
			if aby_data.heroes_zones:contains(zone_id) then
				synthetic_atmas = aby_data.heroes_synthetic
				aby_expansion = 'Heroes of Abyssea'
			elseif aby_data.scars_zones:contains(zone_id) then
				synthetic_atmas = aby_data.scars_synthetic
				aby_expansion = 'Scars of Abyssea'
			elseif aby_data.vision_zones:contains(zone_id) then
				synthetic_atmas = aby_data.vision_synthetic
				aby_expansion = 'Vision of Abyssea'
			end
			if synthetic_atmas then
				results_string = results_string:append('\n\n')
				results_string = results_string:append(generate_key_items_table('SYNTHETIC ATMA (%s)':format(aby_expansion), synthetic_atmas))
			end
			update_results(results_string)
		end
		return
	end

	-- Abyssite: Show list of Abyssite for selected zone, and whether player has them
	if selected_objects['menu'].name == 'Abyssite' then
		-- Show 'Main Story' zone submenu option
		sub_menu_objects['extrazone'].text:show()
	
		if not selected_objects['zone'] then
			auto_select_zone()
		end
		if selected_objects['zone'] and selected_objects['zone'].name == 'Main Story' then
			update_results(generate_key_items_table('ABYSSITE (misc)', aby_data.abyssite_non_area_specific))
			return
		end
		if selected_objects['zone'] then
			local zone_id = selected_objects['zone'].zone_id
			if not aby_data.abyssite[zone_id] then print('ah error: no abyssite data found for this area') return end
			update_results(generate_key_items_table('ABYSSITE (%s)':format(zones[zone_id].name), aby_data.abyssite[zone_id]))
		end
		return
	end

	-- Procs
	if selected_objects['menu'].name == 'Procs' then
		if selected_objects['proc_color'] then
			local results_string = ''
			local my_weapon_skills = T(windower.ffxi.get_abilities().weapon_skills)
			hide_sub_menu('days')

			-- Red Procs
			if selected_objects['proc_color'].name == 'Red' then
				local title = 'RED PROCS'
				results_string = '%s\n%s\n%s %s     %s\n':format(title, '':rpad('-', title:length()), 'ELEMENT':rpad(' ', 10), 'WEAPON':rpad(' ', 15), 'WS')
				
				for procs in aby_data.red_procs:it() do
					local have_it = '[ ]'
					if my_weapon_skills:contains(procs.ws) then
						have_it = '[X]'
					end
					results_string = results_string:append('%s %s %s %s\n':format(procs.element:rpad(' ', 10), procs.weapon:rpad(' ', 15), have_it, weapon_skills[procs.ws].name))
				end
				
				update_results(results_string:trim())
				return
			end
			-- Yellow Procs
			if selected_objects['proc_color'].name == 'Yellow' then
				local today = windower.ffxi.get_info().day
				local now = windower.ffxi.get_info().time
				local player = windower.ffxi.get_player()
				local my_spells = windower.ffxi.get_spells()
				
				show_sub_menu('days')
				if not selected_objects['day'] then
					auto_select_day(days[today].name)
				end
				local title = 'YELLOW PROCS (Current date/time is %s %02d:%02d)':format(selected_objects['day'].name, now / 60, now % 60)
				results_string = '%s\n%s\n    %s\n':format(title, '':rpad('-', title:length()), 'SPELL')
				for spell in aby_data.yellow_procs[selected_objects['day'].day_id]:it() do
					local have_it = '[ ]'
					if can_cast_spell(spell, my_spells, player) then
						have_it = '[X]'
					end
					results_string = results_string:append("%s %s\n":format(have_it, spells[spell].name))	
				end
				update_results(results_string:trim())
				return
			end
			-- Blue  Procs
			if selected_objects['proc_color'].name == 'Blue' then
				local now = windower.ffxi.get_info().time
				local my_weapon_skills = T(windower.ffxi.get_abilities().weapon_skills)
				results_string = 'BLUE PROCS (Current time is %02d:%02d)':format(now / 60, now % 60)
				results_string = '%s\n%s\n\n':format(results_string, '':rpad('-', results_string:length()))

				for dmg_type, _ in pairs(aby_data.blue_procs) do
					local start_time = aby_data.blue_procs[dmg_type]['time']['start']
					local end_time = aby_data.blue_procs[dmg_type]['time']['end']
					local selection_time = '  '
					if within_time_range(now, start_time, end_time) then
						selection_time = '->'
					end
					local title = '%s%s damage (%02d:00-%02d:00)':format(selection_time, dmg_type, start_time, end_time)
					title = '%s\n  %s\n  %s%s\n':format(title, '':rpad('-', title:length()-2), 'WEAPON':rpad(' ', 14), 'WEAPON SKILLS')
					results_string = results_string:append(title)

					for weapon, weapon_list in pairs(aby_data.blue_procs[dmg_type]['weapons']) do
						results_string = results_string:append('  %s':format(weapon:rpad(' ', 14)))
						for ws in weapon_list:it() do
							local have_it = '[ ]'
							if my_weapon_skills:contains(ws) then
								have_it = '[X]'
							end
							results_string = results_string:append('%s %s':format(have_it, weapon_skills[ws].name:rpad(' ', 16)))
						end
						results_string = results_string:append('\n')
					end
					results_string = results_string:append('\n')
				end
				update_results(results_string:trim())
				return
			end
		end
		return
	end
	
	-- Pop Items
	if selected_objects['menu'].name == 'Pop Items' then
		if not selected_objects['zone'] then auto_select_zone() end

		if selected_objects['zone'] then
			show_area_pop_chart(selected_objects['zone'].zone_id)
			current_zone_pop_chart = selected_objects['zone'].zone_id
		end
		return
	end
	-- +1
	if selected_objects['menu'].name == '+1' then
		if not selected_objects['job'] then auto_select_job() end

		if selected_objects['job'] and selected_objects['slot'] then
			local job = selected_objects['job'].name
			local slot = selected_objects['slot'].name
			update_results(generate_upgrade_items_table('+1', job, slot, aby_data.plus_one[job][slot]))
		end
		return
	end
	-- +2
	if selected_objects['menu'].name == '+2' then
		if not selected_objects['job'] then auto_select_job() end

		if selected_objects['job'] and selected_objects['slot'] then
			local job = selected_objects['job'].name
			local slot = selected_objects['slot'].name
			local item_id = aby_data.plus_two[job][slot].id
			local data_table = aby_data.plus_two[job][slot]
			data_table.locs = aby_data.plus_two['locs'][item_id]
			update_results(generate_upgrade_items_table('+2', job, slot, data_table))
		end
		return
	end
end


---- MOUSE EVENTS
function handle_mouse(eventtype, x, y, delta, blocked)
    if blocked then return end

    -- mouse move event
    if eventtype == 0 then
        for _, obj in pairs(interactive_objects) do
	        if obj.text:hover(x, y) then
        		obj.hover_on()
        	else
        		obj.hover_off()
        	end
        end
    end

    -- left click down event
    if eventtype == 1 then
       for _, obj in pairs(interactive_objects) do
	        if obj.text:hover(x, y) then
	        	-- ignore if already selected
	        	if not obj.selected then
	        		-- unselect objs of same type
			    	for _, i in pairs(interactive_objects) do
    					if i.type == obj.type and i.selected then
    						i.unselect()
    					end
    				end
    				if obj.left_click_down then
		        		obj.left_click_down()
		        	end
    	    		obj.select()
    	    		selected_objects[obj.type] = obj
    	    		process_selections()
    	    	end
        		return true
        	end
       end
    end
    -- left click up event
    if eventtype == 2 then
       for _, obj in pairs(interactive_objects) do
	        if obj.text:hover(x, y) then
    			if obj.left_click_up then
		        	obj.left_click_up()
		        end
        	return true
        	end
       end
    end    
	-- ignore rest
    return false
end


function incoming_packets(id, original, modified, injected, blocked)
	-- Ability List or Spell list has changed
	if id == 0xAA or id == 0xAC then
		if selected_objects['menu'] and selected_objects['menu'].name == 'Procs' then
			process_selections()
		end
	end
	if id == 0x2a then
		local p = packets.parse ('incoming', original)
		-- Yellow proc hint
		if p['Message ID'] == 40088 then
			-- element = param1 -1
			send_to_output('YELLOW PROC: %s element':format(elements[p['Param 1'] - 1].name))
			return
		end
		-- Blue proc hint
		if p['Message ID'] == 40089 then
			-- skill = param1
			send_to_output('BLUE PROC: %s skill':format(skills[p['Param 1']].name))
			return
		end
		if p['Message ID'] == 40090 then
			send_to_output('RED PROC: %s element':format(elements[p['Param 1'] - 1].name))
			return
		end
	end
end

function target_change(index)
	if index > 0 then
		target = windower.ffxi.get_mob_by_index(index)
	else
		target = nil
		target_object.text.msg = ''
	end
end

function action(act)
	if act.actor_id == player_id or not target then
		return
	end

	if target and act.actor_id == target.id then
		local action_msg = nil
		if act.category == 7 then
			-- special move
			action_msg = 'Target doing a special move'
		elseif act.category == 8 and act.param ~= 28787 then
			action_msg = 'Target casting a spell'
		elseif act.category == 12 then
			action_msg = 'Target beginning a range attack'
		end
		if action_msg then
			target_object.text.msg = action_msg
		else
			target_object.text.msg = ''
		end
	end
end

-- Register callbacks
windower.register_event('day change', process_selections)
windower.register_event('load', load_defaults)
windower.register_event('logout', exit_addon)
windower.register_event('mouse', handle_mouse)
windower.register_event('incoming chunk', incoming_packets)
windower.register_event('target change', target_change)
windower.register_event('action', action)