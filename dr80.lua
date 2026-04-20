-- title:   game title
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
		-- Console.toggle()
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
	local w, h = 140, 130
	local x, y = 100, 0
	rect(x, y, w, h, 0)
	rectb(x, y, w, h, 13)
	local visible = 14
	local start = math.max(1, #Console.lines - visible - Console.scroll + 1)
	local idx = 0
	for i = start, math.min(#Console.lines, start + visible - 1) do
		print(Console.lines[i], x + 4, y + 4 + idx * 8, 12, false, 1, true)
		idx = idx + 1
	end
end

local Assets = {
	music = {
		flora = 0,
		fever = 1,
	},
	sfx = {
		common = {
			land = 0,
			move = 1,
			rotate = 2,
			clear = 3,
			overflow = 4,
			invalid = 5,
			drop = 6,
		},
		character = {
			overflow = { 16, 17, 18, 19 },
			drop = { 20, 21, 22, 23 },
			clear = { 24, 25, 26, 27 },
			invalid = { 28, 29, 30, 31 },
		},
	},
	sprites = {
		ui = {
			menu_cursor = 352,
			faces = { 0, 48, 192, 206 },
			border = {
				top_left = 32,
				top = 33,
				top_right = 34,
				left = 48,
				center = 49,
				right = 50,
				bottom_left = 64,
				bottom = 65,
				bottom_right = 66,
			},
			background = {
				single = 503,
				single_transparent = 474,
				square_2x2 = 270,
			},
		},
		pieces = {
			runes = {
				{ name = "R", W = 490, E = 491, N = 492, S = 508 },
				{ name = "S", W = 506, E = 507, N = 493, S = 509 },
				{ name = "E", W = 488, E = 489, N = 494, S = 510 },
			},
			stones = {
				R = 256,
				S = 272,
				E = 288,
			},
			halves = {
				R = 486,
				S = 487,
				E = 502,
			},
			queued_surprise = {
				R = 401,
				S = 407,
				E = 403,
			},
		},
		fx = {
			drop_trail = {
				horizontal = { 398, 382, 366, 350, 334 },
				vertical = { 396, 380, 397, 381, 365 },
			},
			ghost_pill = {
				horizontal = { 478, 462, 446 },
				vertical = { 459, 460, 461 },
			},
			disappear = {
				R = { 400, 401, 402, 409 },
				S = { 406, 407, 408, 409 },
				E = { 403, 404, 405, 409 },
			},
			appear = {
				R = { 409, 402, 401, 400 },
				S = { 409, 408, 407, 406 },
				E = { 409, 405, 404, 403 },
			},
			cloud = 194,
			cloud_raining = { 196, 198, 200, 202, 204 },
			spawn_animation_temp_gray = { 409, 474 },
			spawn_animation_temp_transparent = { 409, 478, 409 },
			spawn_animation_temp_color = {
				R = { 409, 402, 401, 400 },
				S = { 409, 408, 407, 406 },
				E = { 409, 405, 404, 403 },
			},
		},
		characters = {
			[1] = {
				name = "ruby",
				idle = { 0, 2, 4, 6 },
				game_over = { 10 },
			},
			[2] = {
				name = "opal",
				idle = { 48, 50, 52, 54 },
				game_over = { 48 },
			},
			[3] = {
				name = "amethyst",
				idle = { 96, 98, 100, 102 },
				game_over = { 106 },
			},
			[4] = {
				name = "pearl",
				idle = { 144, 146, 148, 150 },
				game_over = { 154 },
			},
		},
	},
}

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
	grids_spawned = false,
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

function Audio.play_bgm(track, loop)
	if Audio.bgm == track then
		return
	end
	music(track, 0, 0, loop ~= false)
	Audio.bgm = track
end

function Audio.stop_bgm()
	music(-1)
	Audio.bgm = nil
end

function Audio.play(id, speed, note)
	sfx(id, note, -1, Audio.reserved.sfx, 15, speed or 0, false)
end

function Audio.generate_character_note(combo, character_name)
	local note = Audio.chords.happy[math.min(combo, 4)]
	if character_name == "amethyst" or character_name == "pearl" then
		note = Audio.chords.arcade[math.min(combo, 4)]
	end
	return note
end

-- Audio manager end --

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

local KEYMAPS = {
	KEYMAP_P1,
	KEYMAP_P2,
	KEYMAP_P3,
	KEYMAP_P4,
}

-- Keymap end --

-- Targets

local TARGETS = {
	LEADER = 0,
	PLAYER_1 = 1,
	PLAYER_2 = 2,
	PLAYER_3 = 3,
	PLAYER_4 = 4,
	RANDOM = 5,
}

local CELL_TYPES = {
	STONE = "stone",
	HALF = "half",
	PILL = "pill",
}

-- Grid manager --

local Grid = {
	cell_size = 8,
}
Grid.__index = Grid

function Grid:new(player)
	local g = setmetatable({}, Grid)

	g.player = player
	g.h = Game.get_grid_height()
	g.w = Game.get_grid_width()
	g.py = Game.get_grid_y()
	g.spawn_animation_finished = true
	g.target = TARGETS.LEADER
	if Game.players <= 2 then
		g.px = (player - 1) * (g.w + 4) + 1
		g.next_pill_x = g.w + 1
		g.next_pill_y = 0
		g.character_x = g.w + 1
		g.character_y = g.h - 4
		g.score_x = g.w + 1
		g.score_y = g.h
		g.target_x = g.w + 1
		g.target_y = g.h - 8
		g.target_selected_x = g.w + 1
		g.target_selected_y = g.h - 7
	else
		g.px = (player - 1) * (g.w + 1) + 1
		g.next_pill_x = g.w - 3
		g.next_pill_y = -3
		g.character_x = g.w - 1
		g.character_y = -4
		g.score_x = 0
		g.score_y = -2
		g.target_x = 0
		g.target_y = -4
		g.target_selected_x = 2
		g.target_selected_y = -4
	end

	g.cell_size = Grid.cell_size
	g.level = 9
	g.num_stones = 0
	g.next_pill = nil
	g.static_pills = {}
	g.active_pill = nil
	g.halves = {}
	g.drop_phase = false
	g.board = {}
	g.interval = 60
	g.is_paused = false
	g.character = nil
	g.combo = 0
	g.pending_surprises = 0
	g.queued_surprises = {}
	g.game_over = false
	g.cascade_trigger = false

	g.animation_queue = {}

	g:generate_board()
	g:generate_stones(5)
	g:generate_character(player)

	return g
end

local ANIMATIONS = {
	DROP_TRAIL = 0, -- plays both drop_trail and ghost_pill
	DISAPPEARING_PILL = 1,
	CLOUD_RAINING = 2,
	SOMETHING = 3,
}

local Animation = {
	animation_index = 0,
}
Animation.__index = Animation

function Animation:new(name, options)
	local animation = {
		name = name,
		index = self.animation_index,
		cur_frame = 0,
	}

	if name == ANIMATIONS.DROP_TRAIL then
		animation.num_frames = 30
		animation.start_x1 = options.start_x1
		animation.start_y1 = options.start_y1
		animation.start_x2 = options.start_x2
		animation.start_y2 = options.start_y2
		animation.end_x1 = options.end_x1
		animation.end_y1 = options.end_y1
		animation.end_x2 = options.end_x2
		animation.end_y2 = options.end_y2
		animation.rotation = options.rotation
	elseif name == ANIMATIONS.DISAPPEARING_PILL then
		animation.num_frames = 20
		animation.x = options.x
		animation.y = options.y
		animation.sprites = Assets.sprites.fx.disappear[options.color]
	end

	self.animation_index = self.animation_index + 1
	return animation
end

local Runes = {}

function Runes.generate_pill_runes()
	local runes = Assets.sprites.pieces.runes
	local rune1 = runes[math.random(1, #runes)]
	local rune2 = runes[math.random(1, #runes)]
	return { rune1 = rune1, rune2 = rune2 }
end

function Runes.get_random_color()
	local bag = { "R", "S", "E" }
	local i = math.random(#bag)
	return bag[i]
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
	local asset = Assets.sprites.characters[index]
	self.character = {
		id = index,
		name = asset.name,
		state = "idle",
		anim_idle = {
			cur = 0,
			sprites = asset.idle,
		},
		anim_game_over = {
			sprites = asset.game_over,
		},
		w = 2,
		h = 3,
	}
end

function Grid:draw_level()
	print("LEVEL", self:cx(1), self:cy(1), 8, true)
	print(self.level, self:cx(self.w - 2) + 4, self:cy(1), 8, true)

	rectb(self:cx(1), self:cy(2), 8, 8, 1)
end

function Grid:draw_score()
	local cx = self:cx(self.score_x)
	local cy = self:cy(self.score_y - 1)

	spr(Assets.sprites.ui.background.square_2x2, cx, cy, 0, 1, 0, 0, 2, 2)

	-- local movement offset = 5
	if self.num_stones >= 10 then
		offset = 2
	end
	print(self.num_stones, self:cx(self.score_x) + offset, self:cy(self.score_y) - (self.cell_size // 4), 8, true)
end

function Grid:draw_character(t)
	local char = self.character
	if char == nil then
		Console.log("ERROR: character is nil, fix the code")
		return
	end

	local cx = self:cx(self.character_x)
	local cy = self:cy(self.character_y)

	if self.game_over == true then
		spr(char.anim_game_over.sprites[1], cx, cy, 0, 1, 0, 0, char.w, char.h)
		local gy = self:cy(self.character_y - 2)
		spr(Assets.sprites.fx.cloud, cx, gy, 0, 1, 0, 0, 2, 1)
		local rain = Assets.sprites.fx.cloud_raining
		local i = (t // 8) % #rain + 1
		local frame = rain[i]

		local ry = self:cy(self.character_y - 1)
		spr(frame, cx, ry, 0, 1, 0, 0, 2, 1)
	else
		local i = (t // 8) % #char.anim_idle.sprites + 1
		local frame = char.anim_idle.sprites[i]
		spr(frame, cx, cy, 0, 1, 0, 0, char.w, char.h)
	end
end

function Grid:add_animation_to_queue(name, options)
	local animation = Animation:new(name, options)
	self.animation_queue[animation.index] = animation
end

function Grid:animate_all()
	for index, animation in pairs(self.animation_queue) do
		self:animate_one(index, animation)
		if index ~= nil then
			self:animate_one(index, animation)
		end
	end
end

function Grid:animate_one(index, animation)
	if animation.name == ANIMATIONS.DROP_TRAIL then
		local start_y = math.min(animation.start_y1, animation.start_y2)
		local start_x = math.min(animation.start_x1, animation.start_x2)
		local end_y = math.min(animation.end_y1, animation.end_y2)

		local trail_offset = 0
		if animation.start_x1 == animation.start_x2 then
			local ghost = Assets.sprites.fx.ghost_pill.vertical
			local gp_frame = (animation.cur_frame // (animation.num_frames // (#ghost - 1))) + 1
			spr(ghost[gp_frame], self:cx(start_x), self:cy(start_y), 0, 1, 0, 0, 1, 2)

			for ly = start_y + 2, end_y - 1, 1 do
				local trail = Assets.sprites.fx.drop_trail.vertical
				local num_sprites = #trail
				local frame = math.max(animation.cur_frame - trail_offset, 0)
						// (animation.num_frames // (num_sprites - 1))
					+ 1
				local sprite = trail[math.min(frame, #trail)]
				spr(sprite, self:cx(start_x), self:cy(ly), 0, 1, 0, 0, 1, 1)
				trail_offset = trail_offset + 1
			end
		else
			local ghost = Assets.sprites.fx.ghost_pill.horizontal
			local gp_frame = (animation.cur_frame // (animation.num_frames // (#ghost - 1))) + 1
			spr(ghost[gp_frame], self:cx(start_x), self:cy(start_y), 0, 1, 0, 0, 2, 1)

			for ly = start_y + 1, end_y - 1, 1 do
				local trail = Assets.sprites.fx.drop_trail.horizontal
				local num_sprites = #trail
				local frame = math.max(animation.cur_frame - trail_offset, 0)
						// (animation.num_frames // (num_sprites - 1))
					+ 1
				local sprite = trail[math.min(frame, #trail)]
				spr(sprite, self:cx(start_x), self:cy(ly), 0, 1, 0, 0, 2, 1)
				trail_offset = trail_offset + 1
			end
		end
	elseif animation.name == ANIMATIONS.DISAPPEARING_PILL then
		local sprite = animation.sprites[animation.cur_frame // 5]
		spr(sprite, self:cx(animation.x), self:cy(animation.y), 0, 1, 0, 0, 1, 1)
	end

	animation.cur_frame = animation.cur_frame + 1
	if animation.cur_frame >= animation.num_frames then
		self.animation_queue[index] = nil
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
			type = CELL_TYPES.STONE,
			spr = Assets.sprites.pieces.stones[color],
			color = color,
		}
	end

	self.num_stones = preset.n
end

function Grid:count_stones()
	local count = 0
	for y = 0, self.h - 1, 1 do
		for x = 0, self.w - 1, 1 do
			if self.board[y][x] ~= nil and self.board[y][x].type == CELL_TYPES.STONE then
				count = count + 1
			end
		end
	end

	self.num_stones = count
end

function Grid:increment_combo()
	self.combo = self.combo + 1
	local note = Audio.generate_character_note(self.combo, self.character.name)
	Audio.play(Assets.sfx.character.clear[self.character.id], -2, note)
end

function Grid:queue_surprises(num_surprises)
	self.pending_surprises = self.pending_surprises + num_surprises
end

function Grid:reset_combo()
	self.combo = 0
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

function Grid:generate_next_pill()
	local pill = Runes.generate_pill_runes()

	self.next_pill = {
		rune1 = pill.rune1,
		rune2 = pill.rune2,
		x = self.next_pill_x,
		y = self.next_pill_y,
		rotation = 0,
		spawn_animation = {
			cur_frame = 0,
			rune1_frames = Assets.sprites.fx.appear[pill.rune1.name],
			rune2_frames = Assets.sprites.fx.appear[pill.rune2.name],
		},
	}
end

function Grid:draw_next_pill()
	if self.game_over then
		return
	end
	local next_pill = self.next_pill
	if not next_pill then
		return
	end

	local x1, y1, x2, y2 = self:get_pill_xy(next_pill)
	local spr1, spr2 = self:get_pill_sprites(next_pill)

	if next_pill.spawn_animation.cur_frame < 20 then
		spr1 = next_pill.spawn_animation.rune1_frames[next_pill.spawn_animation.cur_frame // 5 + 1]
		spr2 = next_pill.spawn_animation.rune2_frames[next_pill.spawn_animation.cur_frame // 5 + 1]
		next_pill.spawn_animation.cur_frame = next_pill.spawn_animation.cur_frame + 1
	end

	spr(spr1, self:cx(x1), self:cy(y1), 0)
	spr(spr2, self:cx(x2), self:cy(y2), 0)
end

function Grid:draw_target()
	if self.game_over or Game.players <= 2 then
		return
	end
	local cx = self:cx(self.target_x)
	local cy = self:cy(self.target_y)
	local cx2 = self:cx(self.target_selected_x)
	local cy2 = self:cy(self.target_selected_y)

	print("TAR:", cx, cy, 13, true, 1, true)
	if self.target == TARGETS.LEADER then
		print("lead", cx2, cy2, 8, true, 1, true)
	elseif self.target >= TARGETS.PLAYER_1 and self.target <= TARGETS.PLAYER_4 then
		spr(Assets.sprites.ui.faces[self.target], cx2, cy2, 0, 1, 0, 0, 2, 1)
	elseif self.target == TARGETS.RANDOM then
		print("rand", cx2, cy2, 8, true, 1, true)
	end
end

function Grid:spawn_pill(pill)
	local spawnx = 0
	if self.w % 2 == 0 then
		spawnx = self.w / 2 - 1
	else
		spawnx = (self.w - 1) / 2
	end
	local spawny = 0

	local game_over = not (self:available(spawnx, spawny) and self:available(spawnx + 1, spawny))
	if game_over then
		self:trigger_game_over()
	else
		self.active_pill = {
			rune1 = pill.rune1,
			rune2 = pill.rune2,
			x = spawnx,
			y = spawny,
			rotation = 0,
		}
	end
end

function Grid:trigger_game_over()
	Audio.play(Assets.sfx.character.overflow[self.character.id])
	self.game_over = true
end

function Grid:spawn_queued_surprises()
	local num_surprises = self.pending_surprises
	if num_surprises > self.w - 1 then
		num_surprises = self.w - 1
	end

	local bag = {}
	for x = 0, self.w - 1, 1 do
		table.insert(bag, x)
	end

	for i = 1, num_surprises, 1 do
		local spawnindex = math.random(#bag)
		local spawnx = bag[spawnindex]
		table.remove(bag, spawnindex)
		local spawny = 0

		local color = Runes.get_random_color()
		local cell = {
			type = CELL_TYPES.HALF,
			color = color,
			spr = Assets.sprites.pieces.halves[color],
			spawnx = spawnx,
			spawny = spawny,
		}
		table.insert(self.queued_surprises, cell)
	end

	self.pending_surprises = 0
end

function Grid:drop_queued_surprises()
	for _, v in ipairs(self.queued_surprises) do
		local cell = self.board[v.spawny][v.spawnx]
		if not cell then
			cell = {
				type = v.type,
				color = v.color,
				spr = v.spr,
			}
		end
		self.board[v.spawny][v.spawnx] = cell
	end

	self.queued_surprises = {}

	self.cascade_trigger = true
end

function Grid:rotate_clockwise()
	if self.active_pill == nil then
		return
	end

	local next_rotation = (self.active_pill.rotation + 1) % 4
	local x1, y1, x2, y2 = self:get_pill_xy(self.active_pill, next_rotation)
	if self:available(x1, y1) and self:available(x2, y2) then
		self.active_pill.rotation = next_rotation
	else
		Audio.play(Assets.sfx.character.invalid[self.character.id])
	end
end

function Grid:rotate_counterclockwise()
	if self.active_pill == nil then
		return
	end

	local next_rotation = (self.active_pill.rotation + 3) % 4
	local x1, y1, x2, y2 = self:get_pill_xy(self.active_pill, next_rotation)
	if self:available(x1, y1) and self:available(x2, y2) then
		self.active_pill.rotation = next_rotation
	else
		Audio.play(Assets.sfx.character.invalid[self.character.id])
	end
end

function Grid:move_left()
	if self.active_pill == nil then
		return
	end

	local x1, y1, x2, y2 = self:get_pill_xy()
	if self:available(x1 - 1, y1) and self:available(x2 - 1, y2) then
		self.active_pill.x = self.active_pill.x - 1
	else
		Audio.play(Assets.sfx.character.invalid[self.character.id])
	end
end

function Grid:move_right()
	if self.active_pill == nil then
		return
	end

	local x1, y1, x2, y2 = self:get_pill_xy()
	if self:available(x1 + 1, y1) and self:available(x2 + 1, y2) then
		self.active_pill.x = self.active_pill.x + 1
	else
		Audio.play(Assets.sfx.character.invalid[self.character.id])
	end
end

function Grid:cycle_target()
	if self.target == nil then
		self.target = TARGETS.LEADER
	end

	if self.target == TARGETS.LEADER then
		self.target = TARGETS.PLAYER_1
	elseif self.target == TARGETS.PLAYER_1 then
		self.target = TARGETS.PLAYER_2
	elseif self.target == TARGETS.PLAYER_2 then
		if #Game.grids > 2 then
			self.target = TARGETS.PLAYER_3
		else
			self.target = TARGETS.RANDOM
		end
	elseif self.target == TARGETS.PLAYER_3 then
		if #Game.grids > 3 then
			self.target = TARGETS.PLAYER_4
		else
			self.target = TARGETS.RANDOM
		end
	elseif self.target == TARGETS.PLAYER_4 then
		self.target = TARGETS.RANDOM
	elseif self.target == TARGETS.RANDOM then
		self.target = TARGETS.LEADER
	end

	if self.target == self.player then
		self:cycle_target()
	end
end

function Grid:drop_pill()
	if self.active_pill == nil then
		return
	end

	Audio.play(Assets.sfx.character.drop[self.character.id])

	-- mark tiles that need to be animated (drop trail)
	-- current position
	local start_x1, start_y1, start_x2, start_y2 = self:get_pill_xy()
	local rotation = self.active_pill.rotation

	local grav_possible, end_x1, end_y1, end_x2, end_y2 = self:grav()
	while grav_possible do
		grav_possible, end_x1, end_y1, end_x2, end_y2 = self:grav()
	end

	self:add_animation_to_queue(ANIMATIONS.DROP_TRAIL, {
		start_x1 = start_x1,
		start_y1 = start_y1,
		start_x2 = start_x2,
		start_y2 = start_y2,
		end_x1 = end_x1,
		end_y1 = end_y1,
		end_x2 = end_x2,
		end_y2 = end_y2,
		rotation = rotation,
	})
end

-- instead of bunch of for loops, prepare a table / dictionary to quickly check availability
function Grid:available(x, y)
	if x < 0 or x > self.w - 1 then
		return false
	end

	-- allow rotation right after spawn
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

-- get_pill_xy checks the pill rotation and returns x,y position for both sides of the pill.
-- returns x1, y1, x2, y2
function Grid:get_pill_xy(pill, rotation)
	pill = pill or self.active_pill
	rotation = rotation or pill.rotation
	if rotation == 0 then
		return pill.x, pill.y, pill.x + 1, pill.y
	elseif rotation == 1 then
		return pill.x, pill.y - 1, pill.x, pill.y
	elseif rotation == 2 then
		return pill.x + 1, pill.y, pill.x, pill.y
	elseif rotation == 3 then
		return pill.x, pill.y, pill.x, pill.y - 1
	end

	return nil, nil, nil, nil
end

function Grid:get_pill_sprites(pill)
	pill = pill or self.active_pill
	if not pill then
		Console.log("error: pill not found")
		return
	end

	local rotation = (pill.rotation or 0) % 4
	local dir = {
		[0] = { "W", "E" },
		[1] = { "N", "S" },
		[2] = { "E", "W" },
		[3] = { "S", "N" },
	}
	local pair = dir[rotation]

	local spr1 = pill.rune1[pair[1]]
	local spr2 = pill.rune2[pair[2]]
	return spr1, spr2
end

function Grid:draw_static_pills()
	for _, pill in ipairs(self.static_pills) do
		if pill == nil then
			Console.log("static pill is nil")
			return
		end

		local x1, y1, x2, y2 = self:get_pill_xy(pill)
		local spr1, spr2 = self:get_pill_sprites(pill)
		spr(spr1, x1 * self.cell_size, y1 * self.cell_size, 0)
		spr(spr2, x2 * self.cell_size, y2 * self.cell_size, 0)
	end
end

function Grid:draw_active_pill()
	if self.active_pill == nil then
		return
	end

	local x1, y1, x2, y2 = self:get_pill_xy()
	local spr1, spr2 = self:get_pill_sprites()

	spr(spr1, self:cx(x1), self:cy(y1), 0)
	spr(spr2, self:cx(x2), self:cy(y2), 0)
end

function Grid:draw_halves()
	for _, half in ipairs(self.halves) do
		spr(half.spr, half.x * self.cell_size, half.y * self.cell_size, 0)
	end
end

function Grid:draw_queued_surprises()
	for _, v in ipairs(self.queued_surprises) do
		spr(Assets.sprites.pieces.queued_surprise[v.color], self:cx(v.spawnx), self:cy(v.spawny - 1), 0)
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
				if self.board[y][x].type == CELL_TYPES.HALF then
					local half = self.board[y][x]
					if self:available(x, y + 1) then
						self.board[y + 1][x] = {
							type = CELL_TYPES.HALF,
							color = half.color,
							spr = half.spr,
						}
						self.board[y][x] = nil
						still_falling = true
					else
						-- Audio.play(SFX.LAND)
						self.board[y][x] = {
							type = CELL_TYPES.HALF,
							color = half.color,
							spr = half.spr,
						}
					end
				elseif self.board[y][x].type == CELL_TYPES.PILL then
					local pill = self.board[y][x]
					local oh_pos = pill.other_half
					local is_pill_available = self:available(x, y + 1)
					local is_available_oh = self:available(oh_pos.x, oh_pos.y + 1)

					if oh_pos.x == x then
						if is_pill_available then
							self.board[y + 1][x] = table.deep_copy(self.board[y][x])
							self.board[y + 1][x].other_half.y = oh_pos.y + 1
							self.board[oh_pos.y + 1][oh_pos.x] = table.deep_copy(self.board[oh_pos.y][oh_pos.x])
							self.board[oh_pos.y + 1][oh_pos.x].other_half.y = y + 1
							self.board[oh_pos.y][oh_pos.x] = nil
							already_moved[oh_pos.y][oh_pos.x] = true
							still_falling = true
						end
					elseif is_pill_available and is_available_oh then
						self.board[y + 1][x] = table.deep_copy(self.board[y][x])
						self.board[y + 1][x].other_half.y = oh_pos.y + 1
						self.board[y][x] = nil
						self.board[oh_pos.y + 1][oh_pos.x] = table.deep_copy(self.board[oh_pos.y][oh_pos.x])
						self.board[oh_pos.y + 1][oh_pos.x].other_half.y = y + 1
						self.board[oh_pos.y][oh_pos.x] = nil
						already_moved[oh_pos.y][oh_pos.x] = true
						still_falling = true
					else
						-- Audio.play(SFX.LAND)
					end
				end
			end

			::continue::
		end
	end

	return still_falling
end

-- grav checks whether the active pill can go one position down.
-- if it can, it moves to y+1 from the current position.
-- it it cannot, it doesn't move, and it's marked as static (it's no longer the active pill).
-- the function returns true if the movement was possible (and the active pill remains active).
-- the function returns false if the movement was not possible and the pill became static.
-- also returns the position where the pill landed, assuming it has landed (the movement was not possible)
function Grid:grav()
	local active = self.active_pill
	if active == nil then
		return
	end

	local x1, y1, x2, y2 = self:get_pill_xy()

	if self:available(x1, y1 + 1) and self:available(x2, y2 + 1) then
		active.y = active.y + 1

		return true
	else
		self:mark_active_pill_as_static()
		return false, x1, y1, x2, y2
	end
end

function Grid:mark_active_pill_as_static()
	if self.active_pill == nil then
		Console.log("cannot mark pill as static, active pill not found")
		return
	end

	local x1, y1, x2, y2 = self:get_pill_xy()

	local spr1, spr2 = self:get_pill_sprites()
	if y1 >= 0 then
		self.board[y1][x1] = {
			type = CELL_TYPES.PILL,
			color = self.active_pill.rune1.name,
			spr = spr1,
			other_half = {
				x = x2,
				y = y2,
			},
		}
	end
	if y2 >= 0 then
		self.board[y2][x2] = {
			type = CELL_TYPES.PILL,
			color = self.active_pill.rune2.name,
			spr = spr2,
			other_half = {
				x = x1,
				y = y1,
			},
		}
	end

	self.active_pill = nil
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

-- TODO: think of some nicer animation and add animation to viruses as well
function Grid:get_spawn_tile_art(x, y, border, transparent)
	local frames = Assets.sprites.fx.spawn_animation_temp_gray
	local base = nil

	if border == false then
		local cell = self.board[y - 1][x - 1]
		if cell ~= nil then
			frames = Assets.sprites.fx.spawn_animation_temp_color[cell.color]
			base = Assets.sprites.pieces.stones[cell.color]
		end
	end
	if border == true then
		base = Assets.sprites.ui.background.single
	end
	if transparent == true then
		frames = Assets.sprites.fx.spawn_animation_temp_transparent
		base = Assets.sprites.ui.background.single_transparent
	end

	return frames, base
end

function Grid:spawn_grid_radial_wave(t)
	if self.grid_spawn_start_t == nil then
		self.grid_spawn_start_t = t
	end

	local elapsed = (t - self.grid_spawn_start_t) / 4
	local cx0 = self.w / 2
	local cy0 = self.h / 2

	local all_finished = true
	for y = 0, self.h + 1, 1 do
		local cy = self:cy(y - 1)
		for x = 0, self.w + 1, 1 do
			local cx = self:cx(x - 1)
			local dx = x - cx0
			local dy = y - cy0
			local distance = math.sqrt(dx * dx + dy * dy)
			local wave_start = distance * 1.5 + y * 0.2
			local phase = elapsed - wave_start
			if phase < 0 then
				all_finished = false
			end

			local border = false
			local transparent = false
			if y == self.h + 1 then
				border = true
			end
			if y == 0 then
				border = true
				if x > 1 and x < self.w then
					transparent = true
				end
			end
			if x == 0 or x == self.w + 1 then
				border = true
			end

			if phase >= 0 then
				local frames, base = self:get_spawn_tile_art(x, y, border, transparent)
				local frame = math.floor(phase) + 1
				if frame <= #frames then
					all_finished = false
					local effect = frames[frame]
					spr(effect, cx, cy, 0)
				elseif base ~= nil then
					spr(base, cx, cy, 0)
				end
			end
		end
	end

	return all_finished
end

function Grid:spawn_grid(t)
	if self.grid_spawn_start_t == nil then
		self.grid_spawn_start_t = t
	end

	local elapsed = (t - self.grid_spawn_start_t) / 6
	local all_finished = true
	local max_x = self.w + 1

	for y = 0, self.h + 1, 1 do
		local cy = self:cy(y - 1)
		local row_delay = y * 0.85
		for x = 0, self.w + 1, 1 do
			local cx = self:cx(x - 1)
			local lane_x = x
			if y % 2 == 1 then
				lane_x = max_x - x
			end
			local wave_start = row_delay + lane_x * 0.45 + ((x + y) % 2) * 0.35
			local phase = elapsed - wave_start
			if phase < 0 then
				all_finished = false
			end

			local border = false
			local transparent = false
			if y == self.h + 1 then
				border = true
			end
			if y == 0 then
				border = true
				if x > 1 and x < self.w then
					transparent = true
				end
			end
			if x == 0 or x == self.w + 1 then
				border = true
			end

			if phase >= 0 then
				local frames, base = self:get_spawn_tile_art(x, y, border, transparent)
				local frame = math.floor(phase) + 1
				if frame <= #frames then
					all_finished = false
					spr(frames[frame], cx, cy, 0)
				elseif base ~= nil then
					spr(base, cx, cy, 0)
				end
			end
		end
	end

	return all_finished
end

function Grid:draw_border()
	for y = 0, self.h + 1 do
		local cy = self:cy(y - 1)
		for x = 0, self.w + 1 do
			local ok = false
			local transparent = false
			if y == self.h + 1 then
				ok = true
			end
			if y == 0 then
				ok = true
				if x > 1 and x < self.w then
					transparent = true
				end
			end
			if x == 0 or x == self.w + 1 then
				ok = true
			end
			if ok == true then
				local cx = self:cx(x - 1)
				local sprt = Assets.sprites.ui.background.single
				if transparent == true then
					sprt = Assets.sprites.ui.background.single_transparent
				end
				spr(sprt, cx, cy, 0)
			end
		end
	end

	-- around next pill
	-- spr(Assets.sprites.ui.background.single, self:cx(self.next_pill_x), self:cy(self.next_pill_y + 1))
	-- spr(Assets.sprites.ui.background.single, self:cx(self.next_pill_x + 1), self:cy(self.next_pill_y + 1))
	-- spr(Assets.sprites.ui.background.single, self:cx(self.next_pill_x), self:cy(self.next_pill_y - 1))
	-- spr(Assets.sprites.ui.background.single, self:cx(self.next_pill_x + 1), self:cy(self.next_pill_y - 1))
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

function Game.find_leader(excluded_player)
	local leader = 1
	local min = 9999999
	for _, grid in pairs(Game.grids) do
		if grid.player == excluded_player then
			goto continue
		end

		if grid.num_stones < min then
			min = grid.num_stones
			leader = grid.player
		end
		::continue::
	end

	return leader
end

function Game.find_random(excluded_player)
	local bag = {}
	for _, grid in pairs(Game.grids) do
		if grid.player == excluded_player then
			goto continue
		end

		Console.log("bag has " .. grid.player)
		table.insert(bag, grid.player)
		::continue::
	end

	local rand = math.random(#bag)
	Console.log("chose " .. rand)
	return bag[rand]
end

function Game.send_surprises(victim, combo)
	Console.log("victim: " .. victim)
	Console.log("combo: " .. combo)
	Console.log("#grids: " .. #Game.grids)
	Console.log("#players: " .. Game.players)

	for _, grid in pairs(Game.grids) do
		Console.log(grid.player)
	end

	local num_surprises = combo + 1
	Game.grids[victim]:queue_surprises(num_surprises)
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

function Game.animate_grids()
	for _, grid in pairs(Game.grids) do
		grid:animate_all()
	end
end

function Game.spawn_grids()
	local spawn_ended = true
	for _, grid in pairs(Game.grids) do
		local ended = grid:spawn_grid(t)
		spawn_ended = spawn_ended and ended
	end
	if spawn_ended == true then
		Game.grids_spawned = true
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

function Game.get_grid_height()
	-- when there are more than 2 players, grid is smaller and character is drawn on top
	if Game.players <= 2 then
		return 15
	end
	return 12
end

function Game.get_grid_y()
	-- when there are more than 2 players, grid is smaller and character is drawn on top
	if Game.players <= 2 then
		return 1
	end
	return 4
end

function Game.get_grid_width()
	if Game.players == 1 then
		return 9
	elseif Game.players == 2 then
		return 11
	elseif Game.players == 3 then
		return 8
	elseif Game.players == 4 then
		return 6
	else
		Console.log("unexpected number of players during get_grid_width")
	end
end

function Grid:log_state()
	Console.clear()
	Console.log(self.active_pill)
	Console.log(self.combo)
	Console.log(self.board)
	Console.log(self.game_over)
	Console.log(self.cascade_trigger)
end

function Grid:eval()
	if self.active_pill == nil then
		if #self.queued_surprises > 0 then
			self:drop_queued_surprises()
			return
		end
	end

	if self.pending_surprises > 0 then
		self:spawn_queued_surprises()
		return
	end

	if self.cascade_trigger == true then
		local halves_still_falling = self:grav_halves()
		self.cascade_trigger = halves_still_falling

		if halves_still_falling == true then
			return
		end
	end

	self:count_x_rle()
	self:count_y_rle()
	local to_remove = self:remove_marked()
	if to_remove > 0 then
		self:increment_combo()
		return
	end

	if self.active_pill == nil then
		if self.combo > 1 then
			self:send_surprises(self.combo, self.target)
		elseif self.next_pill ~= nil then
			self:spawn_pill(self.next_pill)
			self.next_pill = nil
		end
		self:reset_combo()
	else
		self:grav()
	end

	if self.next_pill == nil then
		self:generate_next_pill()
	end
end

function Grid:send_surprises(combo, target)
	local victim = 0
	if Game.players == 2 then
		if self.player == 1 then
			victim = 2
		else
			victim = 1
		end

		Game.send_surprises(victim, combo)
		return
	end

	Console.log("target: " .. target)
	if target == TARGETS.LEADER then
		victim = Game.find_leader(self.player)
	elseif target == TARGETS.RANDOM then
		victim = Game.find_random(self.player)
	else
		victim = target
	end

	Game.send_surprises(victim, combo)
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
	local removed_counter = 0

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

				table.insert(
					to_remove_diff,
					{ x = x, y = y, color = board_copy[y][x].color, type = board_copy[y][x].type }
				)

				removed_counter = removed_counter + 1
			end

			::continue::
		end
	end

	for _, pos in ipairs(to_convert_diff) do
		local cell = self.board[pos.y][pos.x]
		if cell then
			cell.type = CELL_TYPES.HALF
			cell.spr = Assets.sprites.pieces.halves[cell.color]
		end
	end

	for _, diff in ipairs(to_remove_diff) do
		self.board[diff.y][diff.x] = nil
		local cx = self:cx(diff.x)
		local cy = self:cy(diff.y)
		spr(Assets.sprites.ui.border.center, cx, cy, 0)

		self:add_animation_to_queue(ANIMATIONS.DISAPPEARING_PILL, {
			x = diff.x,
			y = diff.y,
			color = diff.color,
		})
	end

	if removed_counter > 0 then
		self.cascade_trigger = true
		self:count_stones()
	end

	return removed_counter
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
		spr(Assets.sprites.ui.menu_cursor, 80, y - 2)
	end
	print(txt, x, y, 8, true)
end

function Menu:get_offset(i)
	local center_index = (#self.options + 1) // 2
	return (i - center_index) * self.options_padding
end

function Menu:draw()
	for i, option in ipairs(self.options) do
		self:print_item(option.label, i == self.selected_option, self:get_offset(i))
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
	print(KEYMAPS[player_index])
end

local main_menu
local players_menu

players_menu = Menu:new({
	options = {
		{
			label = "2 PLAYERS",
			callback = function()
				Game.setup_game(2)
			end,
		},
		{
			label = "3 PLAYERS",
			callback = function()
				Game.setup_game(3)
			end,
		},
		{
			label = "4 PLAYERS",
			callback = function()
				Game.setup_game(4)
			end,
		},
		{
			label = "BACK",
			callback = function()
				Game.menu = main_menu
			end,
		},
	},
})

main_menu = Menu:new({
	options = {
		{
			label = "VS GAME",
			callback = function()
				Game.menu = players_menu
				Game.mode = MODES.VS
			end,
		},
		{
			label = "VS GAME",
			callback = function()
				Game.menu = players_menu
				Game.mode = MODES.VS
			end,
		},
	},
})

Game.menu = main_menu

function Grid:update()
	local keys = KEYMAPS[self.player]
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
		self:log_state()
	end
	if Game.players > 2 and btnp(keys.SUPER) then
		self:cycle_target()

		-- Game.send_surprises(2, 3)
		-- for testing
	end

	local effective_interval = self.interval
	if btn(keys.DOWN) and self.active_pill ~= nil then
		effective_interval = self.interval / 10
	elseif self.active_pill == nil then
		effective_interval = self.interval / 5
	end

	if btnp(keys.UP) then
		self:drop_pill()
	end

	if t % effective_interval == 0 then
		if self.is_paused ~= true and self.game_over ~= true then
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
	local keys = KEYMAPS[self.player]
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
	self:draw_static_pills()
	self:draw_active_pill()
	self:draw_halves()
	self:draw_queued_surprises()
	self:draw_character(t)
	self:draw_score()
	self:draw_next_pill()
	self:draw_target()
end

function TIC()
	Audio.play_bgm(Assets.music.fever)
	Console.update()
	cls(0)

	if Game.scene == SCENES.MENU then
		Game.menu:update()
		Game.menu:draw()
	elseif Game.scene == SCENES.PARAMS then
		Game.update_params()
		Game.draw_params()
	elseif Game.scene == SCENES.GAME then
		if Game.grids_spawned then
			Game.update_grids()
			Game.draw_grids()
			Game.animate_grids()
		else
			Game.spawn_grids()
		end
	end

	t = t + 1
	Console.draw()
end

-- <TILES>
-- 000:0000cccc000c112100c112120c11255100cc5c55000c5a55000c55550000cccc
-- 001:ccccc00022222c00122222c0212222c0c52222c0a55152c0555cccc0ccc00000
-- 002:0000cc00000c2ccc000c112100c112120c11255100cc5c55000c5a55000c5555
-- 003:00000000ccccc00022222c00122222c0212222c0c52222c0a55152c0555cccc0
-- 004:0000c000000c1ccc000c112100c112120c11255100cc5c55000c5a55000c5555
-- 005:00000000ccccc00022222c00122222c0212222c0c52222c0a55152c0555cccc0
-- 006:00000000000ccccc000c112100c112120c11255100cc5c55000c5a55000c5555
-- 007:00000000ccccc00022222c00122222c0212222c0c52222c0a55152c0555cccc0
-- 008:0000c000000c1ccc000c112100c112120c11255100cc5c55000c5a55050c5555
-- 009:00000000ccccc00022222c00122222c0212222c0c52222c0a55152c5555cccc0
-- 010:0000c000000c1ccc000c112100c112120c11255100cc5555000ccc55000c5555
-- 011:00000000ccccc00022222c00122222c0212222c0552222c0cc5152c0555cccc0
-- 012:0000c000000c1ccc000c112100c112120c112c5100cc5a55000c5555000c5555
-- 013:00000000ccc8c80022282800122b2bc0c12222c0a52222c0555152c0555cccc0
-- 014:0000cccc000c112100c112120c112c5100cc5a55000c5555000c55550005cccc
-- 015:cccccc0022282800122b2bc0c12222c0a52222c0555152c0555cccc0ccc50000
-- 016:0000000000000ccc005ccc0c000000ca00000caa0000ccaa0000ca9a0000c9a9
-- 017:cc000000aacc0000aacccc00aaac00c0aaac0050aaaac000aaaac000aaaac000
-- 018:0000cccc000000cc005ccc0c000000ca00000caa0000ccaa0000ca9a0000c9a9
-- 019:cccc0000ccc00000aacccc00aaac00c0aaac0050aaaac000aaaac000aaaac000
-- 020:0000cccc0000000000500ccc000ccc0c000000ca00000caa0000ccaa0000ca9a
-- 021:ccc00000cc000000aacc0000aacccc00aaac00c0aaac0050aaaac000aaaac000
-- 022:0000cccc00000ccc0000cc0c008c00ca00000caa0000ccaa0000ca9a0000c9a9
-- 023:cc000000aacc0000aaccc000aaac0c00aaac00c0aaaac080aaaac000aaaac000
-- 024:00c0cccc000cc0000000cccc000000ca00000caa00000caa0000ca9a000caaa9
-- 025:ccc00cc0cc00cc00aaccc000aaac0000aaac0000aaaac000aaaac000aaaac000
-- 026:0000cccc000000000000000c000000cc000000ca00000cca0000ccaa0000cc9a
-- 027:ccc00000cc000000aac00000aacc0000aacc0000aacc0000aacac000aacac000
-- 028:0005cccc000cc0000000cccc000000cc000000ca00000caa0000ccaa0000ca9a
-- 029:ccc50000cc0c0000aacc0000aacc0000aacc0000aaac0000aaaac000aaaac000
-- 030:000cc0000000cccc000000cc000000ca00000caa00000caa00000caa0000ca9a
-- 031:cc0c0000aacc0000aacc0000aacc0000aaac0000aaaac000aaaac000aaaac000
-- 032:00000ccc000000cc000000cc000000cc0000000c0000000c0000cc0c0000cccc
-- 033:ccccc0000ccc00000cc000000cc000000c0000000c0000000ccc00000ccc0000
-- 034:00000ccc000000cc000000cc000000cc0000000c0000000c0000cc0c0000cccc
-- 035:ccccc0000ccc00000cc000000cc000000c0000000c0000000ccc00000ccc0000
-- 036:0000c9a900000ccc000000cc000000cc0000000c0000000c0000cc0c0000cccc
-- 037:aaaac000ccccc0000ccc00000cc000000c0000000c0000000ccc00000ccc0000
-- 038:00000ccc000000cc000000cc000000cc0000000c0000000c0000cc0c0000cccc
-- 039:ccccc0000ccc00000cc000000cc000000c0000000c0000000ccc00000ccc0000
-- 040:00ccccaa0cc00ccc0c00000c0c00000cccc0000cccc00000000000000000000c
-- 041:aaac0000cccc0000c00000000000000000000000c0000000cc000000cc000000
-- 042:000005cc000000cc000000cc000000cc0000000c0000000c0000cc0c0000cccc
-- 043:cc5cc0000ccc00000cc000000cc000000c0000000c0000000ccc00000ccc0000
-- 044:0000c9a900000ccc000000cc000000cc0000000c0000000c0000cc0c0000cccc
-- 045:aaaac000cccc00000cc000000cc000000c0000000c0000000ccc00000ccc0000
-- 046:0000c9a900000ccc000000cc000000cc0000000c0000000c0000cc0c0000cccc
-- 047:aaaac000cccc00000cc000000cc000000c0000000c0000000ccc00000ccc0000
-- 048:0000cccc000c447400c447470c44745700c45c5500c4565500c4555500c7cccc
-- 049:ccccc000777b7c004777b7c0747777c0c57777c0655a57c05554ccc0ccc7c000
-- 050:00000ccc0000c447000c447400c44745000c45c5000c4565000c7555000c7ccc
-- 051:cccccc004777b7c074777b7c7747777c5c57777c5655a57c55554ccccccc7c00
-- 052:00000ccc0000c447000c447400c44745000c45c5000c4565000c4555000c7ccc
-- 053:cccccc004777b7c074777b7c7747777c5c57777c5655a57c55554ccccccc7c00
-- 054:0000cccc000c447400c447470c44745700c45c5500c4565500c4555500c7cccc
-- 055:ccccc000777b7c004777b7c0747777c0c57777c0655a57c05554ccc0ccc7c000
-- 056:cc000000cbc00cccc7ccc4470c77447400c77745000c75c5000c45650500c555
-- 057:0c7c0000ccbccc004cc7b7c074c77b7c77cc777c5c5c777c5655a57c55554cc5
-- 058:000000000000cccc000c447400c447470c44745700c4555500c4cc5500c45555
-- 059:00000000ccccc000777b7c004777b7c0747777c0557777c0cc5a57c05554ccc0
-- 060:0000000000808ccc008c847400b4b7470c447c5700c4565500c4555500c45555
-- 061:00000000ccccc000777b7c004777b7c0c47777c0657777c0555a57c05554ccc0
-- 062:0000cccc008c847400b4b7470c447c5700c4565500c4555500c4555500c5cccc
-- 063:ccccc000777b7c004777b7c0c47777c0657777c0555a57c05554ccc0ccc75000
-- 064:00c7c000000b000c00c7c0cc00ccc0c300000c3300000c330000c3c30000c335
-- 065:ccc7c000c3c7c000333b00003337c000333cc00033c3c0003c33c0005333c000
-- 066:000c7c00000b7c0000c7c00c00cc00c300000cc300000cc300000cc30000c338
-- 067:ccc77c00c3c7cc003337c000333bcc003333cc00333c3c003cc33c0083333c00
-- 068:000c7c000000b000000c7c0c000ccccc00000cc300000cc300000c3c0000c333
-- 069:0ccc7c00cc3c7c00c333b00033337c003333cc00333cc00033c3c0005533c000
-- 070:00c7c000000cbc0c000c7ccc0000ccc300000c3300000cc30000c33c0000c333
-- 071:ccc7c000c3c7c000333cb000333c7c00333cc000333cc00033c3c0005533c000
-- 072:00cc0ccc0000cc00000000cc0000000c000000c300000cc30000c233000c2233
-- 073:cccc00c0cc00cc00c3ccc000333cc0003333cc003333cc0033333c0033333c00
-- 074:00c7cccc00c7c00c00c7c0cc00cbc0c300c4ccc300cccc330000cc33000c3533
-- 075:ccc7c0003cc7c00033c7c00033cbc00033c4c00033ccc00033c3c0003353c000
-- 076:00c5cccc00c7c000000b0ccc00c7c0cc00ccc0c300000c330000c3330000c333
-- 077:ccc75000ccc7c000c3c70000333b00003337c0003333c0003333c0003333c000
-- 078:00c7c000000b0ccc00c7c0cc00ccc0c300000c3300000c330000c333000c2333
-- 079:ccc7c000c3c7c000333b00003337c0003333c0003333c0003333c00033333c00
-- 080:000c2333000c323300c2232300cccccc0000000c0000000c0000000c000002cc
-- 081:33333c0033333c00333333c0cccccc000c0000000c0000000c0000000c200000
-- 082:000c2333000c323300c2232300cccccc0000000c0000000c0000000c000002cc
-- 083:33333c0033333c00333333c0cccccc000c0000000c0000000c0000000c200000
-- 084:000c2333000c323300c2232300cccccc0000000c0000000c0000000c000002cc
-- 085:33333c0033333c00333333c0cccccc000c0000000c0000000c0000000c200000
-- 086:000c2333000c323300c2232300cccccc0000000c0000000c0000000c000002cc
-- 087:33333c0033333c00333333c0cccccc000c0000000c0000000c0000000c200000
-- 088:000ccc230000cccc00cc0ccc0cc0000020000000000000000000000000000000
-- 089:33333c0032333c00cc3333c0cccccc00c00000000c0000000020000000000000
-- 090:000c2333000c323300c2232300cccccc0000000c0000000c0000000c000002cc
-- 091:3333c0003333c00033333c00cccccc000c0000000c0000000c0000000c200000
-- 092:000c2333000c323300c2232300cccccc0000000c0000000c0000000c000002cc
-- 093:33333c0033333c00333333c0cccccc000c0000000c0000000c0000000c200000
-- 094:000c323300c2232300cccccc0000000c0000000c0000000c0000000c000002cc
-- 095:33333c00333333c0cccccc000c0000000c0000000c0000000c0000000c200000
-- 096:000000cc00000c770000c747000cc47400cc474700c4cccc0ccc5c550c4c5255
-- 097:ccccccc077777cc0777777cc7777c77c4777cc7cccc777c0c5ccc77c2551cc7c
-- 098:00000000000000cc00000c770000c747000cc47400cc474700c4cccc0ccc5c55
-- 099:00000000ccccccc0777777cc7777777c7777c77c4777ccc0ccc777c0c5ccc77c
-- 100:00000000000000cc00000c770000c747000cc47400cc474700c4cccc0ccc5c55
-- 101:0cccccccccc7777c777777c0777777c07777c7c04777ccc0ccc777c0c5ccc77c
-- 102:00000000000000cc00000c770000c747000cc47400cc474700c4cccc0ccc5c55
-- 103:00000000ccccccc0777777cc7777777c7777c77c4777ccc0ccc777c0c5ccc77c
-- 104:000000cc00000c770000c747000cc47400cc474700c444740cc444440c4ccccc
-- 105:ccccccc077777cc0777777cc7777c77c4777cc7c747777c04447c77ccccccc7c
-- 106:00000000000000cc00000c770000c747000cc47400cc474700c4cccc0ccc5555
-- 107:00000000ccccccc077777cc0777777cc7777c77c4777cc7cccc777c055ccc77c
-- 108:00000000000000cc08080c770808c7470b0bcccc00cccc5500cc52550ccc5555
-- 109:00000000ccccccc077777cc0777777cccc77c77cc5c7cc7c255c77c0555cc77c
-- 110:000000cc00000c770808c7470b0bcccc00cccc5500cc52550ccc55550c4c5555
-- 111:ccccccc077777cc0777777cccc77c77cc5c7cc7c255c77c0555cc77c555ccc7c
-- 112:0c4c555500c4cccc00cc44440000ccc700000c7700000c7790000c770c00cc77
-- 113:5551c47ccccc47cc44477cc07cccc00077c0000077cc0000777c0000777c0000
-- 114:0c4c52550c4c555500c4cccc00cc44440000ccc700000c7700000c77a000cc77
-- 115:2551cc7c5551c47ccccc47cc44477cc07cccc00077cc0000777c0000777c0000
-- 116:0c4c51550c4c555500c4cccc00cc44440000ccc700000c7700000c7700000c77
-- 117:1551cc7c5551c47ccccc47cc44477cc07cccc00077cc000077cc0000777c0000
-- 118:0c4c52550c4c555500c4cccc00cc44440000ccc700000c7700000c77a000cc77
-- 119:2551cc7c5551c47ccccc47cc44477cc07cccc00077cc0000777c0000777c0000
-- 120:0c4c525500c4cccc00cc44440000ccc700000c7700000c770000c777000c7777
-- 121:2551c47ccccc47cc44477cc07cccc00077c0000077c0000077c00000777c0000
-- 122:0c4ccc550c4c555500c4cccc00cc44440000ccc700000c7700000c770000cc77
-- 123:cc51cc7c5551c47ccccc47cc44477cc077ccc00077cc0000777c0000777c0000
-- 124:0c4c55550c4c155500c4cccc00cc44440000ccc700000c770000c7770000c777
-- 125:555ccc7c5511c47ccccc47cc44477cc07cccc00077c0000077c00000777c0000
-- 126:0c4c155500c4cccc00cc44440000ccc700000c7700000c770000c7770000c777
-- 127:5511c47ccccc47cc44477cc07cccc00077c0000077c0000077c00000777c0000
-- 128:00c0cc74000cc4470000c4440000c4470000c4c40000000c0000cc0c0000cccc
-- 129:7777c0004777c00074777c00477777c074cc7c004c00c0000ccc00000ccc0000
-- 130:0cc0cc74000cc4470000c4440000c4470000c4c40000000c0000cc0c0000cccc
-- 131:777cc0004777c00074777c00477777c074cc7c004c00c0000ccc00000ccc0000
-- 132:b000cc770cc0cc74000cc4470000c4440000c447000000c40000cc0c0000cccc
-- 133:777c00007777c00047777c00747777c047777c0074ccc0000ccc00000ccc0000
-- 134:0cc0cc74000cc4470000c4440000c4470000c4c40000000c0000cc0c0000cccc
-- 135:777cc00047777c0074777c00477777c074cc7c004c00c0000ccc00000ccc0000
-- 136:00c4477700c474770c4447470ccc44c7000c4ccc0000cccc00000c00000000c0
-- 137:777c0000777cc0007777cc0077777c00c77cccc00ccc00000cc00000cc000000
-- 138:0000cc74000cc447000cc44400c0c4470900c4c40000000c0000cc0c0000cccc
-- 139:777c0000477cc0007477c0004777c00074cc7c004c00c0000ccc00000ccc0000
-- 140:0000c7740000c4470000c4440000c4470000c4c40000000c0000cc0c0000cccc
-- 141:777cc00047777c0074777c00477777c074cc7c004c00c0000ccc00000ccc0000
-- 142:0000c7740000c4470000c4440000c4470000c4c40000000c0000cc0c0000cccc
-- 143:777cc00047777c0074777c00477777c074cc7c004c00c0000ccc00000ccc0000
-- 144:00000ccc000ccccc00cccc930c4777930c44ccccc4cc5c550cc65b5500c65555
-- 145:ccccccc0cc7777cc9cccc77c9777ccccccc777c0c5ccc77cb556cccc555666cc
-- 146:00000000000000cc000ccccc00cccc930c4777930c44ccccc4cc5c550cc65b55
-- 147:ccccc000c7777cc0cc77777c9cccccc09777cc00ccc777c0c5ccc77cb556cccc
-- 148:0000000c00000ccc000ccccc00cccc930c4777930c44ccccc4cc5c550cc65b55
-- 149:cccc0000c77cccc0cc77777c9cccc7c09777ccc0ccc777c0c5ccc77cb556cccc
-- 150:0000000000000ccc000ccccc00cccc930c4777930c44ccccc4cc5c550cc65b55
-- 151:00000000ccccccc0cc7777cc9cccc77c9777ccccccc777c0c5ccc77cb556cccc
-- 152:000000000000000c0c000c77c6cccc936c4777936c44ccccc4cc5555c4c65c55
-- 153:0ccc0000cc77c0007777c0009ccc7c0c9777ccc6ccc77c6655c777c6c55c777c
-- 154:0000000000000ccc000ccccc00cccc930c4777930c44cccc0ccc55550cc6cc55
-- 155:00000000ccccccc0cc7777cc9cccc77c9777ccccccc777c055ccc77ccc56ccc7
-- 156:000000000000000c00000c77000ccc9300c777930c44ccccc44c5c550cc65b55
-- 157:00000000cccc00007778c8009cc87800977bcb00cc777c00c5c77c00b55c77c0
-- 158:0000000c00000c77000ccc9300c777930c44ccccc44c5c550cc65b5500c65555
-- 159:cccc00007777c0009cc87800977bcb00cc777c00c5c77c00b55c77c0555c777c
-- 160:00c6cccc30c64444c0c6644c0c0c66cc0c00cc7705ccc44700000cc4000000c9
-- 161:cccc666cc444cc6c7c444c6c7cc44c6c77ccc66c777cccc07777c000399c0500
-- 162:00c6555560c6ccccc0c6644c0c0c66cc0c00cc7705ccc44700000cc4000000c9
-- 163:555666cccccc666c7c444c6c7cc44c6c77ccc66c777cccc07777c000399c0500
-- 164:00c6555500c6cccc00c6444450c6644cc00c66cc0c00cc770c00c44705cc0cc4
-- 165:555666cccccc666cc444cc6c7c444c6c7cc44c6c77ccc66c777cc0c0399c0c00
-- 166:00c6555500c6cccc60c64444c0c6644c0c0c66cc0c00cc7705ccc447000000c9
-- 167:555666cccccc666cc444cc6c7c444c6c7cc44c6c77ccc66c777cccc0399c0500
-- 168:05465b550cc6555500cccccc000cc0000000cc0c00000ccc00000c770000c447
-- 169:b556cc7755564c5ccccc0cc0c000cc007c0cc0007ccc000077c0000077c00000
-- 170:00c6555500c6cccc00c6444400c6644c000c66cc0000cc7700000c4700000cc9
-- 171:555666cccccc666cc444cc6c7c444c6c7cc44c6c77ccc66c777c0cc039cc0000
-- 172:00c6555500c6555500c5cccc00ccc44400c6cc4c000c6ccc0000cc7700000c47
-- 173:555c777c5554c6ccccc5666cc44ccc6c7ccc4c6c7cc44c6c7cccc66c777c0cc0
-- 174:00c6555500c5cccc00ccc44400c6cc4c000c6ccc0000cc7700000c4700000cc9
-- 175:5554c6ccccc5666cc44ccc6c7ccc4c6c7cc44c6c7cccc66c777c0cc039cc0000
-- 176:00000c470000c47400c44447000ccccc0000000c0000000c0000000c000009cc
-- 177:7777c00077777c0047777c00747777c00ccccc000c0000000c0000000c900000
-- 178:00000c470000c47400c44447000ccccc0000000c0000000c0000000c000009cc
-- 179:7777c00077777c0047777c00747777c00ccccc000c0000000c0000000c900000
-- 180:000000c900000c470000c47400c44447000ccccc0000000c0000000c000009cc
-- 181:399c05007777c00077777c0047777c00747777c00ccccc000c0000000c900000
-- 182:00000c470000c47400c44447000ccccc0000000c0000000c0000000c000009cc
-- 183:7777c00077777c0047777c00747777c00ccccc000c0000000c0000000c900000
-- 184:000c999300c444470c44447400ccc447000c0ccc00c000c00c000c0090009000
-- 185:99c00000777c0000777c0000477c0000747c0000cccc00000000000000000000
-- 186:00000cc70000c4c500c44447000ccccc0000000c0000000c0000000c000009cc
-- 187:7cc7c0005c777c0047777c00747777c00ccccc000c0000000c0000000c900000
-- 188:00000cc900000c470000c444000c444700c44444000ccccc0000000c000009cc
-- 189:39cc00007777c00077777c0047777c00747777c00ccccc000c0000000c900000
-- 190:00000c470000c444000c444700c44444000ccccc0000000c0000000c000009cc
-- 191:7777c00077777c0047777c00747777c00ccccc000c0000000c0000000c900000
-- 192:000ccccc00cc474700c4cccc0ccc5c550c4c52550c4c555500c4cccc00cc4444
-- 193:ccccccc0477777ccccc7777cc5ccc77c2551cc7c5551c47ccccc47cc44477cc0
-- 194:000000000000000c000000cd000cccdd00cecddd00ceeded000ccede00000ccc
-- 195:cccc00008888cc0088888cc0888888c0d88888ccdd88d88cdddddcc0ccccc000
-- 196:000000000000e000000e00000000000e00000000000000e000000e0000000000
-- 197:000000000000e000e00e0000000000000e000000e0000000000e0000e0e00000
-- 198:00000000000000e0000e000000e0000e000000e00000000000000e0e0000e000
-- 199:0000000000000000000e000000e0000000000000e00000000000000000e00000
-- 200:00000000000000e000000e0000e000000e0000e000000e000000000e0000e0e0
-- 201:000000000000e0000000000000e000000e00000000000000000e000000000000
-- 202:000000000000000000000e000000e0000e00000000000e000000e000000000e0
-- 203:000000000000e000000e0000000000000e000000e0000000000e000000e00000
-- 204:0000000000000000000000000000e000000e0000e00000000000e000000e0000
-- 205:00000e000e00e000e000000000e000000e0000000000e0000e0e000000000000
-- 206:000ccccc00cccc930c4777930c44ccccc4cc5c550cc65b5500c6555500c6cccc
-- 207:cc7777cc9cccc77c9777ccccccc777ccc5ccc77cb556ccc7555666cccccc666c
-- 208:0000cccc000cc12100cc12120cc1225100cc25c5000c55a5050cc55500c0cccc
-- 209:ccccc00022222c00122222c0215222c05c5522c05a5552c55555ccc0cccc0cc0
-- 210:0000cccc000cc12100cc12120cc1225100cc25c5000c55a5005cc555000ccccc
-- 211:ccccc00022222c00122222c0215222c05c5522c05a5552c05555cc00cccc0c50
-- 212:0000cccc000c447400c4474700c4445500c445c500c4556500cc4555000c7ccc
-- 213:ccccc00077b74c00477b74c0547777c05c5477c0565547c05554ccc0ccc7c000
-- 214:000000000000cccc000c447400c4474700c4445500c445c500c4556500cc4555
-- 215:00000000ccccc00077b74c00477b74c0547777c05c5477c0565547c05554ccc0
-- 216:0000000000000ccc0000cc77000cc747000cc47400cc4ccc0cc4c5550c4c55c5
-- 217:00000000ccccc0007777cc0077777c007777c7c0ccc7ccc0555c77c05c55c77c
-- 218:00000ccc0000cc77000cc747000cc47400cc44440cc4cccc0c4c15c50c4c5525
-- 219:ccccc0007777cc0077777c007777c7c04447ccc0cccc77c05c51c77c5255cc7c
-- 220:00000ccc000ccccc00cccc930c4777930c44ccccc4cc5c550cc65b5500c65555
-- 221:ccccccc0cc7777cc9cccc77c9777ccccccc777c0c5ccc77cb556cccc555666cc
-- 222:00000ccc000ccccc00cccc930c4777930c44ccccc4cc5c550cc65b5500c65555
-- 223:ccccccc0cc7777cc9cccc77c9777ccccccc777c0c5ccc77cb556cccc555666cc
-- 224:000cc0000000cccc000000ca000000ca00000caa00000caa0000ca9a000c99a9
-- 225:cc00cc00aaccc000aac00000aaac0000aaac0000aaaac000aaaac000aaaac000
-- 226:000c000c0000ccca00000caa00000caa0000caaa0000caaa000c9a9a000c9aa9
-- 227:c000c000accc0000ac000000aac00000aac00000aaac0000aaac0000aaaac000
-- 228:050c7c0000c0b00c000c7ccc0000ccc300000c2300000c330000c2330000c333
-- 229:ccc7c050c3c7cc00333bc000333700003333c0003333c0003333c0003333c000
-- 230:000c7ccc000c7c000500b00c00cc7ccc0000ccc300000c2300000c330000c233
-- 231:ccc7c000ccc7c000c3c7c005333bccc0333700003333c0003333c0003333c000
-- 232:0c4c55250c4c155500c4cccc00cc44440000ccc700000c7700000c7700000c77
-- 233:5255cc7c5551c47ccccc47cc44477cc07cccc00077c0000077cc0000777c0000
-- 234:0c4c155500c4cccc00cc44440000ccc700000c7700000c7700000c7700000c77
-- 235:5551c47ccccc47cc44477cc07cccc00077c0000077cc0000777c0000777c0000
-- 236:00c6cccc30c64444c0c6644c0c0c66cc0c00cc7705ccc44700000cc4000000c9
-- 237:cccc666cc444cc6c7c444c6c7cc44c6c77ccc66c777cccc07777c000399c0500
-- 238:00c6cccc30c64444c0c6644c0c0c66cc0c00cc7705ccc44700000cc4000000c9
-- 239:cccc666cc444cc6c7c444c6c7cc44c6c77ccc66c777cccc07777c000399c0500
-- 240:0000cccc000000cc000000cc000000cc0000000c0000000c0000cc0c0000cccc
-- 241:ccccc0000ccc00000cc000000cc000000c0000000c0000000ccc00000ccc0000
-- 242:0000cccc000000cc000000cc000000cc0000000c0000000c0000cc0c0000cccc
-- 243:ccccc0000ccc00000cc000000cc000000c0000000c0000000ccc00000ccc0000
-- 244:000c2333000c323300c2232300cccccc0000000c0000000c0000000c000002cc
-- 245:33333c0033333c00333333c0ccccccc00c0000000c0000000c0000000c200000
-- 246:0000c333000c2333000c323300c2232300cccccc0000000c0000000c000002cc
-- 247:3333c00033333c0033333c00333333c0cccccc000c0000000c0000000c200000
-- 248:0000cc770000cc740000c4440000c4470000ccc40000000c0000cc0c0000cccc
-- 249:777c0000777cc0007477c0004777c00074ccc0004c0000000ccc00000ccc0000
-- 250:0000cc770000cc740000c4440000c4470000ccc40000000c0000cc0c0000cccc
-- 251:777c0000777cc0007477c0004777c00074ccc0004c0000000ccc00000ccc0000
-- 252:00000c470000c47400c44447000ccccc0000000c0000000c0000000c000009cc
-- 253:7777c00077777c0047777c00747777c00ccccc000c0000000c0000000c900000
-- 254:00000c470000c47400c44447000ccccc0000000c0000000c0000000c000009cc
-- 255:7777c00077777c0047777c00747777c00ccccc000c0000000c0000000c900000
-- </TILES>

-- <SPRITES>
-- 000:00ccccc00cc332cccc23232cc223232cc223322cc123232ccc1311cc0cccccc0
-- 001:00ccccc00cc33dcccc23232cc223232cc223322cc123232ccc1311cc0cccccc0
-- 002:00ccccc00cc33dcccce3e3dcc22323ecc223322cc123232ccc1311cc0cccccc0
-- 003:00ccccc00cc33dcccce3e3dccee3e3ecc22332ecc122232ccc1211cc0cccccc0
-- 004:00ccccc00cc33dcccce3e3dccee2e2ecc2e22eecc122e2eccc1211cc0cccccc0
-- 005:00ccccc00cc33dcccce2e2dccee2e2ecc2e22eecc122e2eccc1211cc0cccccc0
-- 006:00ccccc00cc22dcccce2e2dccee2e2eccee22eeccfe2e2ecccf2ffcc0cccccc0
-- 014:0cccccccccffffffcfffffffcfffffffcfffffffcfffffffcfffffffcfffffff
-- 015:ccccccc0ffffffccffffeffcfffffefcfffffffcfffffffcfffffffcfffffffc
-- 016:0ccccc00cc665cc0c66566ccc655556cc766566cc775666ccc5777cc0cccccc0
-- 017:0ccccc00cced5cc0c665eeccc655556cc766566cc775666ccc5777cc0cccccc0
-- 018:0ccccc00cced5cc0cee5eeccc65555ecc766566cc775666ccc5777cc0cccccc0
-- 019:0ccccc00cced5cc0cee5eeccce5555ecc7ee5eecc775666ccc6777cc0cccccc0
-- 020:0ccccc00cced5cc0cee5eeccce5555ecceee6eecc7e6eeeccc6777cc0cccccc0
-- 021:0ccccc00cced5cc0cee5eeccce6666ecceee6eeccfe6eeeccc6fffcc0cccccc0
-- 022:0ccccc00cced6cc0cee6eeccce6666ecceee6eeccff6eeeccc6fffcc0cccccc0
-- 030:cfffffffcfffffffcfffffffcfffffffcfcfffffcffcffffccffffff0ccccccc
-- 031:fffffffcfffffffcfffffffcfffffffcfffffffcfffffffcffffffccccccccc0
-- 032:0ccccc00ccabacc0caabbacccaababaccbabaabcc9bbaaaccc9b99cc0cccccc0
-- 033:0ccccc00ccabdcc0caabbecccaababaccbabaabcc9bbaaaccc9b99cc0cccccc0
-- 034:0ccccc00ccebdcc0caabbecccaabebeccbabaabcc9bbaaaccc9b99cc0cccccc0
-- 035:0ccccc00ccebdcc0ceebbdcccaabebeccbabeebcc9bbaaeccc9b99cc0cccccc0
-- 036:0ccccc00ccebdcc0ceebbeccceebebeccaeaeebcc9aaeeeccc9a99cc0cccccc0
-- 037:0ccccc00ccebdcc0ceeabeccceeaebeccaeaeeaccfaaeeecccfaffcc0cccccc0
-- 038:0ccccc00cceadcc0ceeaaeccceeaeaeccaeaeeaccfaaeeecccfaffcc0cccccc0
-- 078:f000000000000000f000000000000000f000000000000000f000000000000000
-- 079:0000000f000000000000000f000000000000000f000000000000000f00000000
-- 094:f0000000f0000000f0000000f0000000f0000000f0000000f0000000f0000000
-- 095:0000000f0000000f0000000f0000000f0000000f0000000f0000000f0000000f
-- 096:0000000060000000656000006656600066666660666660006660000060000000
-- 109:f000000f00000000f000000f00000000f000000f00000000f000000f00000000
-- 110:e0000000e0000000e0000000e0000000e0000000e0000000e0000000e0000000
-- 111:0000000e0000000e0000000e0000000e0000000e0000000e0000000e0000000e
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
-- 124:d000000dd000000dd000000dd000000dd000000dd000000dd000000dd000000d
-- 125:f000000ff000000ff000000ff000000ff000000ff000000ff000000ff000000f
-- 126:d0000000d0000000d0000000d0000000d0000000d0000000d0000000d0000000
-- 127:0000000d0000000d0000000d0000000d0000000d0000000d0000000d0000000d
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
-- 140:8000000880000008800000088000000880000008800000088000000880000008
-- 141:e000000ee000000ee000000ee000000ee000000ee000000ee000000ee000000e
-- 142:8000000080000000800000008000000080000000800000008000000080000000
-- 143:0000000800000008000000080000000800000008000000080000000800000008
-- 144:0111111011000011100030011000030110300001100300011100001101111110
-- 145:0222222022000022200030022000030220300002200300022200002202222220
-- 146:0333333033000033300030033000030330300003300300033300003303333330
-- 147:09999990990000999000b00990000b0990b00009900b00099900009909999990
-- 148:0aaaaaa0aa0000aaa000b00aa0000b0aa0b0000aa00b000aaa0000aa0aaaaaa0
-- 149:0bbbbbb0bb0000bbb000b00bb0000b0bb0b0000bb00b000bbb0000bb0bbbbbb0
-- 150:0777777077000077700050077000050770500007700500077700007707777770
-- 151:0666666066000066600050066000050660500006600500066600006606666660
-- 152:0555555055000055500050055000050550500005500500055500005505555550
-- 153:0dddddd0dd0000ddd000d00dd0000d0dd0d0000dd00d000ddd0000dd0dddddd0
-- 154:00000000000000000000000000000000000000000000000000d00d000d0000d0
-- 155:000000000000000000000000000000000000000000d00d000de00ed00e0000e0
-- 156:00000000000000000000000000000000000000000dd00dd00ee00ee000000000
-- 157:00000000000000000000000000000000000000000d0000d000d00d0000000000
-- 158:0000000000000000000000000000000000000000000000000e0000e000e00e00
-- 159:000000000000000000000000000000000000000000000000000000000e0000e0
-- 160:0111111111000000100003331000000010300000100300001100000001111111
-- 161:1111111000000011300030010000030100000001000000010000001111111110
-- 162:0333333333000000300003333000000030300000300300003300000003333333
-- 163:3333333000000033300030030000030300000003000000030000003333333330
-- 164:0aaaaaaaaa000000a0000bbba0000000a0b00000a00b0000aa0000000aaaaaaa
-- 165:aaaaaaa0000000aab000b00a00000b0a0000000a0000000a000000aaaaaaaaa0
-- 166:0777777777000000700005557000000070500000700500007700000007777777
-- 167:7777777000000077500050070000050700000007000000070000007777777770
-- 168:0555555555000000500005555000000050500000500500005500000005555555
-- 169:5555555000000055500050050000050500000005000000050000005555555550
-- 170:00000000000000000000000000000000000000000000000000d00d000d0000d0
-- 171:000000000000000000000000000000000000000000d00d000de00ed00e0000e0
-- 172:00000000000000000000000000000000000000000dd00dd00ee00ee000000000
-- 173:00000000000000000000000000000000000000000d0000d000d00d0000000000
-- 174:0000000000000000000000000000000000000000000000000e0000e000e00e00
-- 175:000000000000000000000000000000000000000000000000000000000e0000e0
-- 176:0222222222000000200003332000000020300000200300002200000002222222
-- 177:2222222000000022300030020000030200000002000000020000002222222220
-- 178:099999999900000090000bbb9000000090b00000900b00009900000009999999
-- 179:9999999000000099b000b00900000b0900000009000000090000009999999990
-- 180:0bbbbbbbbb000000b0000bbbb0000000b0b00000b00b0000bb0000000bbbbbbb
-- 181:bbbbbbb0000000bbb000b00b00000b0b0000000b0000000b000000bbbbbbbbb0
-- 182:0666666666000000600005556000000060500000600500006600000006666666
-- 183:6666666000000066500050060000050600000006000000060000006666666660
-- 184:0ddddddddd000000d0000dddd0000000d0d00000d00d0000dd0000000ddddddd
-- 185:ddddddd0000000ddd000d00d00000d0d0000000d0000000d000000ddddddddd0
-- 190:0eeeeeeeee000000e0000ddde0000000e0d00000e00d0000ee0000000eeeeeee
-- 191:eeeeeee0000000eed000d00e00000d0e0000000e0000000e000000eeeeeeeee0
-- 192:0111111011000011100030011000030110000001100003011000030110000301
-- 193:0222222022000022200030022000030220000002200003022000030220000302
-- 194:0333333033000033300030033000030330000003300003033000030330000303
-- 195:09999990990000999000b00990000b099000000990000b0990000b0990000b09
-- 196:0aaaaaa0aa0000aaa000b00aa0000b0aa000000aa0000b0aa0000b0aa0000b0a
-- 197:0bbbbbb0bb0000bbb000b00bb0000b0bb000000bb0000b0bb0000b0bb0000b0b
-- 198:0777777077000077700050077000050770000007700005077000050770000507
-- 199:0666666066000066600050066000050660000006600005066000050660000506
-- 200:0555555055000055500050055000050550000005500005055000050550000505
-- 201:0dddddd0dd0000ddd000d00dd0000d0dd000000dd0000d0dd0000d0dd0000d0d
-- 203:08888880880000888000d00880000d088000000880000d0880000d0880000d08
-- 204:0dddddd0dd0000ddd000d00dd0000d0dd000000dd0000d0dd0000d0dd0000d0d
-- 205:0eeeeee0ee0000eee000d00ee0000d0ee000000ee0000d0ee0000d0ee0000d0e
-- 206:0ddddddddd000000d0000dddd0000000d0d00000d00d0000dd0000000ddddddd
-- 207:ddddddd0000000ddd000d00d00000d0d0000000d0000000d000000ddddddddd0
-- 208:1000030110000001100000011000000110300001100300011100001101111110
-- 209:2000030220000002200000022000000220300002200300022200002202222220
-- 210:3000030330000003300000033000000330300003300300033300003303333330
-- 211:90000b0990000009900000099000000990b00009900b00099900009909999990
-- 212:a0000b0aa000000aa000000aa000000aa0b0000aa00b000aaa0000aa0aaaaaa0
-- 213:b0000b0bb000000bb000000bb000000bb0b0000bb00b000bbb0000bb0bbbbbb0
-- 214:7000050770000007700000077000000770500007700500077700007707777770
-- 215:6000050660000006600000066000000660500006600500066600006606666660
-- 216:5000050550000005500000055000000550500005500500055500005505555550
-- 217:d0000d0dd000000dd000000dd000000dd0d0000dd00d000ddd0000dd0dddddd0
-- 218:0eeeeee0ee0000eee000e00ee0000e0ee0e0000ee00e000eee0000ee0eeeeee0
-- 219:80000d0880000008800000088000000880d00008800d00088800008808888880
-- 220:d0000d0dd000000dd000000dd000000dd0d0000dd00d000ddd0000dd0dddddd0
-- 221:e0000d0ee000000ee000000ee000000ee0d0000ee00d000eee0000ee0eeeeee0
-- 222:088888888800000080000ddd8000000080d00000800d00008800000008888888
-- 223:8888888000000088d000d00800000d0800000008000000080000008888888880
-- 224:0ccccccccc999999c9999bbbc9999999c9999999c9999999cc9999990ccccccc
-- 225:ccccccc0999999ccb999b99c99999b9c9999999c9999999c999999ccccccccc0
-- 226:0ccccccccc111111c1111333c1111111c1111111c1111111cc1111110ccccccc
-- 227:ccccccc0111111cc3111311c1111131c1111111c1111111c111111ccccccccc0
-- 228:0cccccc0cc1111ccc111311cc111131cc111111cc111111ccc1111cc0cccccc0
-- 229:0cccccc0cc7777ccc777577cc777757cc777777cc777777ccc7777cc0cccccc0
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
-- 240:0cccccccccffffffcfffffffcfffffffcfffffffcfffffffccffffff0ccccccc
-- 241:ccccccc0ffffffccffffdffcfffffdfcfffffffcfffffffcffffffccccccccc0
-- 242:0ccccccccc777777c7777555c7777777c7777777c7777777cc7777770ccccccc
-- 243:ccccccc0777777cc5777577c7777757c7777777c7777777c777777ccccccccc0
-- 244:0cccccc0cc9999ccc999b99cc9999b9cc999999cc999999ccc9999cc0cccccc0
-- 245:0cccccc0ccffffcccfffdffccffffdfccffffffccffffffcccffffcc0cccccc0
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
-- 000:00111111111111110000000000000000
-- 001:0123456789abcdeffedcba9876543210
-- 002:13445666655554444333333222222223
-- 004:79bcdeefffeedcb97532110001123576
-- 005:ffffffffffffffffffffffffffffffff
-- 009:00000000000000000000006600000000
-- 012:12345678889bcdeffedcb98887654321
-- 013:34556677888899999999988887665543
-- 014:aaaaaa55559fffffaaaaaaaa99999999
-- 015:12345666666666666789abcdedcba987
-- </WAVES>

-- <SFX>
-- 000:14c0249e346e442f641074639495b445c400d400e400e400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400301000000000
-- 001:2100310e311a4128514a616f818791c7a1f7b1f0c1f0e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100316000000000
-- 002:010d010e013f11301161118221a321c531d741d061008100a100c100d100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100c12000000000
-- 003:0100117021003190410051b0710091d0a100c1f0d100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100470000000000
-- 004:01f011c0112011a02130319031404170515051a061607170814091309110a120b100b150b100c100c180c130c120d130d120d110e110f100f100f100240000000000
-- 005:14e01430343064307440848094e0b450c4d0d430e440e400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400300000000000
-- 006:7cb07cb48cb39ca49c62fc015c007c0f9c0dac0bac0abc0adc0afc0afc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00200000000000
-- 016:5cf05cc05c005c005c905c705c006c506c606c006c006c906c007c007c208c108c009c009c00ac00bc00bc00dc00ec00fc00fc00fc00fc00fc00fc00340000000000
-- 017:5df05dc05d005d005d905d705d006d506d606d006d006d906d007d007d208d108d009d009d00ad00bd00bd00dd00ed00fd00fd00fd00fd00fd00fd00540000000000
-- 018:fe0a2e8ebe012e948e052ec7fe07fe07fe071ef72ed63e95fe648ec29e70fe3dae9cbe5afe29de18ee00ee00fe00fe00fe00fe00fe00fe00fe00fe00252000000000
-- 019:ff0b2f8fbf022f948f062fc6ff06ff05ff051ff42fd33f92ff618fc09f7eff3caf9abf58ff28df18ef00ef00ff00ff00ff00ff00ff00ff00ff00ff00550000000000
-- 020:7cb07cb48cb39ca49c62fc015c007c0f9c0dac0bac0abc0adc0afc0afc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00200000000000
-- 021:7db07db48db39da49d62fd015d007d0f9d0dad0bad0abd0add0afd0afd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00209000000000
-- 022:9e70ae74ae63be64be52fe01de00de0fde0ede0eee0dfe0dfe0dfe0dfe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00200000000000
-- 023:9f70af74af63bf64bf52ff01df00df0fdf0edf0eef0dff0dff0dff0dff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff0040b000000000
-- 024:0c001c702c003c904c005cb07c009cd0ac00ccf0dc00ec00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00470000000000
-- 025:0d001d702d003d904d005db07d009dd0ad00cdf0dd00ed00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00470000000000
-- 026:0e001e702e003e904e005eb07e009ed0ae00cef0de00ee00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00470000000000
-- 027:0f001f702f003f904f005fb07f009fd0af00cff0df00ef00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00470000000000
-- 032:100010001000200030003000500070008000a000c000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000300000000000
-- 033:d200d200d200d200d200d200d200d200d200d200d200d200d200d200d200d200d200d200d200d200d200d200d200d200d200d200d200d200d200d200670000000000
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
-- 001:a00000ac2000ac2c00ac2d00ec2c00ec2d00e00010e001100c2210f003104d50005160004d5000616910a10e00a100007e0200
-- 002:4100005100000000000000000000000000000000000000000000000000000000000000000000000000000000000000006f0000
-- </TRACKS>

-- <PALETTE>
-- 000:3030345d275d993e53ef7d575d4048ffffe6ffd691a57579ffffff3b5dc924c2ff89eff71a1c2c9db0c2566c86333c57
-- </PALETTE>

