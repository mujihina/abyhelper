
local menu_defaults = {
	pos = {},
	text = {
		font = 'Consolas',
		size = 18,
		alpha = 255,
		red = 255,
		green =255,
		blue = 255,
		padding = 5,
	},
	bg = {
		alpha = 200,
		red = 0,
		green =20,
		blue = 200,
		visible = false,
	},
	flags = { 
		draggable = false,
		bold = true,
		italic = true,
		},
}


local sub_menu_defaults = {
	pos = {},
	text = {
		font = 'Consolas',
		size = 13,
		alpha = 255,
		red = 255,
		green =255,
		blue = 255,
		padding = 5,
	},
	bg = {
		alpha = 100,
		red = 0,
		green =20,
		blue = 200,
		visible = true,
	},
	flags = { 
		draggable = false,
		bold = false,
		italic = false,
		},
}

local result_defaults = {
	pos = {},
	text = {
		font = 'Consolas',
		size = 12,
		alpha = 255,
		red = 255,
		green = 255,
		blue = 255,
		padding = 5,
	},
	bg = {
		alpha = 100,
		red = 0,
		green = 0,
		blue = 0,
		visible = true,
	},
	flags = { 
		draggable = true,
		bold = false,
		italic = false,
		},
}

local target_defaults = {
	pos = {},
	text = {
		font = 'Arial',
		size = 14,
		alpha = 255,
		red = 255,
		green = 0,
		blue = 0,
		padding = 5,
	},
	bg = {
		alpha = 100,
		red = 0,
		green = 0,
		blue = 0,
		visible = true,
	},
	flags = { 
		draggable = true,
		bold = false,
		italic = false,
		},
}

local title_defaults = {
	pos = {},
	text = {
		font = 'Consolas',
		size = 15,
		alpha = 255,
		red = 255,
		green =255,
		blue = 255,
		padding = 5,
	},
	bg = {
		alpha = 100,
		red = 0,
		green =20,
		blue = 200,
		visible = false,
	},
	flags = { 
		draggable = false,
		bold = true,
		italic = false,
		},
}

local pop_entry_defaults = {
	pos = { x = 100, y = 100},
	text = {
		font = 'Consolas',
		size = 10,
		alpha = 255,
		red = 255,
		green = 255,
		blue = 255,
		padding = 10,
	},
	bg = {
		alpha = 150,
		red = 0,
		green = 0,
		blue = 0,
		visible = true,
	},
	flags = { 
		draggable = false,
		bold = false,
		italic = false,
		},
}

local pop_color_defaults = {
	pos = { },
	text = {
		font = 'Consolas',
		size = 10,
		alpha = 255,
		red = 255,
		green = 0,
		blue = 0,
		padding = 0,
	},
	bg = {
		alpha = 150,
		red = 255,
		green = 0,
		blue = 0,
		visible = true,
	},
	flags = { 
		draggable = false,
		bold = false,
		italic = false,
		},
}

local button_defaults = {
	pos = {},
	text = {
		font = 'Consolas',
		size = 16,
		alpha = 255,
		red = 0,
		green = 20,
		blue = 200,
		padding = 5,
	},
	bg = {
		alpha = 200,
		red = 255,
		green = 255,
		blue = 255,
		visible = false,
	},
	flags = { 
		draggable = false,
		bold = true,
		italic = false,
		},
}

function new_menu(label, x, y, menu_type)
    local this = {}
    this.name = label:trim()
    this.selected = false
    this.type = menu_type

	if menu_type == 'menu' then
		settings = menu_defaults
	else
		settings = sub_menu_defaults
	end
    settings.pos.x = x
    settings.pos.y = y
    this.text = texts.new("${select_string|'  '}${name|''}", settings)
    this.text.name = label
	this.destroy = function() texts.destroy(this.text) end
    this.text.select_string = '  '
    this.select = function() 
    	this.text.select_string = '->'
    	this.selected = true
     end
    this.unselect = function()
    	this.text.select_string = '  '
    	this.selected = false
    	this.hover_off()
    end
	if menu_type == 'menu' then
		this.hover_on = function() if not this.selected then this.text:bg_visible(true) end end
		this.hover_off = function() if not this.selected then this.text:bg_visible(false) end end
		this.text:show()
	else
		this.hover_on = function() if not this.selected then this.text:bg_alpha(255) end end
		this.hover_off = function() if not this.selected then this.text:bg_alpha(100) end end	
	end    
	return this
end


function new_results(x, y)
	settings = result_defaults
    settings.pos.x = x
    settings.pos.y = y
    local this = {}
    this.text = texts.new('${data|}', settings)
    this.text.data = nil
	this.destroy = function() texts.destroy(this.text) end
	this.type = 'results'
	this.text:show()
	return this
end

function new_target(x, y)
	settings = target_defaults
    settings.pos.x = x
    settings.pos.y = y
    local this = {}
    this.text = texts.new('${msg|}', settings)
	this.destroy = function() texts.destroy(this.text) end
	this.type = 'target'
	this.text:show()
	return this
end

function new_button(label, x, y, button_type)
	settings = button_defaults
    settings.pos.x = x
    settings.pos.y = y
    local this = {}
    this.text = texts.new(label, settings)
    this.name = label
	this.destroy = function() texts.destroy(this.text) end
	this.type = button_type
	 this.select = function() end
	this.hover_on = function() this.text:bg_visible(true) end
	this.hover_off = function() this.text:bg_visible(false) end
	return this
end

function new_title(label, x, y)
	settings = title_defaults
    settings.pos.x = x
    settings.pos.y = y
    local this = {}
    this.text = texts.new(label, settings)
	this.destroy = function() texts.destroy(this.text) end
	this.type = 'title'
	return this
end

function new_pop_entry(data, x, y)
	settings = pop_entry_defaults
    settings.pos.x = x
    settings.pos.y = y
    local this = {}
	this.text = texts.new(data, settings)
	this.destroy = function() texts.destroy(this.text) end
	this.type = 'pop_entry'
	return this
end

function new_pop_color(lines, x, y)
	settings = pop_color_defaults
    settings.pos.x = x
    settings.pos.y = y
    local this = {}
    local content = ' '
    if lines > 2 then
    	lines = lines - 1
    end
	content = content:append('':rpad('\n', lines))
    this.text = texts.new(content, settings)
    this.green = function()
    	this.text:bg_color(0,255,0)
    	this.text:show()
    	end
    this.red = function()
    	this.text:bg_color(255,0,0)
    	this.text:show()
    	end
	this.destroy = function() texts.destroy(this.text) end
	this.type = 'pop_color'
	return this
end