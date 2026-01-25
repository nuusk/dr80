:-- title:   game title
-- author:  game developer, email, etc.
-- desc:    short description
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  lua
math.randomseed(tstamp())

function table.deep_copy(orig, copies)
	if type(orig) ~= "table" then
		return orig
	end

	copies = copies or {}
	if copies[orig] then
		return copies[orig]
	end

	local copy = {}
	copies[orig] = copy

	for k, v in pairs(orig) do
		local new_k = (type(k) == "table") and table.deep_copy(k, copies) or k
		local new_v = (type(v) == "table") and table.deep_copy(v, copies) or v
		copy[new_k] = new_v
	end

	return copy
end

local Screen = {
	height = 136,
	width = 240,
}

Console = {
	open = false,
	lines = {},
	max = 220,
	scroll = 0,
	actions = {},
	action_keys = { 4, 5, 6, 7 },
	action_labels = {},
}

function Console.toggle()
	Console.open = not Console.open
end

function Console.log(msg)
	trace(msg)
	local t = tstamp()

	local hours = math.floor(t / 3600) % 24
	local minutes = math.floor(t / 60) % 60
	local seconds = math.floor(t) % 60
	local s = string.format("[%02d:%02d:%02d] %s", hours, minutes, seconds, tostring(msg))

	table.insert(Console.lines, s)
	if #Console.lines > Console.max then
		table.remove(Console.lines, 1)
	end
end

function Console.clear()
	Console.lines = {}
end

function Console.update()
	if btnp(7) then
		Console.toggle()
	end
	if not Console.open then
		return
	end
	if btnp(2) then
		Console.scroll = math.min(Console.scroll + 1, math.max(0, #Console.lines - 1))
	end
	if btnp(3) then
		Console.scroll = math.max(Console.scroll - 1, 0)
	end
end

function Console.draw()
	if not Console.open then
		return
	end
	local w, h = 140, 120
	local x, y = 100, 0
	rect(x, y, w, h, 0)
	rectb(x, y, w, h, 13)
	local visible = 20
	local start = math.max(1, #Console.lines - visible - Console.scroll + 1)
	local idx = 0
	for i = start, math.min(#Console.lines, start + visible - 1) do
		print(Console.lines[i], x + 4, y + 4 + idx * 8, 12, false, 1, true)
		idx = idx + 1
	end
end

-- Global variables --

local SFX = {
	DROP = 0,
	MOVE = 1,
	ROTATE = 2,
	CLEAR = 3,
	OVERFLOW = 4,
	INVALID = 5,
}

local TRACK = {
	FLORA = 0,
	FEVER = 1,
}

-- Global variables end --

local SCENES = {
	MENU = 0,
	PARAMS = 1,
	GAME = 2,
}

local MODES = {
	VS = 0,
}

local Game = {
	scene = SCENES.MENU,
	mode = MODES.VS,
	grids = {},
	players = 1,
}

-- Audio manager --

local Audio = {
	bgm = nil,
	reserved = {
		sfx = 3,
		bgm = { 0, 1, 2 },
	},
	chords = {
		happy = { "C-4", "D-4", "E-4", "G-4" },
		arcade = { "E-3", "G-3", "A-3", "C-4" },
	},
}

function Audio.playBGM(track, loop)
	if Audio.bgm == track then
		return
	end
	music(track, 0, 0, loop ~= false)
	Audio.bgm = track
end

function Audio.stopBGM()
	music(-1)
	Audio.bgm = nil
end

function Audio.play(id, speed, note)
	sfx(id, note, -1, Audio.reserved.sfx, 15, speed or 0, false)
end

function Audio.generate_note(combo, character)
	-- change chord based on character
	return Audio.chords.arcade[math.min(combo, 4)]
end

-- Audio manager end --

-- Pill manager --

local RUNES = {
	{ name = "R", W = 490, E = 491, N = 492, S = 508 },
	{ name = "S", W = 506, E = 507, N = 493, S = 509 },
	{ name = "E", W = 488, E = 489, N = 494, S = 510 },
}

local Runes = {}

function Runes.gen_binding_rune()
	local rune1 = RUNES[math.random(1, #RUNES)]
	local rune2 = RUNES[math.random(1, #RUNES)]
	return { rune1 = rune1, rune2 = rune2 }
end

-- Pill manager end --

-- Keymap start --

local KEYMAP_P1 = {
	UP = 0,
	DOWN = 1,
	LEFT = 2,
	RIGHT = 3,
	B = 4,
	A = 5,
	PAUSE = 6,
	SUPER = 7,
}

local KEYMAP_P2 = {
	UP = 8,
	DOWN = 9,
	LEFT = 10,
	RIGHT = 11,
	B = 12,
	A = 13,
	PAUSE = 14,
	SUPER = 15,
}

local KEYMAP_P3 = {
	UP = 16,
	DOWN = 17,
	LEFT = 18,
	RIGHT = 19,
	B = 20,
	A = 21,
	PAUSE = 22,
	SUPER = 23,
}

local KEYMAP_P4 = {
	UP = 24,
	DOWN = 25,
	LEFT = 26,
	RIGHT = 27,
	B = 28,
	A = 29,
	PAUSE = 30,
	SUPER = 31,
}

local KEYS = {
	KEYMAP_P1,
	KEYMAP_P2,
	KEYMAP_P3,
	KEYMAP_P4,
}

-- Keymap end --

-- Grid manager --

local BORDER = {
	TOPLEFT = 32,
	TOP = 33,
	TOPRIGHT = 34,
	LEFT = 48,
	CENTER = 49,
	RIGHT = 50,
	BOTTOMLEFT = 64,
	BOTTOM = 65,
	BOTTOMRIGHT = 66,
}

local BACKGROUND = {
	SINGLE = 503,
	SQUARE_2x2 = 452,
}

local Grid = {
	cell_size = 8,
	level = 9,
	num_stones = 0,
	next_binding = nil,
	static_bindings = {},
	active_binding = nil,
	halves = {},
	drop_phase = false,
	board = {},
	interval = 60,
	is_paused = false,
	character = nil,
	combo = 0,
}
Grid.__index = Grid

function Grid:new(player)
	local g = setmetatable({}, Grid)

	g.player = player
	g.h = Game.assign_grid_height()
	g.w = Game.assign_grid_width()
	g.py = Game.assign_py()
	if Game.players <= 2 then
		g.px = (player - 1) * (g.w + 4) + 1
		g.next_binding_x = g.w + 1
		g.next_binding_y = 0
		g.character_x = g.w + 1
		g.character_y = g.h - 4
		g.score_x = g.w + 1
		g.score_y = g.h
	else
		g.px = (player - 1) * (g.w + 1) + 1
		g.next_binding_x = g.w - 3
		g.next_binding_y = -3
		g.character_x = g.w - 1
		g.character_y = -4
		g.score_x = 0
		g.score_y = -2
	end

	g.interval = Grid.interval
	g.stones = Grid.stones

	g.static_bindings = {}
	g.active_binding = nil
	g.halves = {}
	g.drop_phase = false
	g.board = {}
	g.is_paused = false
	g.character = nil
	g.next_binding = nil

	g:generate_board()
	g:generate_stones(5)
	g:generate_character(1)

	return g
end

local STONES = {
	{ name = "R", spr = 256 },
	{ name = "S", spr = 272 },
	{ name = "E", spr = 288 },
}

local STONES_SPR = {
	R = 256,
	S = 272,
	E = 288,
}

local HALVES_SPR = {
	R = 486,
	S = 487,
	E = 502,
}

local CHAR_1_ANIMATION_IDLE = {
	400,
	402,
	404,
	406,
	408,
}

function Grid:effective_interval()
	if btn(KEYMAP_P1.DOWN) then
		return self.interval / 10
	end
	return self.interval
end

function Grid:generate_board()
	for y = 0, self.h - 1, 1 do
		self.board[y] = {}
		for x = 0, self.w - 1, 1 do
			self.board[y][x] = nil
		end
	end
end

function Grid:generate_character(index)
	if index == 1 then
		self.character = {
			name = "ruby",
			state = "idle",
			anim_idle = {
				sprites = CHAR_1_ANIMATION_IDLE,
				cur = 0,
			},
			w = 2,
			h = 3,
		}
	end
end

function Grid:draw_level()
	print("LEVEL", self:cx(1), self:cy(1), 8, true)
	print(self.level, self:cx(self.w - 2) + 4, self:cy(1), 8, true)

	rectb(self:cx(1), self:cy(2), 8, 8, 1)
end

function Grid:draw_score()
	local cx = self:cx(self.score_x)
	local cy = self:cy(self.score_y - 1)

	spr(BACKGROUND.SQUARE_2x2, cx, cy, 0, 1, 0, 0, 2, 2)

	local offset = 5
	if self.num_stones >= 10 then
		offset = 2
	end
	print(self.num_stones, self:cx(self.score_x) + offset, self:cy(self.score_y) - (Grid.cell_size // 4), 8, true)
end

function Grid:draw_character(t)
	local char = self.character
	if char == nil then
		Console.log("ERROR: character is nil, fix the code")
		return
	end

	local cx = self:cx(self.character_x)
	local cy = self:cy(self.character_y)

	local i = (t // 8) % #char.anim_idle.sprites + 1
	local frame = char.anim_idle.sprites[i]
	if char.state == "idle" then
		spr(frame, cx, cy, 0, 1, 0, 0, char.w, char.h)
	end
end

function Grid:generate_stones(level)
	local presets = {
		[1] = { n = 3, safe = 0.55 },
		[2] = { n = 5, safe = 0.50 },
		[3] = { n = 8, safe = 0.45 },
		[4] = { n = 12, safe = 0.40 },
		[5] = { n = 17, safe = 0.35 },
		[6] = { n = 23, safe = 0.30 },
		[7] = { n = 30, safe = 0.25 },
		[8] = { n = 38, safe = 0.20 },
		[9] = { n = 47, safe = 0.15 },
		[10] = { n = 57, safe = 0.10 },
	}
	local preset = presets[level]
	if not preset then
		Console.log("level too high")
		return {}
	end

	local h_start = math.floor(preset.safe * self.h)
	local bag = {}

	for ly = h_start, self.h - 1, 1 do
		for lx = 0, self.w - 1, 1 do
			table.insert(bag, { x = lx, y = ly })
		end
	end

	for i = 1, preset.n, 1 do
		local rand_num = math.random(#bag)
		local rand_pos = bag[rand_num]
		local color = "R"
		if i % 3 == 0 then
			color = "S"
		elseif i % 3 == 1 then
			color = "E"
		end
		table.remove(bag, rand_num)
		self.board[rand_pos.y][rand_pos.x] = {
			type = "stone",
			spr = STONES_SPR[color],
			color = color,
		}
	end

	self.num_stones = preset.n
end

function Grid:count_stones()
	local count = 0
	for y = 0, self.h - 1, 1 do
		for x = 0, self.w - 1, 1 do
			if self.board[y][x] ~= nil and self.board[y][x].type == "stone" then
				count = count + 1
			end
		end
	end

	self.num_stones = count
end

function Grid:increment_combo(inc)
	if inc == nil then
		self.combo = self.combo + 1
	else
		self.combo = self.combo + inc
	end
	local note = Audio.generate_note(self.combo, self.character.name)
	Audio.play(SFX.CLEAR, -2, note)
end

function Grid:reset_combo()
	-- self.combo = 0
end

function Grid:draw_board()
	for y = 0, self.h - 1, 1 do
		for x = 0, self.w - 1, 1 do
			if self.board[y][x] ~= nil then
				local cx = self:cx(x)
				local cy = self:cy(y)
				spr(self.board[y][x].spr, cx, cy, 0)
			end
		end
	end
end

function Grid:gen_next_binding()
	local binding = Runes.gen_binding_rune()

	self.next_binding = {
		rune1 = binding.rune1,
		rune2 = binding.rune2,
		x = self.next_binding_x,
		y = self.next_binding_y,
		rotation = 0,
	}
end

function Grid:draw_next_binding()
	local next = self.next_binding
	if not next then
		return
	end

	local x1, y1, x2, y2 = self:get_binding_xy(next)
	local spr1, spr2 = self:get_binding_spr(next)

	spr(spr1, self:cx(x1), self:cy(y1), 0)
	spr(spr2, self:cx(x2), self:cy(y2), 0)
end

function Grid:spawn_binding(binding)
	local spawnx = 0
	if self.w % 2 == 0 then
		spawnx = self.w / 2 - 1
	else
		spawnx = (self.w - 1) / 2
	end
	local spawny = 0

	self.active_binding = {
		rune1 = binding.rune1,
		rune2 = binding.rune2,
		x = spawnx,
		y = spawny,
		rotation = 0,
	}
end

function Grid:rotate_clockwise()
	if self.active_binding == nil then
		Console.log("error rotating binding - no active binding in game")
		return
	end

	local next_rotation = (self.active_binding.rotation + 1) % 4
	local x1, y1, x2, y2 = self:get_binding_xy(self.active_binding, next_rotation)
	if self:available(x1, y1) and self:available(x2, y2) then
		self.active_binding.rotation = next_rotation
	else
		Audio.play(SFX.INVALID)
	end
end

function Grid:rotate_counterclockwise()
	if self.active_binding == nil then
		Console.log("error rotating binding - no active binding in game")
		return
	end

	local next_rotation = (self.active_binding.rotation + 3) % 4
	local x1, y1, x2, y2 = self:get_binding_xy(self.active_binding, next_rotation)
	if self:available(x1, y1) and self:available(x2, y2) then
		self.active_binding.rotation = next_rotation
	else
		Audio.play(SFX.INVALID)
	end
end

function Grid:move_left()
	if self.active_binding == nil then
		Console.log("error moving binding left - no active binding in game")
		return
	end

	local x1, y1, x2, y2 = self:get_binding_xy()
	if self:available(x1 - 1, y1) and self:available(x2 - 1, y2) then
		self.active_binding.x = self.active_binding.x - 1
	else
		Audio.play(SFX.INVALID)
	end
end

function Grid:move_right()
	if self.active_binding == nil then
		Console.log("error moving binding right - no active binding in game")
		return
	end

	local x1, y1, x2, y2 = self:get_binding_xy()
	if self:available(x1 + 1, y1) and self:available(x2 + 1, y2) then
		self.active_binding.x = self.active_binding.x + 1
	else
		Audio.play(SFX.INVALID)
	end
end

-- instead of bunch of for loops, prepare a table / dictionary to quickly check availability
function Grid:available(x, y)
	if x < 0 or x > self.w - 1 then
		return false
	end

	if y < 0 then
		return true
	end

	if y >= self.h then
		return false
	end

	if self.board[y][x] == nil then
		return true
	end

	return false
end

function Grid:get_binding_xy(binding, rotation)
	binding = binding or self.active_binding
	rotation = rotation or binding.rotation
	if rotation == 0 then
		return binding.x, binding.y, binding.x + 1, binding.y
	elseif rotation == 1 then
		return binding.x, binding.y - 1, binding.x, binding.y
	elseif rotation == 2 then
		return binding.x + 1, binding.y, binding.x, binding.y
	elseif rotation == 3 then
		return binding.x, binding.y, binding.x, binding.y - 1
	end

	return nil, nil, nil, nil
end

function Grid:get_binding_spr(binding)
	binding = binding or self.active_binding
	if not binding then
		Console.log("error: binding not found")
		return
	end

	local rotation = (binding.rotation or 0) % 4
	local dir = {
		[0] = { "W", "E" },
		[1] = { "N", "S" },
		[2] = { "E", "W" },
		[3] = { "S", "N" },
	}
	local pair = dir[rotation]

	local spr1 = binding.rune1[pair[1]]
	local spr2 = binding.rune2[pair[2]]
	return spr1, spr2
end

function Grid:draw_static_bindings()
	for _, binding in ipairs(self.static_bindings) do
		if binding == nil then
			Console.log("static pill is nil")
			return
		end

		local x1, y1, x2, y2 = self:get_binding_xy(binding)
		local spr1, spr2 = self:get_binding_spr(binding)

		Console.log(x1)

		spr(spr1, x1 * self.cell_size, y1 * self.cell_size, 0)
		spr(spr2, x2 * self.cell_size, y2 * self.cell_size, 0)
	end
end

function Grid:draw_active_binding()
	if self.active_binding == nil then
		return
	end

	local x1, y1, x2, y2 = self:get_binding_xy()
	local spr1, spr2 = self:get_binding_spr()

	spr(spr1, self:cx(x1), self:cy(y1), 0)
	spr(spr2, self:cx(x2), self:cy(y2), 0)
end

function Grid:draw_halves()
	for _, half in ipairs(self.halves) do
		spr(half.spr, half.x * self.cell_size, half.y * self.cell_size, 0)
	end
end

function Grid:grav_halves()
	local still_falling = false
	local already_moved = {}

	for y = self.h - 1, 0, -1 do
		if already_moved[y] == nil then
			already_moved[y] = {}
		end
	end

	for y = self.h - 1, 0, -1 do
		for x = self.w - 1, 0, -1 do
			if already_moved[y][x] == true then
				goto continue
			end

			if self.board[y] ~= nil and self.board[y][x] ~= nil then
				Console.log(string.format("x: %d, y: %d, type: %s", x, y, self.board[y][x].type))

				if self.board[y][x].type == "half" then
					local half = self.board[y][x]
					if self:available(x, y + 1) then
						self.board[y + 1][x] = {
							type = "half",
							color = half.color,
							spr = half.spr,
						}
						self.board[y][x] = nil
						still_falling = true
					else
						-- Audio.play(SFX.DROP)
						self.board[y][x] = {
							type = "half",
							color = half.color,
							spr = half.spr,
						}
					end
				elseif self.board[y][x].type == "binding" then
					local binding = self.board[y][x]
					local oh_pos = binding.other_half
					local is_available_binding = self:available(x, y + 1)
					local is_available_oh = self:available(oh_pos.x, oh_pos.y + 1)

					if oh_pos.x == x then
						if is_available_binding then
							self.board[y + 1][x] = table.deep_copy(self.board[y][x])
							self.board[y + 1][x].other_half.y = oh_pos.y + 1
							self.board[oh_pos.y + 1][oh_pos.x] = table.deep_copy(self.board[oh_pos.y][oh_pos.x])
							self.board[oh_pos.y + 1][oh_pos.x].other_half.y = y + 1
							self.board[oh_pos.y][oh_pos.x] = nil
							already_moved[oh_pos.y][oh_pos.x] = true
						end
					elseif is_available_binding and is_available_oh then
						self.board[y + 1][x] = table.deep_copy(self.board[y][x])
						self.board[y + 1][x].other_half.y = oh_pos.y + 1
						self.board[y][x] = nil
						self.board[oh_pos.y + 1][oh_pos.x] = table.deep_copy(self.board[oh_pos.y][oh_pos.x])
						self.board[oh_pos.y + 1][oh_pos.x].other_half.y = y + 1
						self.board[oh_pos.y][oh_pos.x] = nil
						already_moved[oh_pos.y][oh_pos.x] = true
						still_falling = true
					else
						-- Audio.play(SFX.DROP)
					end
				end
			end

			::continue::
		end
	end

	return still_falling
end

function Grid:grav()
	local active = self.active_binding
	if active == nil then
		return
	end

	local x1, y1, x2, y2 = self:get_binding_xy()

	if self:available(x1, y1 + 1) and self:available(x2, y2 + 1) then
		active.y = active.y + 1
	else
		-- Audio.play(SFX.DROP)
		self:mark_active_binding_as_static()
	end
end

function Grid:mark_active_binding_as_static()
	if self.active_binding == nil then
		Console.log("cannot mark binding as static, active binding not found")
		return
	end

	local x1, y1, x2, y2 = self:get_binding_xy()
	local spr1, spr2 = self:get_binding_spr()
	self.board[y1][x1] = {
		type = "binding",
		color = self.active_binding.rune1.name,
		spr = spr1,
		other_half = {
			x = x2,
			y = y2,
		},
	}
	self.board[y2][x2] = {
		type = "binding",
		color = self.active_binding.rune2.name,
		spr = spr2,
		other_half = {
			x = x1,
			y = y1,
		},
	}

	self.active_binding = nil
end

function Grid:print()
	for y = 0, self.h - 1 do
		for x = 0, self.w - 1 do
			local color = "nil"
			local type = "nil"
			if self.board[y][x] ~= nil then
				color = self.board[y][x].color
				type = self.board[y][x].type

				format = string.format("[%d][%d]:(%s)%s", y, x, color, type)
				oh = self.board[y][x].other_half
				if oh then
					format = string.format("[%d][%d]:(%s)%s {oh y:%d,x:%d}", y, x, color, type, oh.y, oh.x)
				end

				Console.log(format)
			end
		end
	end
end

-- cx converts x position in the grid to x position on the screen
-- px is a reference to grid origin offset (in cells, not pixels)
function Grid:cx(x)
	return (x + self.px) * self.cell_size
end

-- cy converts y position in the grid to y position on the screen
-- py is a reference to grid origin offset (in cells, not pixels)
function Grid:cy(y)
	return (y + self.py) * self.cell_size
end

function Grid:draw_border()
	for y = 0, self.h + 1 do
		local cy = self:cy(y - 1)
		for x = 0, self.w + 1 do
			ok = false
			if y == 0 or y == self.h + 1 then
				ok = true
			end
			if x == 0 or x == self.w + 1 then
				ok = true
			end
			if ok == true then
				local cx = self:cx(x - 1)
				spr(BACKGROUND.SINGLE, cx, cy, 0)
			end
		end
	end

	-- around next pill
	-- spr(BACKGROUND.SINGLE, self:cx(self.next_binding_x), self:cy(self.next_binding_y + 1))
	-- spr(BACKGROUND.SINGLE, self:cx(self.next_binding_x + 1), self:cy(self.next_binding_y + 1))
	-- spr(BACKGROUND.SINGLE, self:cx(self.next_binding_x), self:cy(self.next_binding_y - 1))
	-- spr(BACKGROUND.SINGLE, self:cx(self.next_binding_x + 1), self:cy(self.next_binding_y - 1))
end

function Grid:draw_border_deprecated()
	for y = 0, self.h - 1 do
		local cy = self:cy(y)
		for x = 0, self.w - 1 do
			local cx = self:cx(x)

			if y == 0 then
				if x == 0 then
					spr(BORDER.TOPLEFT, cx, cy, 0)
				elseif x == self.w - 1 then
					spr(BORDER.TOPRIGHT, cx, cy, 0)
				else
					spr(BORDER.TOP, cx, cy, 0)
				end
			elseif y == self.h - 1 then
				if x == 0 then
					spr(BORDER.BOTTOMLEFT, cx, cy, 0)
				elseif x == self.w - 1 then
					spr(BORDER.BOTTOMRIGHT, cx, cy, 0)
				else
					spr(BORDER.BOTTOM, cx, cy, 0)
				end
			else
				if x == 0 then
					spr(BORDER.LEFT, cx, cy, 0)
				elseif x == self.w - 1 then
					spr(BORDER.RIGHT, cx, cy, 0)
				else
					spr(BORDER.CENTER, cx, cy, 0)
				end
			end
		end
	end
end

-- Grid manager end --

-- Game manager --

function Game.setup_game(players)
	Game.players = players

	for i = 1, players, 1 do
		local grid = Grid:new(i)
		table.insert(Game.grids, grid)
	end

	Game.scene = SCENES.GAME
end

function Game.update_grids()
	for _, grid in pairs(Game.grids) do
		grid:update()
	end
end

function Game.draw_grids()
	for _, grid in pairs(Game.grids) do
		grid:draw()
	end
end

function Game.update_params()
	for _, grid in pairs(Game.grids) do
		grid:update_params()
	end
end

function Game.draw_params()
	for _, grid in pairs(Game.grids) do
		grid:draw_params()
	end
end

function Game.assign_grid_height()
	-- when there are more than 2 players, grid is smaller and character is drawn on top
	if Game.players <= 2 then
		return 15
	end
	return 12
end

function Game.assign_py()
	-- when there are more than 2 players, grid is smaller and character is drawn on top
	if Game.players <= 2 then
		return 1
	end
	return 4
end

function Game.assign_grid_width()
	if Game.players == 1 then
		return 9
	elseif Game.players == 2 then
		return 11
	elseif Game.players == 3 then
		return 8
	elseif Game.players == 4 then
		return 6
	else
		Console.log("unexpected number of players during assign_grid_width")
	end
end

function Grid:eval()
	if self.drop_trigger == true then
		local halves_still_falling = self:grav_halves()
		self.drop_trigger = halves_still_falling

		if halves_still_falling == true then
			return
		end
	end

	self:count_x_rle()
	self:count_y_rle()
	local to_remove = self:remove_marked()
	if to_remove > 0 then
		self:increment_combo(to_remove)
		return
	else
		self:reset_combo()
	end

	if self.next_binding == nil then
		self:gen_next_binding()
	end

	if self.active_binding == nil then
		self:reset_combo()
		self:spawn_binding(self.next_binding)
		self.next_binding = nil
	else
		self:grav()
	end
end

function Grid:mark_to_remove_on_y(y, from, to)
	for x = from, to, 1 do
		if self.board[y] ~= nil and self.board[y][x] ~= nil then
			self.board[y][x].to_remove = true
		end
	end
end

function Grid:mark_to_remove_on_x(x, from, to)
	for y = from, to, 1 do
		if self.board[y] ~= nil and self.board[y][x] ~= nil then
			self.board[y][x].to_remove = true
		end
	end
end

function Grid:count_x_rle()
	for y = 0, self.h - 1, 1 do
		local acc = nil
		for x = 0, self.w - 1, 1 do
			if self.board[y][x] == nil then
				acc = nil
				goto continue
			end
			if acc == nil then
				acc = {
					color = self.board[y][x].color,
					count = 1,
				}
			elseif acc.color == self.board[y][x].color then
				acc.count = acc.count + 1
			else
				acc = {
					color = self.board[y][x].color,
					count = 1,
				}
			end

			if acc ~= nil and acc.count > 3 then
				self:mark_to_remove_on_y(y, x - acc.count + 1, x)
			end

			::continue::
		end
	end
end

function Grid:count_y_rle()
	for x = 0, self.w - 1, 1 do
		local acc = nil
		for y = 0, self.h - 1, 1 do
			if self.board[y][x] == nil then
				acc = nil
				goto continue
			end
			if acc == nil then
				acc = {
					color = self.board[y][x].color,
					count = 1,
				}
			elseif acc.color == self.board[y][x].color then
				acc.count = acc.count + 1
			else
				acc = {
					color = self.board[y][x].color,
					count = 1,
				}
			end

			if acc ~= nil and acc.count > 3 then
				self:mark_to_remove_on_x(x, y - acc.count + 1, y)
			end

			::continue::
		end
	end
end

function Grid:remove_marked()
	local board_copy = table.deep_copy(self.board)

	local to_remove_diff = {}
	local to_convert_diff = {}
	local oh_boy_we_gotta_remove_something = 0

	for y = self.h - 1, 0, -1 do
		for x = self.w - 1, 0, -1 do
			if not board_copy[y] or not board_copy[y][x] then
				goto continue
			end

			if board_copy[y][x].to_remove then
				local oh = board_copy[y][x].other_half
				if oh and board_copy[oh.y] and board_copy[oh.y][oh.x] and not board_copy[oh.y][oh.x].to_remove then
					table.insert(to_convert_diff, oh)
				end

				table.insert(to_remove_diff, { x = x, y = y })

				oh_boy_we_gotta_remove_something = oh_boy_we_gotta_remove_something + 1
			end

			::continue::
		end
	end

	for _, pos in ipairs(to_convert_diff) do
		local cell = self.board[pos.y][pos.x]
		if cell then
			cell.type = "half"
			cell.spr = HALVES_SPR[cell.color]
		end
	end

	for _, pos in ipairs(to_remove_diff) do
		self.board[pos.y][pos.x] = nil
		local cx = self:cx(pos.x)
		local cy = self:cy(pos.y)
		spr(BORDER.CENTER, cx, cy, 0)
	end

	if oh_boy_we_gotta_remove_something > 0 then
		self.drop_trigger = true
		self:count_stones()
	end

	return oh_boy_we_gotta_remove_something
end

-- Game manager end --

t = 0

local Menu = {}
Menu.__index = Menu

function Menu:new(opts)
	local m = setmetatable({}, Menu)
	m.options_padding = opts.options_padding or 8
	m.selected_option = opts.selected_option or 1
	m.options = opts.options or {}
	m.on_back = opts.on_back
	return m
end

function Menu:print_item(txt, is_selected, y_offset)
	local width = print(txt, 0, -100)
	local x = Screen.width // 2 - width // 2
	local y = Screen.height // 2 + y_offset
	if is_selected then
		spr(456, 80, y - 2)
	end
	print(txt, x, y, 8, true)
end

function Menu:get_offset(i)
	local center_index = (#self.options + 1) // 2
	return (i - center_index) * self.options_padding
end

function Menu:draw()
	for i, option in ipairs(self.options) do
		self:print_item(option.key, i == self.selected_option, self:get_offset(i))
	end
end

function Menu:up()
	if self.selected_option > 1 then
		self.selected_option = self.selected_option - 1
	end
end

function Menu:down()
	if self.selected_option < #self.options then
		self.selected_option = self.selected_option + 1
	end
end

function Menu:confirm()
	local opt = self.options[self.selected_option]
	if opt and opt.callback then
		opt.callback()
	end
end

function Menu:update()
	if btnp(KEYMAP_P1.UP) then
		self:up()
	elseif btnp(KEYMAP_P1.DOWN) then
		self:down()
	end

	if btnp(KEYMAP_P1.A) then
		self:confirm()
	end
	if btnp(KEYMAP_P1.B) and self.on_back then
		self.on_back()
	end
end

function setup_player_keys(player_index)
	print(KEYS[player_index])
end

local main_menu
local players_menu

players_menu = Menu:new({
	options = {
		{
			key = "2 PLAYERS",
			callback = function()
				Game.setup_game(2)
			end,
		},
		{
			key = "3 PLAYERS",
			callback = function()
				Game.setup_game(3)
			end,
		},
		{
			key = "4 PLAYERS",
			callback = function()
				Game.setup_game(4)
			end,
		},
		{
			key = "BACK",
			callback = function()
				Game.menu = main_menu
			end,
		},
	},
})

main_menu = Menu:new({
	options = {
		{
			key = "VS GAME",
			callback = function()
				Game.menu = players_menu
				Game.mode = MODES.VS
			end,
		},
	},
})

Game.menu = main_menu

function Grid:update()
	local keys = KEYS[self.player]
	if btnp(keys.A) then
		self:rotate_clockwise()
	end
	if btnp(keys.B) then
		self:rotate_counterclockwise()
	end
	if btnp(keys.LEFT) then
		self:move_left()
	end
	if btnp(keys.RIGHT) then
		self:move_right()
	end
	if btnp(keys.PAUSE) then
		-- implement pause
	end

	if t % self:effective_interval() == 0 then
		if self.is_paused ~= true then
			self:eval()
		end
	end
end

-- btnp repeat helper
local REPEAT_DELAY = 20
local REPEAT_RATE = 6
local hold = {}

function btnp_repeat(b)
	if btnp(b) then
		hold[b] = 0
		return true
	end

	if btn(b) then
		hold[b] = (hold[b] or 0) + 1

		if hold[b] > REPEAT_DELAY and (hold[b] - REPEAT_DELAY) % REPEAT_RATE == 0 then
			return true
		end
	else
		hold[b] = nil
	end

	return false
end

function Grid:update_params()
	local keys = KEYS[self.player]
	if btnp(keys.UP) then
		self:param_up()
	end
	if btnp(keys.DOWN) then
		self:param_down()
	end
	if btnp_repeat(keys.LEFT) then
		if self.level > 1 then
			self.level = self.level - 1
		end
	end
	if btnp_repeat(keys.RIGHT) then
		if self.level < 9 then
			self.level = self.level + 1
		end
	end
end

function Grid:draw_params()
	self:draw_border()
	self:draw_character(t)
	self:draw_score()
	self:draw_level()
end

function Grid:draw()
	self:draw_border()
	self:draw_board()
	self:draw_static_bindings()
	self:draw_active_binding()
	self:draw_halves()
	self:draw_character(t)
	self:draw_score()
	self:draw_next_binding()
end

function TIC()
	-- Audio.playBGM(TRACK.FLORA)
	Console.update()
	cls(0)

	if Game.scene == SCENES.MENU then
		Game.menu:update()
		Game.menu:draw()
	elseif Game.scene == SCENES.PARAMS then
		Game.update_params()
		Game.draw_params()
	elseif Game.scene == SCENES.GAME then
		Game.update_grids()
		Game.draw_grids()
	end

	t = t + 1
	Console.draw()
end

-- <TILES>
-- 001:ccccccce888888ccaaaaaaac888888acccccccacccc0ccacccc0ccacccc0ccac
-- 002:ccccceee8888cceeaaaa0cee888a0ceeccca0ccc0cca0c0c0cca0c0c0cca0c0c
-- 003:eccccccccc888888caaaaaaaca888888cacccccccacccccccacc0ccccacc0ccc
-- 004:ccccceee8888cceeaaaa0cee888a0ceeccca0cccccca0c0c0cca0c0c0cca0c0c
-- 017:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 018:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- 019:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 020:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- </TILES>

-- <SPRITES>
-- 000:00ccccc00cc332cccc23232cc223232cc223322cc123232ccc1311cc0cccccc0
-- 001:00ccccc00cc33dcccc23232cc223232cc223322cc123232ccc1311cc0cccccc0
-- 002:00ccccc00cc33dcccce3e3dcc22323ecc223322cc123232ccc1311cc0cccccc0
-- 003:00ccccc00cc33dcccce3e3dccee3e3ecc22332ecc122232ccc1211cc0cccccc0
-- 004:00ccccc00cc33dcccce3e3dccee2e2ecc2e22eecc122e2eccc1211cc0cccccc0
-- 005:00ccccc00cc33dcccce2e2dccee2e2ecc2e22eecc122e2eccc1211cc0cccccc0
-- 006:00ccccc00cc22dcccce2e2dccee2e2eccee22eeccfe2e2ecccf2ffcc0cccccc0
-- 016:0ccccc00cc665cc0c66566ccc655556cc766566cc775666ccc5777cc0cccccc0
-- 017:0ccccc00cced5cc0c665eeccc655556cc766566cc775666ccc5777cc0cccccc0
-- 018:0ccccc00cced5cc0cee5eeccc65555ecc766566cc775666ccc5777cc0cccccc0
-- 019:0ccccc00cced5cc0cee5eeccce5555ecc7ee5eecc775666ccc6777cc0cccccc0
-- 020:0ccccc00cced5cc0cee5eeccce5555ecceee6eecc7e6eeeccc6777cc0cccccc0
-- 021:0ccccc00cced5cc0cee5eeccce6666ecceee6eeccfe6eeeccc6fffcc0cccccc0
-- 022:0ccccc00cced6cc0cee6eeccce6666ecceee6eeccff6eeeccc6fffcc0cccccc0
-- 032:0ccccc00ccabacc0caabbacccaababaccbabaabcc9bbaaaccc9b99cc0cccccc0
-- 033:0ccccc00ccabdcc0caabbecccaababaccbabaabcc9bbaaaccc9b99cc0cccccc0
-- 034:0ccccc00ccebdcc0caabbecccaabebeccbabaabcc9bbaaaccc9b99cc0cccccc0
-- 035:0ccccc00ccebdcc0ceebbdcccaabebeccbabeebcc9bbaaeccc9b99cc0cccccc0
-- 036:0ccccc00ccebdcc0ceebbeccceebebeccaeaeebcc9aaeeeccc9a99cc0cccccc0
-- 037:0ccccc00ccebdcc0ceeabeccceeaebeccaeaeeaccfaaeeecccfaffcc0cccccc0
-- 038:0ccccc00cceadcc0ceeaaeccceeaeaeccaeaeeaccfaaeeecccfaffcc0cccccc0
-- 048:0000cccc000c112100c112120c11255100cc5c55000c5a55000c55550000cccc
-- 049:ccccc00022222c00122222c0212222c0c52222c0a55152c0555cccc0ccc00000
-- 050:0000cccc000c447400c447470c44745700c45c5500c4565500c455550c47cccc
-- 051:ccccc00077757c00477757c0747777c0c57777c0655a57c05554ccc0ccc70000
-- 052:000000cc00000c770000c747000cc47400cc474700c4cccc0ccc5c550c4c5255
-- 053:ccccccc077777cc0777777cc7777c77c4777cc7cccc777c0c5ccc77c2551cc7c
-- 054:00000ccc000ccccc00cccc930c4777930c44ccccc4cc5c550cc65b5500c65555
-- 055:ccccccc0cc7777cc9cccc77c9777ccccccc777c0c5ccc77cb556ccc7555666cc
-- 064:0000000000500ccc000ccccc0000ccaa000caaaa00c9a9aa00c99a9a000cc9a9
-- 065:cc000000aacc0000aacccc00aaac00c0aaac05c0aaaac000aaaac000aaaac000
-- 066:c47c00000cbc000c0c47c0cc00cc0cc30000cc330000cc33000c33c300c33335
-- 067:cc07c0003377c0003b7c0000473cc000733cc00033c3c0003c33c0005333c000
-- 068:0c4c555500c4cccc00cc44440000ccc700000c7700000c7709000c770c00cc77
-- 069:5551c47ccccc47cc44477cc07cccc00077cc000077cc0000777c0000777c0000
-- 070:00c6cccc30c64444c0c6644c0c0c66cc0c00cc7705ccc44700000cc4000000c9
-- 071:cccc666cc444cc6c7c444c6c7cc44c6c77ccc66c777cccc07777c000399c0500
-- 080:00000ccc000000cc000000cc000000cc0000000c0000000c0000cc0c0000cccc
-- 081:ccccc0000ccc00000cc000000cc000000c0000000c0000000ccc00000ccc0000
-- 082:0c3333330c3cccc300c222cc000ccccc0000000c0000000c0000000c000002cc
-- 083:33333c0033333c00c33333c0cccccc000c0000000c0000000c0000000c200000
-- 084:00c0cc74000cc4470000c4440000c4470000c4c40000000c0000cc0c0000cccc
-- 085:777cc00047777c0074777c00477777c074cc7c004c00c0000ccc00000ccc0000
-- 086:00000c470000c47400c444470000cccc0000000c0000000c0000000c000009cc
-- 087:7777c00077777c0047777c00747777c00ccccc000c0000000c0000000c900000
-- 112:0ccccccccc222222c2222333c2222222c2122222c2212222cc2222220ccccccc
-- 113:ccccccc0666666cc5666566c6666656c6666666c6666666c666666ccccccccc0
-- 114:0cccccc0cc2222ccc222322cc222232cc222222cc222232cc222232cc222232c
-- 115:0cccccc0cc6666ccc666566cc666656cc666666cc666656cc666656cc666656c
-- 116:0ccccccccc666666c6666555c6666666c6766666c6676666cc6666660ccccccc
-- 117:ccccccc0aaaaaaccbaaabaacaaaaabacaaaaaaacaaaaaaacaaaaaaccccccccc0
-- 118:0cccccc0cc6666ccc666566cc666656cc666666cc666656cc666656cc666656c
-- 119:0cccccc0ccaaaacccaaabaaccaaaabaccaaaaaaccaaaabaccaaaabaccaaaabac
-- 120:0cccccccccaaaaaacaaaabbbcaaaaaaaca9aaaaacaa9aaaaccaaaaaa0ccccccc
-- 121:ccccccc0222222cc3222322c2222232c2222222c2222222c222222ccccccccc0
-- 122:0cccccc0ccaaaacccaaabaaccaaaabaccaaaaaaccaaaabaccaaaabaccaaaabac
-- 123:0cccccc0cc2222ccc222322cc222232cc222222cc222232cc222232cc222232c
-- 128:0ccccccccc666666c6666555c6666666c6766666c6676666cc6666660ccccccc
-- 129:ccccccc0222222cc3222322c2222232c2222222c2222222c222222ccccccccc0
-- 130:c666656cc666666cc666666cc666666cc676666cc667666ccc6666cc0cccccc0
-- 131:c222232cc222222cc222222cc222222cc212222cc221222ccc2222cc0cccccc0
-- 132:0cccccccccaaaaaacaaaabbbcaaaaaaaca9aaaaacaa9aaaaccaaaaaa0ccccccc
-- 133:ccccccc0666666cc5666566c6666656c6666666c6666666c666666ccccccccc0
-- 134:caaaabaccaaaaaaccaaaaaaccaaaaaacca9aaaaccaa9aaacccaaaacc0cccccc0
-- 135:c666656cc666666cc666666cc666666cc676666cc667666ccc6666cc0cccccc0
-- 136:0ccccccccc222222c2222333c2222222c2122222c2212222cc2222220ccccccc
-- 137:ccccccc0aaaaaaccbaaabaacaaaaabacaaaaaaacaaaaaaacaaaaaaccccccccc0
-- 138:c222232cc222222cc222222cc222222cc212222cc221222ccc2222cc0cccccc0
-- 139:caaaabaccaaaaaaccaaaaaaccaaaaaacca9aaaaccaa9aaacccaaaacc0cccccc0
-- 144:0000cccc000c112100c112120c11255100cc5c55000c5a55000c55550000cccc
-- 145:ccccc00022222c00122222c0212222c0c52222c0a55152c0555cccc0ccc00000
-- 146:0000cc00000c2ccc000c112100c112120c11255100cc5c55000c5a55000c5555
-- 147:00000000ccccc00022222c00122222c0212222c0c52222c0a55152c0555cccc0
-- 148:0000c000000c1ccc000c112100c112120c11255100cc5c55000c5a55000c5555
-- 149:00000000ccccc00022222c00122222c0212222c0c52222c0a55152c0555cccc0
-- 150:00000000000ccccc000c112100c112120c11255100cc5c55000c5a55000c5555
-- 151:00000000ccccc00022222c00122222c0212222c0c52222c0a55152c0555cccc0
-- 152:0000cccc000c112100c112120c11255100cc5c55000c5a55000c55550000cccc
-- 153:ccccc00022222c00122222c0212222c0c52222c0a55152c0555cccc0ccc00000
-- 160:0000000000500ccc000ccc0c000000ca00000caa0000ccaa0000ca9a0000c9a9
-- 161:cc000000aacc0000aacccc00aaac00c0aaac05c0aaaac000aaaac000aaaac000
-- 162:0000cccc000000cc005ccc0c000000ca00000caa0000ccaa0000ca9a0000c9a9
-- 163:cccc0000ccc00000aacccc00aaac00c0aaac0050aaaac000aaaac000aaaac000
-- 164:0000cccc0000000000500ccc000ccc0c000000ca00000caa0000ccaa0000ca9a
-- 165:ccc00000cc000000aacc0000aacccc00aaac00c0aaac05c0aaaac000aaaac000
-- 166:0000cccc00000ccc0000cc0c008c00ca00000caa0000ccaa0000ca9a0000c9a9
-- 167:cc000000aacc0000aaccc000aaac0c00aaac00c0aaaac080aaaac000aaaac000
-- 168:0000000000000ccc008ccc0c000000ca00000caa0000ccaa0000ca9a0000c9a9
-- 169:cc000000aacc0000aacccc00aaac00c0aaac0080aaaac000aaaac000aaaac000
-- 176:00000ccc000000cc000000cc000000cc0000000c0000000c0000cc0c0000cccc
-- 177:ccccc0000ccc00000cc000000cc000000c0000000c0000000ccc00000ccc0000
-- 178:00000ccc000000cc000000cc000000cc0000000c0000000c0000cc0c0000cccc
-- 179:ccccc0000ccc00000cc000000cc000000c0000000c0000000ccc00000ccc0000
-- 180:0000c9a900000ccc000000cc000000cc0000000c0000000c0000cc0c0000cccc
-- 181:aaaac000ccccc0000ccc00000cc000000c0000000c0000000ccc00000ccc0000
-- 182:00000ccc000000cc000000cc000000cc0000000c0000000c0000cc0c0000cccc
-- 183:ccccc0000ccc00000cc000000cc000000c0000000c0000000ccc00000ccc0000
-- 184:00000ccc000000cc000000cc000000cc0000000c0000000c0000cc0c0000cccc
-- 185:ccccc0000ccc00000cc000000cc000000c0000000c0000000ccc00000ccc0000
-- 192:0cccccccccffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffff
-- 193:ccccccc0ffffffccffffdffcfffffdfcfffffffcfffffffcfffffffcfffffffc
-- 194:0cccccccccffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffff
-- 195:ccccccc0ffffffccffffdffcfffffdfcfffffffcfffffffcfffffffcfffffffc
-- 196:0cccccccccffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffff
-- 197:ccccccc0ffffffccffffeffcfffffefcfffffffcfffffffcfffffffcfffffffc
-- 198:0cccccccccffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffff
-- 199:ccccccc0ffffffccffffeffcfffffefcfffffffcfffffffcfffffffcfffffffc
-- 200:0000000060000000656000006656600066666660666660006660000060000000
-- 208:cfffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffff
-- 209:fffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffffc
-- 210:cfffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffff
-- 211:fffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffffc
-- 212:cfffffffcfffffffcfffffffcfffffffcfcfffffcffcffffccffffff0ccccccc
-- 213:fffffffcfffffffcfffffffcfffffffcfffffffcfffffffcffffffccccccccc0
-- 214:cfffffffcfffffffcfffffffcfffffffcfcfffffcffcffffccffffff0ccccccc
-- 215:fffffffcfffffffcfffffffcfffffffcfffffffcfffffffcffffffccccccccc0
-- 224:cfffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffff
-- 225:fffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffffc
-- 226:cfffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffff
-- 227:fffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffffc
-- 228:0ccccccccceeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeee
-- 229:ccccccc0eeeeeecceeeedeeceeeeedeceeeeeeeceeeeeeeceeeeeeeceeeeeeec
-- 230:0cccccc0cc2222ccc222322cc222232cc212222cc221222ccc2222cc0cccccc0
-- 231:0cccccc0cc6666ccc666566cc666656cc676666cc667666ccc6666cc0cccccc0
-- 232:0cccccccccaaaaaacaaaabbbcaaaaaaaca9aaaaacaa9aaaaccaaaaaa0ccccccc
-- 233:ccccccc0aaaaaaccbaaabaacaaaaabacaaaaaaacaaaaaaacaaaaaaccccccccc0
-- 234:0ccccccccc222222c2222333c2222222c2122222c2212222cc2222220ccccccc
-- 235:ccccccc0222222cc3222322c2222232c2222222c2222222c222222ccccccccc0
-- 236:0cccccc0cc2222ccc222322cc222232cc222222cc222232cc222232cc222232c
-- 237:0cccccc0cc6666ccc666566cc666656cc666666cc666656cc666656cc666656c
-- 238:0cccccc0ccaaaacccaaabaaccaaaabaccaaaaaaccaaaabaccaaaabaccaaaabac
-- 239:0cccccc0cceeeeccceeedeecceeeedecceeeeeecceeeedecceeeedecceeeedec
-- 240:cfffffffcfffffffcfffffffcfffffffcfcfffffcffcffffccffffff0ccccccc
-- 241:fffffffcfffffffcfffffffcfffffffcfffffffcfffffffcffffffccccccccc0
-- 242:cfffffffcfffffffcfffffffcfffffffcfcfffffcffcffffccffffff0ccccccc
-- 243:fffffffcfffffffcfffffffcfffffffcfffffffcfffffffcffffffccccccccc0
-- 244:ceeeeeeeceeeeeeeceeeeeeeceeeeeeecefeeeeeceefeeeecceeeeee0ccccccc
-- 245:eeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeccccccccc0
-- 246:0cccccc0ccaaaacccaaabaaccaaaabacca9aaaaccaa9aaacccaaaacc0cccccc0
-- 247:0cccccc0cceeeeccceeedeecceeeedeccefeeeecceefeeeccceeeecc0cccccc0
-- 248:0ccccccccceeeeeeceeeedddceeeeeeecefeeeeeceefeeeecceeeeee0ccccccc
-- 249:ccccccc0eeeeeeccdeeedeeceeeeedeceeeeeeeceeeeeeeceeeeeeccccccccc0
-- 250:0ccccccccc666666c6666555c6666666c6766666c6676666cc6666660ccccccc
-- 251:ccccccc0666666cc5666566c6666656c6666666c6666666c666666ccccccccc0
-- 252:c222232cc222222cc222222cc222222cc212222cc221222ccc2222cc0cccccc0
-- 253:c666656cc666666cc666666cc666666cc676666cc667666ccc6666cc0cccccc0
-- 254:caaaabaccaaaaaaccaaaaaaccaaaaaacca9aaaaccaa9aaacccaaaacc0cccccc0
-- 255:ceeeedecceeeeeecceeeeeecceeeeeeccefeeeecceefeeeccceeeecc0cccccc0
-- </SPRITES>

-- <MAP>
-- 002:000212121212121212122200021212122200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:000313131313131313132300031313132300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:000313131313131313132300041414142400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:000313131313131313132300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:000313131313131313132300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:000313131313131313132300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:000313131313131313132300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:000313131313131313132300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:000313131313131313132300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:000313131313131313132300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:000313131313131313132300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:000313131313131313132300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:000313131313131313132300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:000414141414141414142400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:fffffffffffffffffff0000000000000
-- 001:0123456789abcdeffedcba9876543210
-- 002:13445666655554444333333222222223
-- 004:79bcdeefffeedcb97532110001123576
-- 009:00000000000000000000006600000000
-- </WAVES>

-- <SFX>
-- 000:14c0249e346e442f641074639495b445c400d400e400e400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400305000000000
-- 001:2100310e311a4128514a616f818791c7a1f7b1f0c1f0e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100316000000000
-- 002:010d010e013f11301161118221a321c531d741d061008100a100c100d100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100c12000000000
-- 003:0100117021003190410051b0710091d0a100c1f0d100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100470000000000
-- 004:01f011c0112011a02130319031404170515051a061607170814091309110a120b100b150b100c100c180c130c120d130d120d110e110f100f100f100240000000000
-- 005:14e01430343064307440848094e0b450c4d0d430e440e400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400300000000000
-- 032:100010001000200030003000500070008000a000c000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000300000000000
-- 033:220022002200220022002200220022002200220022002200220022002200220022002200220022002200220022002200220022002200220022002200670000000000
-- 034:e100810061005100410041005100610081009100b100c100e100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100300000000000
-- 035:61005100510041004100410051006100710071008100a100b100c100d100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100400000000000
-- 036:f100a10071006100510041003100210021002100310041005100610071009100a100c100d100e100f100f100f100f100f100f100f100f100f100f100300000000000
-- 037:d310b3209322833d735173526351536153615371536153516340633073307320733f832f8333835f936fa3bfb34fc362d371d371e380e38fe34ff30f480000000000
-- 038:1400145024002480240024b03400448054006430740084009400a400b400d400e400e400f400f400f400f400f400f400f400f400f400f400f400f400000000000000
-- 039:143014001460240034a0440054c0640074f084009400a400c400d400d400e400e400f400f400f400f400f400f400f400f400f400f400f400f400f400000000000000
-- 048:d100a10071005100310021001100110011002100410061009100c100d100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100510000000000
-- 049:d1008120410031306180f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100560000000000
-- 050:d1008120410031306180f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f1005e0000000000
-- </SFX>

-- <PATTERNS>
-- 000:400846000840000840000000400846000000000000000000601f46000840000000000000600846600846000000000000800846000000000000000000800846000000000000000000602f46000840000000000000600846600846000000000000400846000000000000000000400846000000000000000000601f46000000000000000000600846600846000000000000800846000000000000000000800846000000000000000000602f46000000000000000000600846600846000000000000
-- 001:000830000000000830602c32400832000000000000000000000830000000a00832600832400832000000000000000000401f32000000000000000000402f32000000a00832600832400832000000000000000000000830000830000000000000000830000000000000600832400832000000000830000830000830000000a00832600832400832000000000000000000401f32000000000830000830402f32000000a00832600832400832000000000000000830000830000000000000000000
-- 002:43ae1a000820b0081a00081003be10000000000000000000000000000000000000000000000000000000000000000000400826000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b3ae1a00082043be1a000000000810000000000000000000000000000000000000000000000000000000000000000000400826000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:400846000840000840000000400846000000000000000000601f46000840000000000000600846600846000000000000800846000000000000000000800846000000000000000000602f46000840000000000000600846600846000000000000400846000000000000000000400846000000000000000000601f46000000000000000000600846600846000000000000800846000000000000000000800846000000000000000000602f46000000000000000000600846600846000000000000
-- 009:b00804000840b00804000000e00804000000f00804000000400806000000f00804000000e00804000000d00804000000b00804000000b00804000000e00804000000f00804000000400806000000f00804000000e00804000000d00804000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 010:b00802000840b00802000000e00802000000f00802000000400804000000f00802000000e00802000000d00802000000b00802000000b00802000000e00802000000f00802000000400804000000f00802000000e00802000000d00802000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 011:e00808000840f00808000000e00808000000f00808000000d00808000000b00808000000b00808000000d00808000000e00808000000f00808000000d00808000000b00808000000b00808000000000800000000000800000000000800000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 012:e00808000840f00808000000e00808000000f00808000000d00808000000b00808000000b00808000000d00808000000000800000000000800000000000800000000000800000000000800000000000800000000000800000000000800000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 013:b00802000000b01f02000800000800000000b00802000800400804000000401f04000800000800000000400804000800b00802000800b01f02000800000800000000b00802000800400804000000401f04000000000800000000400804000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:400802000000401f02000800000800000000400802000800900802000000901f02000800000800000000900802000800400802000800401f02000800000800000000400802000800900802000000901f02000000000800000000900802000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:700808000840800808000000700808000000800808000000600808000000400808000000400808000000d00806000000700808000000800808000000600808000000400808000000400808000000000800000000000800000000000800000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 016:700808000840800808000000700808000000800808000000600808000000400808000000400808000000d00806000000a00806000000d00806000000f00806000000600808000000404c08000000000800000000f04c06000000000800000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 017:700808000840800808000000600808000000400808000000400808000000000800000000000800000000000800000000700808000000800808000000600808000000400808000000400808000000000800000000000800000000000800000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 018:700808000840800808000000700808000000800808000000600808000000400808000000400808000000d00806000000400808000000000800000000604c08000000000800000000409c08000000000800000000000800000000000800000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 019:844e18000000000000000000000000000000000000000000600818000000000000000000b00818000000000000000000400818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 020:d44e18000000000000000000000000000000000000000000b0081800000000000000000040081a000000000000000000900818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 021:d44e18000000000000000000000000000000000000000000b00818000000000000000000f0081800000000000000000040081a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 022:400804000840000800000000000000000000400804000000000000000000000800000000f00802000000000800000000d00802000000000000000000000000000000d00802000000000000000000000000000800d00802000000000000000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 023:900804000840000800000000000000000000900804000000000000000000000800000000800802000000000800000000600802000000000000000000000000000000600802000000000000000000000000000800600802000000000000000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 024:d99e1a000000000000000000000000000000000000000000b0081a000000000000000000f0081a00000000000000000040081c000000000000000000000800000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 025:b00804000000b01f04000800000800000000b00804000800400806000000401f06000800000800000000400806000800b00804000800b01f04000800000800000000b00804000800400806000000401f06000000000800000000400806000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </PATTERNS>

-- <TRACKS>
-- 000:1000001800001803001803001000001800001803001803001000000000000000000000000000000000000000000000004c0000
-- 001:a00000ac2000ac2c00ac2d00ec2c00ec2d00e00010e001100c2210f003104d50005160004d5000616910a10e00a100006f0200
-- </TRACKS>

-- <PALETTE>
-- 000:3030345d275d993e53ef7d575d4048ffffe6ffd691a57579ffffff3b5dc924c2ff89eff71a1c2c9db0c2566c86333c57
-- </PALETTE>

