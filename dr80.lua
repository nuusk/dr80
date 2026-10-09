-- title:   dr80
-- author:  nuus
-- desc:    remake of dr mario (nes). clear viruses using falling pills.
-- license: MIT License
-- version: 1.2
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

-- TODO add more config options here
local Config = {
	pill_sequence_cleanup_interval_frames = 3600, -- 1 minute
	cooldown_vanish = 300, -- 5 seconds
}

local Assets = {
	music = {
		flora = 0,
		fever = 1,
		menu = 2,
		winner = 3,
	},
	sfx = {
		character = {
			vanish = { 8, 9, 10, 11 },
			land = { 12, 13, 14, 15 },
			overflow = { 16, 17, 18, 19 },
			drop = { 20, 21, 22, 23 },
			clear = { 24, 25, 26, 27 },
			invalid = { 28, 29, 30, 31 },
		},
	},
	sprites = {
		-- Sprite 256 is the blank FG map tile (map index 0).
		-- Sprite sheet: 352-399 reserved for story art.
		-- Cloud/rain: 422-427, 438-443; drop trails: 450-454, 464-473.
		ui = {
			menu_cursor = 410,
			menu_cursor_selected = 411,
			faces = { 0, 48, 192, 200 },
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
			score_coin = 429,
			background = {
				single = 503,
				single_dark_gray = 501,
				single_dark = {
					501,
					501,
					501,
					501,
				},
				single_transparent = 474,
				single_transparent_top_border = 458,
				pill_dark = {
					480,
					498,
					496,
					482,
				},
				pill_special_ready = {
					488,
					506,
					504,
					490,
				},
				half_dark = {
					500,
					485,
					501,
					484,
				},
				half_special_ready = {
					502,
					487,
					503,
					486,
				},
				pill_dark_gray = 496,
				pill_white_border = 444,
			},
			settings = {
				empty = 412,
				empty_focus = 413,
				filled = 444,
				filled_focus = 428,
			},
		},
		pieces = {
			pills = {
				{ name = "R", W = 490, E = 491, N = 492, S = 508 },
				{ name = "S", W = 506, E = 507, N = 493, S = 509 },
				{ name = "E", W = 488, E = 489, N = 494, S = 510 },
			},
			power_drop_shadows_reference = { -- used for initializing shadows below
				{ name = "R", W = 416, E = 417, N = 418, S = 434 },
				{ name = "S", W = 432, E = 433, N = 419, S = 435 },
				{ name = "E", W = 448, E = 449, N = 420, S = 436 },
			},
			shadows = {}, -- used in the game. initialized below
			dark_pills = { 482, 498, 480 },
			viruses = {
				R = 273,
				S = 288,
				E = 320,
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
				horizontal = { 464, 466, 468, 470, 472 },
				vertical = { 450, 451, 452, 453, 454 },
			},
			ghost_pill = {
				horizontal = { 478, 462, 446 },
				vertical = { 421, 460, 461 },
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
				gray = { 409, 474, 503 },
			},
			cloud = 422,
			cloud_raining = { 424, 426, 438, 440, 442 },
			spawn_animation_temp_gray = { 409, 474 },
			spawn_animation_temp_transparent = { 409, 478, 409 },
			spawn_animation_temp_color = {
				R = { 409, 402, 401, 400 },
				S = { 409, 408, 407, 406 },
				E = { 409, 405, 404, 403 },
			},
			virus_idle_animation = {
				R = { 257, 257, 257, 257, 257, 273, 257, 272 },
				S = { 288, 288, 288, 288, 288, 304, 289, 305 },
				E = { 320, 320, 320, 320, 320, 336, 321, 337 },
			},
		},
		characters = {
			[1] = {
				name = "ruby",
				idle = { 0, 2, 4, 6 },
				panic = { 12, 14 },
				game_over = { 10 },
				victory = { 208, 210 },
				fall = { 8 },
				face_idle = 0,
				face_panic = 14,
				face_game_over = 10,
				face_victory = 208,
			},
			[2] = {
				name = "opal",
				idle = { 48, 50, 52, 54 },
				panic = { 60, 62 },
				game_over = { 58 },
				victory = { 212, 214 },
				fall = { 56 },
				face_idle = 48,
				face_panic = 62,
				face_game_over = 58,
				face_victory = 212,
			},
			[3] = {
				name = "amethyst",
				idle = { 96, 98, 100, 102 },
				panic = { 108, 110 },
				game_over = { 106 },
				victory = { 216, 218 },
				fall = { 104 },
				face_idle = 192,
				face_panic = 196,
				face_game_over = 194,
				face_victory = 198,
			},
			[4] = {
				name = "pearl",
				idle = { 144, 146, 148, 150 },
				panic = { 156, 158 },
				game_over = { 154 },
				victory = { 220, 222 },
				fall = { 152 },
				face_idle = 200,
				face_panic = 204,
				face_game_over = 202,
				face_victory = 206,
			},
		},
		viruses = {
			[1] = {
				name = "red",
				idle = { 258, 258, 258, 258, 258, 258, 258, 260, 262, 260, 264, 260, 258 },
				panic = { 266, 268 },
				game_over = 270,
				victory = { 258, 260, 262, 260, 264, 260, 258 },
				face_idle = 258,
				face_panic = 266,
				face_game_over = 270,
				face_victory = 258,
			},
			[2] = {
				name = "yellow",
				idle = { 290, 292, 294, 292, 294, 296, 296, 296, 296, 294, 292, 290 },
				panic = { 298, 300 },
				game_over = 302,
				victory = { 290, 292, 294, 292, 294, 296, 296, 296, 296, 294, 292, 290 },
				face_idle = 290,
				face_panic = 298,
				face_game_over = 302,
				face_victory = 290,
			},
			[3] = {
				name = "blue",
				idle = { 322, 324, 326, 328 },
				panic = { 330, 332 },
				game_over = 334,
				victory = { 322, 324, 326, 328 },
				face_idle = 322,
				face_panic = 330,
				face_game_over = 334,
				face_victory = 322,
			},
		},
	},
}

for i, pill in ipairs(Assets.sprites.pieces.pills) do
	for _, direction in ipairs({ "N", "S", "W", "E" }) do
		local pill_spr = pill[direction]
		local shadow_spr = Assets.sprites.pieces.power_drop_shadows_reference[i][direction]
		Assets.sprites.pieces.shadows[pill_spr] = shadow_spr
	end
end

---@enum Target
local TARGETS = {
	LEADER = 0,
	PLAYER_1 = 1,
	PLAYER_2 = 2,
	PLAYER_3 = 3,
	PLAYER_4 = 4,
	RANDOM = 5,
}

---@enum Cell
local CELL_TYPES = {
	STONE = "stone",
	HALF = "half",
	PILL = "pill",
}

---@enum Setting
local SETTING_TYPES = {
	NUMBER = "number",
	CHARACTER = "character",
}

---@enum Scene
local SCENES = {
	TITLE = -1,
	MENU = 0,
	PARAMS = 1,
	GAME = 2,
	GAME_OVER = 3,
}

---@enum Rule
local RULES = {
	CLASSIC = 0,
	-- ENDLESS = 2,
	-- MONOCOLOR = 3,
	VANISH = 4,
	POWER_DROP = 5,
}

---@enum GameType
local GAME_TYPES = {
	CAMPAIGN = 0,
	BATTLE = 1,
}

---@class Keymap
---@field UP integer
---@field DOWN integer
---@field LEFT integer
---@field RIGHT integer
---@field A integer
---@field B integer
---@field PAUSE integer
---@field SUPER integer

---@type Keymap
local KEYMAP_P1 = {
	UP = 0,
	DOWN = 1,
	LEFT = 2,
	RIGHT = 3,
	A = 4,
	B = 5,
	PAUSE = 6,
	SUPER = 7,
}

---@type Keymap
local KEYMAP_P2 = {
	UP = 8,
	DOWN = 9,
	LEFT = 10,
	RIGHT = 11,
	A = 12,
	B = 13,
	PAUSE = 14,
	SUPER = 15,
}

---@type Keymap
local KEYMAP_P3 = {
	UP = 16,
	DOWN = 17,
	LEFT = 18,
	RIGHT = 19,
	A = 20,
	B = 21,
	PAUSE = 22,
	SUPER = 23,
}

---@type Keymap
local KEYMAP_P4 = {
	UP = 24,
	DOWN = 25,
	LEFT = 26,
	RIGHT = 27,
	A = 28,
	B = 29,
	PAUSE = 30,
	SUPER = 31,
}

local KEYMAPS = {
	KEYMAP_P1,
	KEYMAP_P2,
	KEYMAP_P3,
	KEYMAP_P4,
}

---@class Audio
---@field bgm integer?
---@field reserved {sfx: integer, bgm: integer[]}
---@field chords {happy: string[], arcade: string[]}
---@field music_muted boolean
---@field sfx_cooldown table<integer, number>
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
	music_muted = false,
	sfx_cooldown = {},
}

---Plays background music with given tempo.
---@param track integer
---@param tempo integer
function Audio.play_bgm(track, tempo)
	if Audio.music_muted then
		Audio.bgm = track
		Audio.tempo = tempo
		return
	end
	if Audio.bgm == track and tempo == Audio.tempo and Audio.music_muted == false then
		return
	elseif Audio.bgm == track and tempo ~= Audio.tempo then
		music(track, -1, -1, true, false, tempo or -1)
	else
		music(track, 0, 0, true, false, tempo or -1)
	end
	Audio.bgm = track
	Audio.tempo = tempo
end

---Mutes background music when it's not muted, unmute it when it's muted.
---The track is reset each time it's being unmuted.
function Audio.toggle_music_mute()
	Audio.music_muted = not Audio.music_muted
	if Audio.music_muted then
		music(-1)
	elseif Audio.bgm ~= nil then
		music(Audio.bgm, 0, 0, true, false, Audio.tempo or -1)
	end
end

---Stops background music.
function Audio.stop_bgm()
	music(-1)
	Audio.bgm = nil
end

---Plays sfx with given speed and note.
---@param id integer
---@param speed integer?
---@param note integer?
function Audio.play(id, speed, note)
	local now = time()
	if Audio.sfx_cooldown[id] == nil or now - Audio.sfx_cooldown[id] > 250 then
		sfx(id, note, -1, Audio.reserved.sfx, 15, speed or 0, false)
		Audio.sfx_cooldown[id] = now
	end
end

---Selects notes for playing combos based on the character name.
---@param combo integer
---@param character_name string
function Audio.generate_character_note(combo, character_name)
	local note = Audio.chords.happy[math.min(combo, 4)]
	if character_name == "amethyst" or character_name == "pearl" then
		note = Audio.chords.arcade[math.min(combo, 4)]
	end
	return note
end

---@class Rune
---@field name "R"|"S"|"E"
---@field W integer
---@field E integer
---@field N integer
---@field S integer

---@class Pill
---@field rune1 Rune
---@field rune2 Rune

---@class PositionedPill : Pill
---@field x number
---@field y number
---@field rotation 0|1|2|3

---@class NextPill : PositionedPill
---@field spawn_animation { cur_frame: integer, rune1_frames: integer[], rune2_frames: integer[]}

---@class PillFactory
local PillFactory = {}

---Generates pill with random halves.
---@return Rune rune1
---@return Rune rune2
function PillFactory.generate_random_runes()
	local runes = Assets.sprites.pieces.pills
	local rune1 = runes[math.random(1, #runes)]
	local rune2 = runes[math.random(1, #runes)]
	return rune1, rune2
end

---Returns random color from (R, S, E)
---@return string
function PillFactory.get_random_color()
	local bag = { "R", "S", "E" }
	local i = math.random(#bag)
	return bag[i]
end

---PillSequence helps to maintain the same pills across many players.
---@class PillSequence
---@field pills table<integer, Pill>
---@field head number
---@field tail number
local PillSequence = {}
PillSequence.__index = PillSequence

---Generates the queue without the pills. Needs to be filled before using.
function PillSequence:new()
	local queue = setmetatable({ head = 1, tail = 0, pills = {} }, self)
	return queue
end

---Fills queue with the specified number of pills. They're appended at the end of the queue.
function PillSequence:fill(number)
	for i = 1, number do
		local rune1, rune2 = PillFactory.generate_random_runes()
		self.pills[self.tail + i] = {
			rune1 = rune1,
			rune2 = rune2,
		}
	end
	self.tail = self.tail + number
end

---Clears the queue and all metadata.
function PillSequence:clear()
	self.pills = {}
	self.head = 1
	self.tail = 0
end

---Discards all pills before the index (excluding index).
---@param index integer
function PillSequence:discard_before(index)
	if self.head > index then
		return
	end
	for i = self.head, index - 1 do
		self.pills[i] = nil
	end
	self.head = index
end

---Returns current queue size.
---@return integer size
function PillSequence:size()
	return self.tail - self.head + 1
end

---Retrieves pill with given index from the queue. If it doesn't exist, it fills the queue with 100 new pills.
---@param index integer
---@return Pill? pill
function PillSequence:get_with_refill(index)
	if index < self.head or index % 1 ~= 0 then
		return nil
	end
	while index > self.tail do
		self:fill(100)
	end
	return self.pills[index]
end

---@enum AnimationE
local ANIMATIONS = {
	DROP_TRAIL = 0, -- plays both drop_trail and ghost_pill
	DISAPPEARING_PILL = 1,
	CLOUD_RAINING = 2,
	SOMETHING = 3,
}

---@class Animation
local Animation = {
	animation_index = 0,
}
Animation.__index = Animation

---Creates new animation. Each animation type needs different options.
---@param name AnimationE
---@param options any -- TODO
---@return Animation
function Animation:new(name, options)
	local animation = {
		name = name,
		index = self.animation_index,
		cur_frame = 0,
	}

	if name == ANIMATIONS.DROP_TRAIL then
		animation.num_frames = 15
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
		animation.num_frames = 10
		animation.x = options.x
		animation.y = options.y
		animation.sprites = Assets.sprites.fx.disappear[options.color]
	end

	self.animation_index = self.animation_index + 1
	return animation
end

---@class GridSetting
---@field text string
---@field type "number" | "character"
---@field value integer
---@field min integer
---@field max integer

---@class Grid
---@field player integer
---@field h integer
---@field w integer
---@field py integer
---@field spawn_animation_finished boolean
---@field settings GridSetting[]
---@field score_tmp integer -- temporary score field just for printing
---@field update_timer integer -- each player has their own timer. every "interval", update_timer resets and grid progresses
---@field score integer
---@field character_flip integer
---@field active_pill PositionedPill?
---@field next_pill NextPill?
---@field next_pill_x integer -- stays the same for given player/grid
---@field next_pill_y integer -- stays the same for given player/grid
---@field pill_number integer -- counts the current pill (how many pills the player has spawned so far)
---@field last_special_frame number -- used for calculating cooldown for some special abilities (such as vanish)
local Grid = {
	cell_size = 8,
	intervals = {
		80,
		60,
		40,
		30,
		-- first four are settings based.
		-- next interval levels can be changed during the game as the game progress
		20,
		15,
		10,
	},
	pill_number = 1,
	last_special_frame = -math.huge,
}
Grid.__index = Grid

---@class Game
---@field scene Scene
---@field mode Rule
---@field grids Grid[]
---@field scores integer[]
---@field players integer
---@field winner integer
---@field frame integer
---@field grids_spawned boolean
---@field dont_draw_top_border_positions integer[]
---@field next_game_overlay_delay_frames integer
---@field pill_sequence PillSequence
local Game = {
	scene = SCENES.TITLE,
	mode = RULES.CLASSIC,
	grids = {},
	scores = { 0, 0, 0, 0 },
	players = 1,
	winner = 0,
	frame = 0,
	grids_spawned = false,
	dont_draw_top_border_positions = {},
	next_game_overlay_delay_frames = 120,
	is_paused = false,
	paused_by_player = 0,
	pill_sequence = PillSequence:new(),
}

function Game.cleanup_pill_sequence()
	local earliest = math.huge
	for _, grid in ipairs(Game.grids) do
		if not grid.game_over then
			earliest = math.min(earliest, grid.pill_number)
		end
	end
	Game.pill_sequence:discard_before(earliest)
end

function Game.setup_game(players)
	Game.players = players
	Game.frame = 0
	Game.pill_sequence:fill(200)

	for i = 1, players, 1 do
		local grid = Grid:new(i)
		table.insert(Game.grids, grid)
	end

	Game.scene = SCENES.PARAMS
end

function Game.generate_pill_queue() end

function Game.pause_by_player(player)
	Game.is_paused = not Game.is_paused
	Game.paused_by_player = player
	if not Game.is_paused then
		Game.paused_by_player = 0
	end
end

function Game.character_already_taken(i)
	for _, b in ipairs(Game.grids) do
		if b.selected_character == i then
			return true
		end
	end
	return false
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

		trace("bag has " .. grid.player)
		table.insert(bag, grid.player)
		::continue::
	end

	local rand = math.random(#bag)
	trace("chose " .. rand)
	return bag[rand]
end

function Game.send_surprises(victim, combo)
	trace("victim: " .. victim)
	trace("combo: " .. combo)
	trace("#grids: " .. #Game.grids)
	trace("#players: " .. Game.players)

	for _, grid in pairs(Game.grids) do
		trace(grid.player)
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

function Game.evaluate_speed_up()
	-- every minute, speed up
	if Game.frame % 3600 == 0 then
		for _, grid in pairs(Game.grids) do
			grid:queue_speed_up(1)
		end
	end
end

function Game.reset_grids() -- resets the grids and returns stored settings
	Game.pill_sequence:clear()
	Game.grids_spawned = false
	Game.dont_draw_top_border_positions = {} -- spawn_grid() marks positions where the screen border should be hidden. we need to clear that.
	Game.next_game_overlay_delay_frames = 120
	local saved = {}
	for i, grid in pairs(Game.grids) do
		saved[i] = {
			settings = table.deep_copy(grid.settings),
			selected_character = grid.selected_character,
		}
	end
	Game.grids = {}
	return saved
end

function Game.redo_settings()
	for _, grid in pairs(Game.grids) do
		grid.selected_character = nil
		grid.settings_confirmed = false
	end
end

function Game.restore_settings(saved)
	Game.setup_game(Game.players)
	for i, grid in pairs(Game.grids) do
		grid.settings = saved[i].settings
		grid.selected_character = saved[i].selected_character
		grid.settings_confirmed = true
	end
	Game.evaluate_readiness()
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

function Game.evaluate_readiness()
	local all_ready = true
	for _, grid in pairs(Game.grids) do
		all_ready = all_ready and grid.settings_confirmed
	end
	if all_ready == true then
		local board_presets = {}
		for _, grid in ipairs(Game.grids) do
			grid:apply_settings(board_presets)
		end

		if Game.players == 1 then
			Game.grids[1].stage_visible = true
		end

		Audio.play_bgm(Assets.music.fever)
		Game.scene = SCENES.GAME
	end
end

function Game.update_params()
	for _, grid in pairs(Game.grids) do
		grid:update_params()
	end
end

function Game.draw_player_menus()
	for i, grid in pairs(Game.grids) do
		grid.score_tmp = Game.scores[i]
		grid:draw_player_menu()
	end
end

function Game.draw_next_game_overlay()
	rect(72, 52, 96, 38, 0) -- dark backdrop
	rectb(72, 52, 96, 38, 12) -- thin border
end

function Game.draw_pause_overlay()
	rect(72, 55, 96, 21, 0) -- dark backdrop
	rectb(72, 55, 96, 21, 12) -- thin border

	print("PAUSED", 102, 60, 8)
	print(string.format("(by player %d)", Game.paused_by_player), 86, 66, 8)
end

function Game.draw_score_overlay()
	local y_anchor = 45 - 6 * Game.players
	local x_anchor = 72
	rect(x_anchor, y_anchor, 96, 8 + 6 * Game.players, 0)
	rectb(x_anchor, y_anchor, 96, 8 + 6 * Game.players, 12)
	for i in ipairs(Game.grids) do
		print(string.format("P%d", i), x_anchor + 6, y_anchor - 2 + i * 6, 8)
		if Game.scores[i] < 10 then
			for c = 1, Game.scores[i], 1 do
				spr(Assets.sprites.ui.score_coin, x_anchor + 14 + 7 * c, y_anchor - 3 + i * 6, 0)
			end
		else
			spr(Assets.sprites.ui.score_coin, x_anchor + 21, y_anchor - 3 + i * 6, 0)
			print(string.format("x%d", Game.scores[i]), x_anchor + 32, y_anchor - 2 + i * 6, 8)
		end
	end
end

function Grid:new(player)
	local g = setmetatable({}, Grid)

	g.player = player
	g.h = Game.get_grid_height()
	g.w = Game.get_grid_width()
	g.py = Game.get_grid_y()
	g.spawn_animation_finished = true
	g.target = TARGETS.LEADER
	g.update_timer = 0
	g.settings = {
		{
			text = "difficulty",
			type = SETTING_TYPES.NUMBER,
			value = 2,
			min = 1,
			max = 4,
		},
		{
			text = "speed",
			type = SETTING_TYPES.NUMBER,
			value = 2,
			min = 1,
			max = 4,
		},
		{
			text = "character",
			type = SETTING_TYPES.CHARACTER,
			value = player,
			min = 1,
			max = 4,
		},
	}
	g.score = 0
	g.selected_setting = 1
	g.selected_character = nil
	g.settings_confirmed = false
	g.character_flip = 0
	if Game.players <= 2 then
		g.px = (player - 1) * (g.w + 4) + 1
		g.next_pill_x = g.w + 1
		g.next_pill_y = 0
		g.character_x = g.w + 1
		g.character_y = g.h - 4
		g.num_stones_x = g.w + 1
		g.num_stones_y = 4
		g.target_x = g.w + 1
		g.target_y = g.h - 8
		g.target_selected_x = g.w + 1
		g.target_selected_y = g.h - 7
		if g.player == 2 then
			g.px = g.px + 2
			g.character_x = -3
			g.next_pill_x = -3
			g.num_stones_x = -3
			g.character_flip = 1
		end
	else
		g.px = (player - 1) * (g.w + 1) + 1
		g.next_pill_x = g.w - 5
		g.next_pill_y = -2
		g.character_x = g.w - 3
		g.character_y = -2
		g.num_stones_x = 1
		if Game.players == 3 then
			g.px = g.px + 1
		end
		if Game.players == 4 then
			g.next_pill_x = g.w - 4
			g.character_x = g.w - 2
			g.num_stones_x = 0
			if g.player > 2 then
				-- hack to make grids more centered
				g.px = g.px + 1
			end
		end
		g.num_stones_y = -1
		g.target_x = 0
		g.target_y = -4
		g.target_selected_x = 2
		g.target_selected_y = -4
	end

	g.cell_size = Grid.cell_size
	g.level = 9
	g.num_stones = 0
	g.num_red = 0
	g.num_yellow = 0
	g.num_blue = 0
	g.next_pill = nil
	g.static_pills = {}
	g.active_pill = nil
	g.halves = {}
	g.drop_phase = false
	g.board = {}
	g.phantom_half = {} -- pill that got cut cause it didnt fit on the board. will be used for counting rle
	g.character = nil
	g.combo = 0
	g.pending_surprises = 0
	g.pending_speed_up = 0
	g.queued_surprises = {}
	g.game_over = false
	g.cascade_trigger = false

	g.interval_level = 0
	g.animation_queue = {}

	return g
end

function Grid:apply_settings(board_presets)
	local difficulty = self.settings[1].value
	if not board_presets[difficulty] then
		self:generate_board()
		self:generate_stones()
		board_presets[difficulty] = table.deep_copy(self.board)
	end

	self.board = table.deep_copy(board_presets[difficulty])
	self:count_stones()
	self:generate_character()
	self:apply_speed()
end

function Grid:initialize_those_animated_viruses()
	self.enemies = {
		-- TODO: how to draw them
	}
end

function Grid:generate_board()
	for y = 0, self.h - 1, 1 do
		self.board[y] = {}
		for x = 0, self.w - 1, 1 do
			self.board[y][x] = nil
		end
	end
end

function Grid:generate_character()
	local asset = Assets.sprites.characters[self.selected_character]
	self.character = {
		id = self.selected_character,
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

---Similar to draw_special_pill but for 3 and 4 player mode.
---We can only fit half a pill for displaying special
function Grid:draw_special_half()
	if Game.mode ~= RULES.VANISH then
		return
	end
	local cx = self:cx(self.character_x + 2)
	local cy = self:cy(self.character_y)

	local sprite = Assets.sprites.ui.background.half_dark[self.player]
	local frames_since_last_special = t - self.last_special_frame
	local cooldown_diff = frames_since_last_special - Config.cooldown_vanish

	if
		(frames_since_last_special >= 0 and frames_since_last_special < 5)
		or (frames_since_last_special >= 10 and frames_since_last_special < 15)
		or (cooldown_diff >= 0 and cooldown_diff < 5)
		or (cooldown_diff >= 10 and cooldown_diff < 15)
		or cooldown_diff >= 20
	then
		sprite = Assets.sprites.ui.background.half_special_ready[self.player]
	end

	spr(sprite, cx, cy, 0, 1, 0, 0, 1, 1)
end

function Grid:draw_special_pill()
	local cx = self:cx(self.character_x)
	local cy = self:cy(self.character_y + 3)

	local sprite = Assets.sprites.ui.background.pill_dark[self.player]
	if Game.mode == RULES.VANISH then
		local frames_since_last_special = t - self.last_special_frame
		local cooldown_diff = frames_since_last_special - Config.cooldown_vanish

		if
			(frames_since_last_special >= 0 and frames_since_last_special < 5)
			or (frames_since_last_special >= 10 and frames_since_last_special < 15)
			or (cooldown_diff >= 0 and cooldown_diff < 5)
			or (cooldown_diff >= 10 and cooldown_diff < 15)
			or cooldown_diff >= 20
		then
			sprite = Assets.sprites.ui.background.pill_special_ready[self.player]
		end
	end

	spr(sprite, cx, cy, 0, 1, 0, 0, 2, 1)
	-- spr(Assets.sprites.ui.background.pill_dark_gray, cx, cy2, 0, 1, 0, 0, 2, 1)
end

-- 2 players only
function Grid:draw_additionals()
	local cx = self:cx(self.character_x)
	local cx2 = self:cx(self.character_x + 1)
	local sprc = Assets.sprites.ui.background.single_dark_gray

	-- spr(Assets.sprites.ui.background.pill_dark_gray, cx, self:cy(-1), 0, 1, 0, 0, 2, 1)
	-- spr(Assets.sprites.ui.background.pill_dark_gray, cx, self:cy(1), 0, 1, 0, 0, 2, 1)
	spr(sprc, cx, self:cy(-1), 0, 1, 0, 0, 1, 1)
	spr(sprc, cx2, self:cy(-1), 0, 1, 0, 0, 1, 1)
	spr(sprc, cx, self:cy(1), 0, 1, 0, 0, 1, 1)
	spr(sprc, cx2, self:cy(1), 0, 1, 0, 0, 1, 1)
	spr(sprc, self:cx(self.character_x), self:cy(5), 0, 1, 0, 0, 1, 1)
	spr(sprc, self:cx(self.character_x + 1), self:cy(5), 0, 1, 0, 0, 1, 1)
end

function Grid:draw_num_stones()
	local cx = self:cx(self.num_stones_x)
	local cy = self:cy(self.num_stones_y - 1)

	-- spr(Assets.sprites.ui.background.pill_white_border, cx, cy, 0, 1, 0, 0, 2, 1)

	local offset = 5
	if self.num_stones >= 10 then
		offset = 2
	end
	print(
		self.num_stones,
		self:cx(self.num_stones_x) + offset,
		self:cy(self.num_stones_y) - self.cell_size + 1,
		8,
		true
	)
end

function Grid:should_panic(t)
	if t < 1000 then
		return false
	end

	return self:get_board_criticality() > 0.4
end

function Grid:get_board_criticality()
	local total = 0
	local danger_points = 0

	local multiplier = self.h
	for y = 0, self.h - 1, 1 do
		for x = 0, self.w - 1, 1 do
			local x_offset = math.abs(self.w / 2 - x)
			local position_points = (self.w / 2 - x_offset) * multiplier
			if self.board[y][x] ~= nil then
				danger_points = danger_points + position_points
			end
			total = total + position_points
		end
		multiplier = multiplier - 1
	end

	return danger_points / total
end

function Grid:draw_character(t)
	local char = self.character
	if char == nil then
		trace("ERROR: character is nil, fix the code")
		return
	end

	local cx = self:cx(self.character_x)
	local cy = self:cy(self.character_y)

	if Game.players > 2 then
		local assets = Assets.sprites.characters[self.player]
		local sprt = assets.face_idle
		if self.game_over == true then
			sprt = assets.face_game_over
		elseif self.winner == true then
			sprt = assets.face_victory
		elseif self:should_panic(t) then
			sprt = assets.face_panic
		end

		spr(sprt, cx, cy, 0, 1, 0, 0, 2, 1)
		return
	end

	if self.game_over == true then
		spr(char.anim_game_over.sprites[1], cx, cy, 0, 1, self.character_flip, 0, char.w, char.h)
		local gy = self:cy(self.character_y - 2)
		spr(Assets.sprites.fx.cloud, cx, gy, 0, 1, 0, 0, 2, 1)
		local rain = Assets.sprites.fx.cloud_raining
		local i = (t // 8) % #rain + 1
		local frame = rain[i]

		local ry = self:cy(self.character_y - 1)
		spr(frame, cx, ry, 0, 1, 0, 0, 2, 1)
		return
	end

	if self.winner == true then
		local sprites = Assets.sprites.characters[char.id].victory
		local i = (t // 12) % #sprites + 1
		local frame = sprites[i]
		spr(frame, cx, cy, 0, 1, self.character_flip, 0, char.w, char.h)
		return
	end

	if self:should_panic(t) then
		local sprites = Assets.sprites.characters[char.id].panic
		local i = (t // 12) % #sprites + 1
		local frame = sprites[i]
		spr(frame, cx, cy, 0, 1, self.character_flip, 0, char.w, char.h)
		return
	end

	local i = (t // 8) % #char.anim_idle.sprites + 1
	local frame = char.anim_idle.sprites[i]
	spr(frame, cx, cy, 0, 1, self.character_flip, 0, char.w, char.h)
end

function Grid:add_animation_to_queue(name, options)
	local animation = Animation:new(name, options)
	self.animation_queue[animation.index] = animation
end

function Grid:animate_all()
	for index, animation in pairs(self.animation_queue) do
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
		local sprite = animation.sprites[animation.cur_frame // 5 + 1]
		spr(sprite, self:cx(animation.x), self:cy(animation.y), 0, 1, 0, 0, 1, 1)
	end

	animation.cur_frame = animation.cur_frame + 1
	if animation.cur_frame >= animation.num_frames then
		self.animation_queue[index] = nil
	end
end

function Grid:apply_speed()
	self.interval_level = self.settings[2].value
	self.interval = self.intervals[self.settings[2].value]
end

function Grid:bump_speed()
	self.interval_level = math.min(#self.intervals, self.interval_level + self.pending_speed_up)
	self.interval = self.intervals[self.interval_level]
	self.pending_speed_up = 0
end

function Grid:generate_stones()
	local available_colors = { "R", "S", "E" }
	local presets = {
		[1] = { n = 6, safe = 0.55 },
		[2] = { n = 12, safe = 0.40 },
		[3] = { n = 24, safe = 0.30 },
		[4] = { n = 39, safe = 0.20 },
	}
	local preset = presets[self.settings[1].value]

	if not preset then
		trace("level too high")
		return {}
	end

	if Game.mode == RULES.MONOCOLOR then
		available_colors = {
			available_colors[math.random(#available_colors)],
		}
		preset.n = math.max(1, math.floor(preset.n / 2))
	end

	local h_start = math.floor(preset.safe * self.h)
	local bag = {}

	for ly = h_start, self.h - 1, 1 do
		for lx = 0, self.w - 1, 1 do
			table.insert(bag, { x = lx, y = ly })
		end
	end

	local selected_positions = {}

	for i = 1, preset.n, 1 do
		local rand_num = math.random(#bag)
		table.insert(selected_positions, bag[rand_num])
		table.remove(bag, rand_num)
	end
	for _, pos in ipairs(selected_positions) do
		self.board[pos.y][pos.x] = {
			type = CELL_TYPES.STONE,
		}
	end

	local function color_at(x, y)
		local row = self.board[y]
		local cell = row and row[x]
		return cell and cell.color
	end

	for y = h_start, self.h - 1 do
		for x = 0, self.w - 1 do
			local stone = self.board[y][x]
			if stone then
				local forbidden_left = nil
				local left = color_at(x - 1, y)
				if left == color_at(x - 2, y) and left == color_at(x - 3, y) then
					forbidden_left = left
				end
				local forbidden_above = nil
				local above = color_at(x, y - 1)
				if above == color_at(x, y - 2) and above == color_at(x, y - 3) then
					forbidden_above = above
				end
				local available = {}
				for _, color in ipairs(available_colors) do
					if color ~= forbidden_left and color ~= forbidden_above then
						table.insert(available, color)
					end
				end
				local color
				if Game.mode == RULES.MONOCOLOR then
					color = available_colors[1]
				else
					color = available[math.random(#available)]
				end
				stone.color = color
				stone.spr = Assets.sprites.pieces.viruses[color]
			end
		end
	end

	self:count_stones()
end

function Grid:count_stones()
	local count = 0
	local red = 0
	local yellow = 0
	local blue = 0
	for y = 0, self.h - 1, 1 do
		for x = 0, self.w - 1, 1 do
			if self.board[y][x] ~= nil and self.board[y][x].type == CELL_TYPES.STONE then
				count = count + 1
				if self.board[y][x].color == "R" then
					red = red + 1
				end
				if self.board[y][x].color == "S" then
					yellow = yellow + 1
				end
				if self.board[y][x].color == "E" then
					blue = blue + 1
				end
			end
		end
	end

	self.num_red = red
	self.num_yellow = yellow
	self.num_blue = blue
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

function Grid:queue_speed_up(bump_levels)
	self.pending_speed_up = self.pending_speed_up + bump_levels
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
				if t > 200 and self.board[y][x].type == CELL_TYPES.STONE then
					local sprites = Assets.sprites.fx.virus_idle_animation[self.board[y][x].color]
					local frame = (t // 10) % #sprites
					spr(sprites[frame + 1], cx, cy, 0)
				else
					spr(self.board[y][x].spr, cx, cy, 0)
				end
			end
		end
	end
end

function Grid:draw_stage()
	for v = 1, 3 do
		local cx = self:cx(16 + v * 3)
		local num_viruses = 0
		if v == 1 then
			num_viruses = self.num_red
		elseif v == 2 then
			num_viruses = self.num_yellow
		elseif v == 3 then
			num_viruses = self.num_blue
		end

		local y = 15
		for w = 1, num_viruses do
			spr(Assets.sprites.pieces.dark_pills[v], cx, self:cy(y - w), 0, 1, 0, 0, 2, 1)
		end

		local frame = 0
		if num_viruses == 0 then
			frame = Assets.sprites.viruses[v].game_over
		elseif num_viruses == 1 then
			local sprites = Assets.sprites.viruses[v].panic
			local i = (t // 10) % #sprites + 1
			frame = sprites[i]
		else
			local sprites = Assets.sprites.viruses[v].idle
			local i = (t // 8) % #sprites + 1
			frame = sprites[i]
		end

		spr(frame, cx, self:cy(y - num_viruses - 2), 0, 1, 0, 0, 2, 2)
	end
end

function Grid:draw_stage_border()
	local s = self.w + 4
	local e = self.w + 15
	for y = 0, self.h + 1 do
		local cy = self:cy(y - 1)
		for x = s, e do
			local ok = false
			if y == self.h + 1 then
				ok = true
			end
			if y == 0 then
				ok = true
			end
			if x == s or x == e then
				ok = true
			end
			if ok == true then
				local cx = self:cx(x - 1)
				local sprt = Assets.sprites.ui.background.single_dark_gray
				-- if self.game_over then
				-- 	sprt = Assets.sprites.ui.background.single_dark_gray
				-- end
				spr(sprt, cx, cy, 0)
			end
		end
	end
end

function Grid:generate_next_pill()
	local pill = Game.pill_sequence:get_with_refill(self.pill_number)
	if not pill then
		return
	end
	self.pill_number = self.pill_number + 1

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
		Audio.play(Assets.sfx.character.overflow[self.character.id])
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
	self.game_over = true
end

function Grid:mark_as_winner()
	-- Audio.play(Assets.sfx.character.victory[self.character.id])
	-- TODO: add victory sounds
	self.winner = true
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

		local color = PillFactory.get_random_color()
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

function Grid:special_ability()
	if self.active_pill == nil then
		return
	end
	local frames_since_last_special = t - self.last_special_frame
	if Game.mode == RULES.VANISH then
		if frames_since_last_special > Config.cooldown_vanish then
			self:vanish_pill()
			self.last_special_frame = t
		else
			Audio.play(Assets.sfx.character.invalid[self.player])
		end
	elseif Game.mode == RULES.POWER_DROP then
		self:drop_pill()
		self.last_special_frame = t
	end
end

function Grid:vanish_pill()
	if self.active_pill == nil then
		return
	end

	local x1, y1, x2, y2 = self:get_pill_xy(self.active_pill)
	self:add_animation_to_queue(ANIMATIONS.DISAPPEARING_PILL, {
		x = x1,
		y = y1,
		color = self.active_pill.rune1.name,
	})
	self:add_animation_to_queue(ANIMATIONS.DISAPPEARING_PILL, {
		x = x2,
		y = y2,
		color = self.active_pill.rune2.name,
	})

	Audio.play(Assets.sfx.character.vanish[self.character.id])
	self.active_pill = nil
	self.update_timer = 0
end

function Grid:drop_pill()
	if self.active_pill == nil then
		return
	end

	-- mark tiles that need to be animated (drop trail)
	-- current position
	local start_x1, start_y1, start_x2, start_y2 = self:get_pill_xy()
	local rotation = self.active_pill.rotation

	local grav_possible, end_x1, end_y1, end_x2, end_y2 = self:grav()
	while grav_possible do
		grav_possible, end_x1, end_y1, end_x2, end_y2 = self:grav()
	end

	Audio.play(Assets.sfx.character.drop[self.character.id])
	self.update_timer = 0

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

function Grid:get_shadow_xy()
	if self.active_pill == nil then
		return
	end

	local x1, y1, x2, y2 = self:get_pill_xy()
	local i = 1
	while self:available(x1, y1 + i) and self:available(x2, y2 + i) do
		i = i + 1
	end
	i = i - 1
	if i < 1 then
		return
	end
	return x1, y1 + i, x2, y2 + i
end

function Grid:get_pill_sprites(pill)
	pill = pill or self.active_pill
	if not pill then
		trace("error: pill not found")
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

function Grid:map_pill_sprites_to_power_drop_shadow_sprites(spr1, spr2)
	return Assets.sprites.pieces.shadows[spr1], Assets.sprites.pieces.shadows[spr2]
end

function Grid:draw_static_pills()
	for _, pill in ipairs(self.static_pills) do
		if pill == nil then
			trace("static pill is nil")
			return
		end

		local x1, y1, x2, y2 = self:get_pill_xy(pill)
		local spr1, spr2 = self:get_pill_sprites(pill)
		spr(spr1, x1 * self.cell_size, y1 * self.cell_size, 0)
		spr(spr2, x2 * self.cell_size, y2 * self.cell_size, 0)
	end
end

function Grid:draw_power_drop_shadow()
	if self.active_pill == nil then
		return
	end

	local spr1, spr2 = self:map_pill_sprites_to_power_drop_shadow_sprites(self:get_pill_sprites())
	local x1, y1, x2, y2 = self:get_shadow_xy()

	if x1 ~= nil and x2 ~= nil and y1 ~= nil and y2 ~= nil then
		spr(spr1, self:cx(x1), self:cy(y1), 0)
		spr(spr2, self:cx(x2), self:cy(y2), 0)
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
		Audio.play(Assets.sfx.character.land[self.character.id])

		return false, x1, y1, x2, y2
	end
end

function Grid:mark_active_pill_as_static()
	if self.active_pill == nil then
		trace("cannot mark pill as static, active pill not found")
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

	self.phantom_half = nil
	if y1 < 0 then
		self.phantom_half = {
			color = self.active_pill.rune1.name,
			x = x1,
		}
	elseif y2 < 0 then
		self.phantom_half = {
			color = self.active_pill.rune2.name,
			x = x2,
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
			base = Assets.sprites.pieces.viruses[cell.color]
		end
	end
	if border == true then
		base = Assets.sprites.ui.background.single_dark_gray
	end
	if transparent == true then
		frames = Assets.sprites.fx.spawn_animation_temp_transparent
		base = Assets.sprites.ui.background.single_transparent_top_border
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
					Game.dont_draw_top_border_positions[self.px + x - 1] = true
				end
				if Game.players <= 2 and (x == 1 or x == self.w) then
					Game.dont_draw_top_border_positions[self.px + x - 1] = true
				end
				if Game.players == 4 and (x == 1 or x == self.w) then
					Game.dont_draw_top_border_positions[self.px + x - 1] = true
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
				local sprt = Assets.sprites.ui.background.single_dark_gray
				if transparent == true then
					sprt = Assets.sprites.ui.background.single_transparent_top_border
				end
				-- if self.game_over then
				-- 	sprt = Assets.sprites.ui.background.single_dark_gray
				-- end
				spr(sprt, cx, cy, 0)
			end
		end
	end
end

function Grid:draw_menu_border()
	local start = 0
	if Game.players > 2 then
		start = -1
	end
	for y = start, self.h + 1 do
		local cy = self:cy(y - 1)
		for x = 0, self.w + 1 do
			local ok = false
			if y == self.h + 1 then
				ok = true
			end
			if y == 0 then
				ok = true
				if Game.players > 2 then
					ok = false
				end
			end
			if x == 0 or x == self.w + 1 then
				ok = true
			end
			if ok == true then
				local cx = self:cx(x - 1)
				local sprt = Assets.sprites.ui.background.single_dark_gray
				spr(sprt, cx, cy, 0)
			end
		end
	end
end

function Grid:draw_player_ready()
	self:print_centered("READY")
end

function Grid:draw_settings()
	for i, s in ipairs(self.settings) do
		local text_offset = self:get_setting_y_offset(i)
		local is_focused = self.selected_setting == i
		self:draw_score_in_settings()
		self:print_setting_text(s.text, is_focused, text_offset)
		local value_offset = text_offset + 6
		if s.type == SETTING_TYPES.NUMBER then
			self:draw_number_setting(s.value, s.max, is_focused, value_offset)
		elseif s.type == SETTING_TYPES.CHARACTER then
			self:draw_character_setting(s.value, s.max, is_focused, value_offset)
		end
	end
end

function Grid:draw_score_in_settings()
	local x = (self:cx(0)) - 2
	local y = 10
	local limit = 10
	if Game.players == 3 then
		limit = 8
	elseif Game.players == 4 then
		limit = 6
	end
	if self.score_tmp ~= nil and self.score_tmp < limit then
		for c = 1, self.score_tmp, 1 do
			spr(Assets.sprites.ui.score_coin, x + 7 * c, y, 0)
		end
	else
		spr(Assets.sprites.ui.score_coin, x + 5, y, 0)
		print(string.format("x%d", self.score_tmp), x + 20, y, 8)
	end
end

function Grid:print_centered(txt, y_offset)
	local width = print(txt, 0, -100, 8, true, 1, true)
	local x = (self:cx(0) + self:cx(self.w) - width) // 2
	local y = self:cy(self.h) // 2
	print(txt, x, y, 8, true, 1, true)
end

function Grid:print_setting_text(txt, is_selected, y_offset)
	local width = print(txt, 0, -100, 8, true, 1, true)
	local x = (self:cx(0) + self:cx(self.w) - width) // 2
	local y = self:cy(self.h) // 2 + y_offset
	local color = 8
	if is_selected then
		-- spr(Assets.sprites.ui.menu_cursor, 80, y - 2)
		color = 3
	end
	print(txt, x, y, color, true, 1, true)
end

function Grid:draw_number_setting(value, max, is_focused, y_offset)
	local x = (self.w - max) / 2
	local y = self:cy(self.h) // 2 + y_offset
	local i = 0
	local filled_sprite = Assets.sprites.ui.settings.filled
	if is_focused == true then
		filled_sprite = Assets.sprites.ui.settings.filled_focus
	end
	while i < max do
		local sprt = Assets.sprites.ui.settings.empty
		if is_focused == true then
			sprt = Assets.sprites.ui.settings.empty_focus
		end
		if value > i then
			sprt = filled_sprite
		end
		spr(sprt, self:cx(x + i), y, 0)
		i = i + 1
	end
end

function Grid:draw_character_setting(value, max, is_focused, y_offset)
	local x = (self.w - max) / 2
	local characters = Assets.sprites.characters
	local i = 1
	local j = 1
	local k = i
	while i <= max do
		local sprt = characters[i].face_idle
		local lx = self:cx(x + (k - 1) * 2) + (k - 1) * 3 - 2
		local y = self:cy(self.h + j * 2 - 1) // 2 + y_offset + 2 + (j - 2) * 3

		spr(sprt, lx, y, 0, 1, 0, 0, 2, 1)
		local border_color = 14
		if value == i then
			border_color = 3
		end
		rectb(lx - 1, y - 1, (Grid.cell_size * 2) + 2, Grid.cell_size + 2, border_color)

		if Game.character_already_taken(i) then
			rect(lx, y, (Grid.cell_size * 2), Grid.cell_size, 15)
		end
		i = i + 1
		k = k + 1
		if k > 2 then
			j = j + 1
			k = 1
		end
	end
end

function Grid:get_setting_y_offset(i)
	local center_index = (#self.settings + 2) / 2
	return (i - center_index) * 20
end

function Grid:setting_next()
	self.selected_setting = (self.selected_setting + 1) % (#self.settings + 1)
	if self.selected_setting == 0 then
		self.selected_setting = 1
	end
end

function Grid:setting_prev()
	self.selected_setting = (self.selected_setting - 1) % #self.settings
	if self.selected_setting == 0 then
		self.selected_setting = #self.settings
	end
end

function Grid:confirm_settings()
	for _, s in ipairs(self.settings) do
		if s.type == SETTING_TYPES.CHARACTER then
			if Game.character_already_taken(s.value) then
				Audio.play(Assets.sfx.character.invalid[s.value])
				return
			else
				self.selected_character = s.value
			end
		end
	end
	self.settings_confirmed = true
end

function Grid:go_back_settings()
	self.settings_confirmed = false
	self.selected_character = nil
end

function Grid:selected_setting_plus()
	local current = self.settings[self.selected_setting]
	if current.type == SETTING_TYPES.NUMBER then
		if current.value == current.max then
			return
		end
		current.value = current.value + 1
	elseif current.type == SETTING_TYPES.CHARACTER then
		current.value = current.value + 1
		if current.value == 5 then
			current.value = 1
		end
	end
end

function Grid:selected_setting_minus()
	local current = self.settings[self.selected_setting]
	if current.type == SETTING_TYPES.NUMBER then
		if current.value == current.min then
			return
		end
		current.value = current.value - 1
	elseif current.type == SETTING_TYPES.CHARACTER then
		current.value = current.value - 1
		if current.value == 0 then
			current.value = 4
		end
	end
end

local keycodes = {
	[01] = "A",
	[02] = "B",
	[03] = "C",
	[04] = "D",
	[05] = "E",
	[06] = "F",
	[07] = "G",
	[08] = "H",
	[09] = "I",
	[10] = "J",
	[11] = "K",
	[12] = "L",
	[13] = "M",
	[14] = "N",
	[15] = "O",
	[16] = "P",
	[17] = "Q",
	[18] = "R",
	[19] = "S",
	[20] = "T",
	[21] = "U",
	[22] = "V",
	[23] = "W",
	[24] = "X",
	[25] = "Y",
	[26] = "Z",
	[27] = "0",
	[28] = "1",
	[29] = "2",
	[30] = "3",
	[31] = "4",
	[32] = "5",
	[33] = "6",
	[34] = "7",
	[35] = "8",
	[36] = "9",
	[37] = "MINUS",
	[38] = "EQUALS",
	[39] = "LEFTBRACKET",
	[40] = "RIGHTBRACKET",
	[41] = "BACKSLASH",
	[42] = "SEMICOLON",
	[43] = "APOSTROPHE",
	[44] = "GRAVE",
	[45] = "COMMA",
	[46] = "PERIOD",
	[47] = "SLASH",
	[48] = "SPACE",
	[49] = "TAB",
	[50] = "RETURN",
	[51] = "BACKSPACE",
	[52] = "DELETE",
	[53] = "INSERT",
	[54] = "PAGEUP",
	[55] = "PAGEDOWN",
	[56] = "HOME",
	[57] = "END",
	[58] = "UP",
	[59] = "DOWN",
	[60] = "LEFT",
	[61] = "RIGHT",
	[62] = "CAPSLOCK",
	[63] = "CTRL",
	[64] = "SHIFT",
	[65] = "ALT",
	[66] = "ESC",
	[67] = "F1",
	[68] = "F2",
	[69] = "F3",
	[70] = "F4",
	[71] = "F5",
	[72] = "F6",
	[73] = "F7",
	[74] = "F8",
	[75] = "F9",
	[76] = "F10",
	[77] = "F11",
	[78] = "F12",
	[79] = "NUMPAD0",
	[80] = "NUMPAD1",
	[81] = "NUMPAD2",
	[82] = "NUMPAD3",
	[83] = "NUMPAD4",
	[84] = "NUMPAD5",
	[85] = "NUMPAD6",
	[86] = "NUMPAD7",
	[87] = "NUMPAD8",
	[88] = "NUMPAD9",
	[89] = "NUMPADPLUS",
	[90] = "NUMPADMINUS",
	[91] = "NUMPADMULTIPLY",
	[92] = "NUMPADDIVIDE",
	[93] = "NUMPADENTER",
	[94] = "NUMPADPERIOD",
}

function keycode_to_char(keycode)
	return keycodes[keycode] or "?"
end

local up_key = keycode_to_char(peek(0x14E04 + 0))
local down_key = keycode_to_char(peek(0x14E04 + 1))
local left_key = keycode_to_char(peek(0x14E04 + 2))
local right_key = keycode_to_char(peek(0x14E04 + 3))
local a_key = keycode_to_char(peek(0x14E04 + 4))
local b_key = keycode_to_char(peek(0x14E04 + 5))
local pause_key = keycode_to_char(peek(0x14E04 + 6))

function Game.draw_title_screen()
	local previous = peek4(0x3FFc * 2)
	poke4(0x3FFC * 2, 3)
	map(60, 0, 30, 17, 0, 0)

	poke4(0x3FFC * 2, previous)

	if t % 200 > 100 then
		Game.print_keycodes()
	else
		Game.print_press_to_continue()
	end
end

function Game.print_press_to_continue()
	local txt = string.format("PRESS %s TO CONTINUE", a_key)
	local width = print(txt, 0, -100)
	local x = Screen.width // 2 - width // 2
	local y = 94
	print(txt, x, y, 8)
end

function Game.print_keycodes()
	local x = 42
	local y_start = 78
	print(string.format("%s - confirm / rotate", a_key), x, y_start, 8)
	print(string.format("%s - back / rotate", b_key), x, y_start + 8, 8)
	print(string.format("%s/%s - move pill", left_key, right_key), x, y_start + 16, 8)
	print(string.format("%s - hard drop / vanish", up_key), x, y_start + 24, 8)
	print(string.format("%s - soft drop", down_key), x, y_start + 32, 8)
	print(string.format("%s - pause", pause_key), x, y_start + 40, 8)
end

function Game.draw_screen_border()
	local x_max = 240 // Grid.cell_size
	local y_max = 136 // Grid.cell_size
	local ok = true
	local sprt = Assets.sprites.ui.background.single_dark_gray
	-- TODO: make every single the same!
	-- if Game.scene == SCENES.GAME or Game.scene == SCENES.GAME_OVER then
	-- 	sprt = Assets.sprites.ui.background.single
	-- end
	for x = 0, x_max - 1 do
		for y = 0, y_max - 1 do
			ok = true
			if (x > 0 and x < x_max - 1) and (y > 0 and y < y_max - 1) then
				goto continue
			end
			if y == 0 and Game.dont_draw_top_border_positions[x] then
				ok = false
			end
			if ok == true then
				spr(sprt, x * Grid.cell_size, y * Grid.cell_size, 0)
			end
			::continue::
		end
	end
end

function Game.get_grid_height()
	-- when there are more than 2 players, grid is smaller and character is drawn on top
	if Game.players <= 2 then
		return 15
	end
	return 14
end

function Game.get_grid_y()
	-- when there are more than 2 players, grid is smaller and character is drawn on top
	if Game.players <= 2 then
		return 1
	end
	return 2
end

function Game.get_grid_width()
	if Game.players == 1 then
		return 14
	elseif Game.players == 2 then
		return 11
	elseif Game.players == 3 then
		return 8
	elseif Game.players == 4 then
		return 6
	else
		trace("unexpected number of players during get_grid_width")
	end
end

function Game.eval_game_overs()
	if Game.players == 1 then
		return Game.grids[1].game_over
	end
	local current_winner = 1
	local game_overs = 0
	for i, grid in ipairs(Game.grids) do
		if grid.game_over then
			game_overs = game_overs + 1
		else
			current_winner = i
		end
	end

	if game_overs == Game.players then
		Game.winner = 0
		return true
	elseif game_overs == Game.players - 1 then
		Game.mark_winner(current_winner)
		return true
	end
	return false
end

function Game.mark_winner(winner)
	Game.winner = winner
	Game.grids[winner]:mark_as_winner()
	Game.scores[winner] = Game.scores[winner] + 1
end

function Game.eval_winner()
	if Game.players == 1 then
		if Game.grids[1].num_stones == 0 then
			Game.mark_winner(1)
			return true
		end
	end
	local current_winner = nil
	for i, grid in ipairs(Game.grids) do
		if grid.num_stones == 0 then
			current_winner = i
			Game.mark_winner(i)
			break
		end
	end

	if current_winner == nil then
		return false
	end

	for i, grid in ipairs(Game.grids) do
		if i ~= current_winner then
			grid:trigger_game_over()
		end
	end

	return true
end

function Grid:log_state()
	trace(self.active_pill)
	trace(self.combo)
	trace(self.board)
	trace(self.game_over)
	trace(self.cascade_trigger)
end

-- like the stage with viruses, bosses etc

function Grid:eval()
	self.update_timer = 0

	if self.pending_surprises > 0 then
		self:spawn_queued_surprises()
	end

	if self.active_pill == nil then
		if self.pending_speed_up > 0 then
			self:bump_speed()
		end
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
		if #self.queued_surprises > 0 then
			self:drop_queued_surprises()
			return
		end

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
	if Game.players == 1 then
		return
	end

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

	trace("target: " .. target)
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
				if
					self.phantom_half ~= nil
					and self.phantom_half.color == self.board[y][x].color
					and self.phantom_half.x == x
				then
					acc.count = acc.count + 1
				end
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

t = 0

---@class MenuOption
---@field label string
---@field info string

---@class Menu
---@field options MenuOption[]
---@field options_padding integer
---@field on_back function
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
	local color = 8
	local sprt = Assets.sprites.ui.menu_cursor
	if is_selected then
		sprt = Assets.sprites.ui.menu_cursor_selected
		color = 3
	end
	spr(sprt, 80, y - 2)
	spr(sprt, 152, y - 2)
	print(txt, x, y, color, true)
end

function Menu:get_offset(i)
	local center_index = (#self.options + 1) // 2
	return (i - center_index) * self.options_padding
end

function Menu:print_info_dialog(info)
	local width = print(info, 0, -100, 8, false)
	local x = Screen.width // 2 - width // 2
	local y = Screen.height // 2 + 30
	local color = 8
	print(info, x, y, color, false)
end

function Menu:draw()
	for i, option in ipairs(self.options) do
		self:print_item(option.label, i == self.selected_option, self:get_offset(i))
		if i == self.selected_option and option.info ~= nil then
			self:print_info_dialog(option.info)
		end
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
	elseif btnp(KEYMAP_P1.PAUSE) then
		Audio.toggle_music_mute()
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

local rules_menu
local players_menu

players_menu = Menu:new({
	options = {
		{
			label = "1 PLAYER  ",
			callback = function()
				Game.setup_game(1)
			end,
		},
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
				Game.menu = rules_menu
			end,
		},
	},
})

rules_menu = Menu:new({
	options = {
		{
			label = "CLASSIC",
			callback = function()
				Game.menu = players_menu
				Game.mode = RULES.CLASSIC
			end,
			info = "just like dr mario",
		},
		-- {
		-- 	label = "CAMPAIGN",
		-- 	callback = function()
		-- 		Game.menu = players_menu
		-- 		Game.mode = MODES.CAMPAIGN
		-- 	end,
		-- },
		-- {
		-- 	label = "MONOCOLOR",
		-- 	callback = function()
		-- 		Game.menu = players_menu
		-- 		Game.mode = MODES.MONOCOLOR
		-- 	end,
		-- },
		{
			label = "POWER DROP",
			callback = function()
				Game.menu = players_menu
				Game.mode = RULES.POWER_DROP
			end,
			info = "up arrow instantly drops pill",
		},
		{
			label = "VANISH",
			callback = function()
				Game.menu = players_menu
				Game.mode = RULES.VANISH
			end,
			info = "up arrow discards pill (prototype)",
		},
		-- {
		-- 	label = "ENDLESS",
		-- 	callback = function()
		-- 		Game.menu = players_menu
		-- 		Game.mode = MODES.CLASSIC
		-- 	end,
		-- },
	},
})

next_game_menu = Menu:new({
	options = {
		{
			label = "REMATCH",
			callback = function()
				local saved = Game.reset_grids()
				Game.restore_settings(saved)
			end,
		},
		{
			label = "SETTINGS",
			callback = function()
				Game.reset_grids()
				Game.setup_game(Game.players)
				Audio.play_bgm(Assets.music.menu)
				Game.scene = SCENES.PARAMS
			end,
		},
		{
			label = "MAIN MENU",
			callback = function()
				Game.reset_grids()
				Game.menu = rules_menu
				Game.scene = SCENES.MENU
			end,
		},
	},
})

Game.menu = rules_menu

function Grid:update()
	local keys = KEYMAPS[self.player]

	if btnp(keys.PAUSE) then
		Game.pause_by_player(self.player)
	end
	if Game.is_paused then
		return
	end
	if btnp(keys.A) then
		self:rotate_clockwise()
	end
	if btnp(keys.B) then
		self:rotate_counterclockwise()
	end
	if btnp_repeat(keys.LEFT) then
		self:move_left()
	end
	if btnp_repeat(keys.RIGHT) then
		self:move_right()
	end
	if btnp(keys.SUPER) then
		-- self:bump_speed()
		-- for testing
	end

	local effective_interval = self.interval
	if btn(keys.DOWN) and self.active_pill ~= nil then
		effective_interval = math.max(5, self.interval / 10)
	elseif self.active_pill == nil then
		effective_interval = math.max(5, self.interval / 5)
	end

	if btnp(keys.UP) then
		self:special_ability()
	end

	if self.update_timer >= effective_interval then
		if self.game_over ~= true and self.winner ~= true then
			self:eval()
		end
	end

	self.update_timer = self.update_timer + 1
end

-- btnp repeat helper
local REPEAT_DELAY = 20
local REPEAT_RATE = 3
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
	if btnp_repeat(keys.UP) then
		self:setting_prev()
	elseif btnp_repeat(keys.DOWN) then
		self:setting_next()
	elseif btnp_repeat(keys.LEFT) then
		self:selected_setting_minus()
	elseif btnp_repeat(keys.RIGHT) then
		self:selected_setting_plus()
	elseif btnp(keys.A) then
		self:confirm_settings()
	elseif btnp(keys.B) then
		self:go_back_settings()
	elseif btnp(keys.PAUSE) then
		Audio.toggle_music_mute()
	end
end

function Grid:draw_player_menu()
	self:draw_menu_border()
	if self.settings_confirmed then
		self:draw_player_ready()
	else
		self:draw_settings()
	end
end

function Grid:draw()
	self:draw_border()
	self:draw_board()
	self:draw_static_pills()
	self:draw_active_pill()
	if Game.mode == RULES.POWER_DROP then
		self:draw_power_drop_shadow()
	end
	self:draw_halves()
	self:draw_queued_surprises()
	self:draw_character(t)
	if self.game_over ~= true then
		self:draw_num_stones()
	end
	self:draw_next_pill()
	-- TODO: consider removing
	-- self:draw_target()
	if self.stage_visible then
		self:draw_stage_border()
		self:draw_stage()
		self:draw_num_stones()
	end

	if Game.players <= 2 then
		self:draw_special_pill()
		self:draw_additionals()
	else
		self:draw_special_half()
	end
end

function TIC()
	cls(0)

	rectb(0, 0, 240, 136, 12)

	if Game.scene == SCENES.TITLE then
		Audio.play_bgm(Assets.music.menu)
		Game.draw_title_screen()
		Game.draw_screen_border()
		if btnp(KEYMAP_P1.A) then
			Game.scene = SCENES.MENU
		end
	elseif Game.scene == SCENES.MENU then
		Game.menu:update()
		Game.menu:draw()
		Game.draw_screen_border()
		if btnp(KEYMAP_P1.B) then
			Game.scene = SCENES.TITLE
		end
	elseif Game.scene == SCENES.PARAMS then
		Game.update_params()
		Game.draw_player_menus()
		Game.evaluate_readiness()
		Game.draw_screen_border()
		if btnp(KEYMAP_P1.B) then
			Game.reset_grids()
			Game.scene = SCENES.MENU
		end
	elseif Game.scene == SCENES.GAME then
		Game.draw_screen_border()
		if Game.grids_spawned then
			if Game.eval_winner() or Game.eval_game_overs() then
				Audio.play_bgm(Assets.music.winner)
				Game.menu = next_game_menu
				Game.scene = SCENES.GAME_OVER
			else
				Game.update_grids()
			end

			Game.draw_grids()
			if Game.is_paused then
				Game.draw_pause_overlay()
			else
				Game.animate_grids()
				Game.evaluate_speed_up()
			end
		else
			Game.spawn_grids()
		end
		if t % Config.pill_sequence_cleanup_interval_frames == 0 then
			Game.cleanup_pill_sequence()
		end
	elseif Game.scene == SCENES.GAME_OVER then
		Game.draw_screen_border()
		Game.draw_grids()
		Game.animate_grids()
		if Game.next_game_overlay_delay_frames > 0 then
			Game.next_game_overlay_delay_frames = Game.next_game_overlay_delay_frames - 1
		else
			Game.draw_next_game_overlay()
			Game.draw_score_overlay()
			Game.menu:update()
			Game.menu:draw()
		end
	end

	t = t + 1
	Game.frame = Game.frame + 1
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
-- 010:0000cccc000c112100c112120c11255100cc5555000ccc55000c55550000cccc
-- 011:ccccc00022222c00122222c0212222c0552222c0cc5152c0555cccc0ccc00000
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
-- 026:0000000c0000000c0000000c000000cc000000ca00000cca0000ccaa0000cc9a
-- 027:ac000000aac00000aac00000aacc0000aacc0000aacc0000aacac000aacac000
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
-- 058:0000cccc000c447400c447470c44745700c4555500c4cc5500c4555500c7cccc
-- 059:ccccc000777b7c004777b7c0747777c0557777c0cc5a57c05554ccc0ccc7c000
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
-- 074:00c7c00c00c7c00c00c7c0cc00cbc0c300c4ccc300cccc330000cc33000c3533
-- 075:3cc7c0003cc7c00033c7c00033cbc00033c4c00033ccc00033c3c0003353c000
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
-- 144:00000ccc000ccccc00cccc930c4777930c44ccccc4cc5c550cc65b5500c62555
-- 145:ccccccc0cc7777cc9cccc77c9777ccccccc777c0c5ccc77cb556cccc552666cc
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
-- 158:0000000c00000c77000ccc9300c777930c44ccccc44c5c550cc65b5500c62555
-- 159:cccc00007777c0009cc87800977bcb00cc777c00c5c77c00b55c77c0552c777c
-- 160:00c6cccc30c64444c0c6644c0c0c66cc0c00cc7705ccc44700000cc4000000c9
-- 161:cccc666cc444cc6c7c444c6c7cc44c6c77ccc66c777cccc07777c000399c0500
-- 162:00c6255560c6ccccc0c6644c0c0c66cc0c00cc7705ccc44700000cc4000000c9
-- 163:552666cccccc666c7c444c6c7cc44c6c77ccc66c777cccc07777c000399c0500
-- 164:00c6255500c6cccc00c6444450c6644cc00c66cc0c00cc770c00c44705cc0cc4
-- 165:552666cccccc666cc444cc6c7c444c6c7cc44c6c77ccc66c777cc0c0399c0c00
-- 166:00c6255500c6cccc60c64444c0c6644c0c0c66cc0c00cc7705ccc447000000c9
-- 167:552666cccccc666cc444cc6c7c444c6c7cc44c6c77ccc66c777cccc0399c0500
-- 168:05465b550cc6255500cccccc000cc0000000cc0c00000ccc00000c770000c447
-- 169:b556cc7755264c5ccccc0cc0c000cc007c0cc0007ccc000077c0000077c00000
-- 170:00c6255500c6cccc00c6444400c6644c000c66cc0000cc7700000c4700000cc9
-- 171:552666cccccc666cc444cc6c7c444c6c7cc44c6c77ccc66c777c0cc039cc0000
-- 172:00c6255500c6555500c5cccc00ccc44400c6cc4c000c6ccc0000cc7700000c47
-- 173:552c777c5554c6ccccc5666cc44ccc6c7ccc4c6c7cc44c6c7cccc66c777c0cc0
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
-- 194:000ccccc00cc474700c4cccc0ccc55550c4ccc550c4c555500c4cccc00cc4444
-- 195:ccccccc0477777ccccc7777c55ccc77ccc51cc7c5551c47ccccc47cc44477cc0
-- 196:000ccccc00cc474700c444440cc4cccc0c4c52550c4c555500c4cccc00cc4444
-- 197:ccccccc0477878cc444b7b7ccccc477c2551cc7c5551c47ccccc47cc44477cc0
-- 198:000ccccc00cc44cc00c4cc550c4c15c50c4c55250c4c155500c4cccc00cc4444
-- 199:cccccc00cc477cc055cc77c05c51c7cc5255c77c5551c47ccccc47cc44447cc0
-- 200:000ccccc00cccc930c4777930c44ccccc4cc5c550cc65b5500c6255500c6cccc
-- 201:cc7777cc9cccc77c9777ccccccc777ccc5ccc77cb556ccc7552666cccccc666c
-- 202:000ccccc00cccc930c4777930c44ccccc4cc55550cc6cc5500c6255500c6cccc
-- 203:cc7777cc9cccc77c9777ccccccc777cc55ccc77ccc56ccc7552666cccccc666c
-- 204:00000ccc000ccccc00cc77930c447793c4cccccc0cc65c5500c6255500c6cccc
-- 205:cc7777ccccccc77c97778c8c9777b7bcccccc77cc556ccc7552666cccccc666c
-- 206:00000c93000ccc9300c77ccc0c44c555c4cc55c50cc655b50c66255500c6cccc
-- 207:39c0000039ccc000ccc77c00555c77c05c55cc7c5b556cc0555266c0cccc6c00
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
-- 220:00000000000000cc000ccc9300c777930c744ccc0c44c555c4cc55c50cc655b5
-- 221:00000000cccccc0039ccc7c039777c00ccc477c0555c47c05c55c47c5b556cc0
-- 222:000000cc000ccc9300c777930c744ccc0c44c555c4cc55c50cc655b560c62555
-- 223:cccccc0039ccc7c039777c00ccc477c0555c47c05c55c47c5b556cc0555266cc
-- 224:000cc0000000cccc000000ca000000ca00000caa00000caa0000ca9a000c99a9
-- 225:cc00cc00aaccc000aac00000aaac0000aaac0000aaaac000aaaac000aaaac000
-- 226:000c000c0000ccca00000caa00000caa0000caaa0000caaa000c9a9a000c9aa9
-- 227:c000c000accc0000ac000000aac00000aac00000aaac0000aaac0000aaaac000
-- 228:050c7c0000c0b00c000c7ccc0000ccc300000c2300000c330000c2330000c333
-- 229:ccc7c050c3c7cc00333bc00033370000333c0000333c00003333c0003333c000
-- 230:000c7ccc000c7c000500b00c00cc7ccc0000ccc300000c2300000c330000c233
-- 231:ccc7c000ccc7c000c3c7c005333bccc033370000333c0000333c00003333c000
-- 232:0c4c55250c4c155500c4cccc00cc44440000ccc700000c7700000c7700000c77
-- 233:5255cc7c5551c47ccccc47cc44477cc07cccc00077c0000077cc0000777c0000
-- 234:0c4c155500c4cccc00cc44440000ccc700000c7700000c7700000c7700000c77
-- 235:5551c47ccccc47cc44477cc07cccc00077c0000077cc0000777c0000777c0000
-- 236:00c6255530c6ccccc0c644440cc6644c0c0c66cc05c0cc77000cc44700000c44
-- 237:555266cccccc666cc444cc6c7c444c6c7cc44c6c77ccc66c777cccc0774cc000
-- 238:c0c6ccccc0c644440cc6644c050c66cc00c0cc77000cc44700000c4400000099
-- 239:cccc666cc444cc6c7c444c6c7cc44c6c77ccc66c777cccc0774cc00039900500
-- 240:0000cccc000000cc000000cc000000cc0000000c0000000c0000cc0c0000cccc
-- 241:ccccc0000ccc00000cc000000cc000000c0000000c0000000ccc00000ccc0000
-- 242:0000cccc000000cc000000cc000000cc0000000c0000000c0000cc0c0000cccc
-- 243:ccccc0000ccc00000cc000000cc000000c0000000c0000000ccc00000ccc0000
-- 244:000c2333000c323300c2232300cccccc0000000c0000000c0000000c000002cc
-- 245:33333c0033333c00333333c0ccccccc00c0000000c0000000c0000000c200000
-- 246:0000c333000c2333000c323300c22323000ccccc0000000c0000000c000002cc
-- 247:3333c00033333c0033333c00333333c0cccccc000c0000000c0000000c200000
-- 248:0000cc770000cc740000c4440000c4470000ccc40000000c0000cc0c0000cccc
-- 249:777c0000777cc0007477c0004777c00074ccc0004c0000000ccc00000ccc0000
-- 250:0000cc770000cc740000c4440000c4470000ccc40000000c0000cc0c0000cccc
-- 251:777c0000777cc0007477c0004777c00074ccc0004c0000000ccc00000ccc0000
-- 252:000000990000cc47000cc474000c444700c4444c000ccccc0000000c000009cc
-- 253:399005007777c00077777c0047777c00747777c00ccccc000c0000000c900000
-- 254:0000cc47000cc474000c444700c4444c000ccccc0000000c0000000c000009cc
-- 255:7777c00077777c0047777c00747777c00ccccc000c0000000c0000000c900000
-- </TILES>

-- <SPRITES>
-- 001:c00cc00c0cc11cc0cc1221ccc122221cc28cc82cc322223c0c2222c000cccc00
-- 002:0c00ccccc2ccc3330ccc36630cc321880cc218810c22188c0c1221810c122222
-- 003:ccccc00c3332ccc233232ccc888812c0cc18812cccc8812ccc18122c2222222c
-- 004:000000000c00ccccc2ccc3330ccc36630cc363330cc221880c2218810c12188c
-- 005:00000000ccccc00c3332ccc233232ccc323222c08888122ccc18812cccc8812c
-- 006:00c000000c20cccc00ccc3330ccc36630cc363330cc221880c1218880c121888
-- 007:00000000ccccc0003333cccc33332cc2333223c08888822c1cc1882ccccc882c
-- 008:000000000cc0cccc02ccc3330ccc36630cc363330cc228880c22881c0c2288cc
-- 009:00000000ccccc02c3333ccc033332cc0333223c08888122cc188812ccc88812c
-- 010:0c00ccccc2ccc3330ccc36630cc363330cc222220c2222220c12cccc2c122222
-- 011:ccccc00c3332ccc233838ccc328282c022b2b22c2222222ccccccc2c222222c2
-- 012:000000000c00ccccc2ccc3330ccc36630cc363330cc222220c2222220c12cccc
-- 013:00000000ccccc00c3332ccc233332ccc328282c022b2b22c2222222ccccccc2c
-- 014:000000000000ccccc0ccc3332ccc36630cc363330cc222220c222cc20c12222c
-- 015:00000000ccccc0003332ccc033332ccc322222c22222222c22cc222ccc22222c
-- 016:c00cc00c0cc11cc0cc1221ccc122221cc288cc2cc322223c0c2222c000cccc00
-- 017:c00cc00c0cc11cc0cc1221ccc122221cc2cc882cc322223c0c2222c000cccc00
-- 018:0c1122220c1112220cc111220ccc111c0c0ccc110c000ccc0200c21c0000cccc
-- 019:2222222c2222222c222212c0ccc11cc01111c0c0cccc00c00c12c0200cccc000
-- 020:0c1221810c1122220c1112220cc111220ccc111c0c0ccc1102000ccc0000cccc
-- 021:cc18122c2222222c2222222c222212c0ccc11cc01111c0c0cccc00200cccc000
-- 022:0c1121880c1112220c1111220cc111120ccc11110c0ccc110200c2cc0000cccc
-- 023:1cc1822c2222222c2222222c222221c0cccc1cc01111c0c0ccc2c0200cccc000
-- 024:0c22281c0c2222220c1222220cc112220ccc11cc0c0ccc110200c2cc0000cccc
-- 025:c188122c2222222c2222222c222221c0cc211cc01111c0c0ccc2c0200cccc000
-- 026:0c112c8c0c111ccc0cc111c300cc1111000cc11100000ccc0000c21c0000cccc
-- 027:ccc8c22cccccc22c333c12c0111112c011111c00ccccc0000c12c0000cccc000
-- 028:0c1222222c112c8c0c111ccc0cc11ccc00cc11c3000cc11100000ccc0000cccc
-- 029:2222222cccc8c2c2ccccc22cccccc2c0333c12c011111c00ccccc0000cccc000
-- 030:0c122cc20c1122220c1112220cc1111100cc111c000cc111000c0ccc0002cccc
-- 031:22cc222c2222222c2222222cc11122c0cc1112c011111c00cccccc000cccc200
-- 032:cc0000ccc4cccc4cc46cc64cc6c44c6cc687786ccc6666cc0cc66cc000cccc00
-- 033:00000000ccccccccc76cc67cc4c44c4cc487784ccc6666cc0cc66cc000cccc00
-- 034:7c00ccccc4ccc6650c4c65560c4446660c44ccc40c4484470c4684870c676666
-- 035:ccccc0076666ccc466666c4466666440444ccc4c7778446c7778486c6666666c
-- 036:c7c0ccccc44cc6650c4c65560c4446660c4444440c44ccc40c4684870c676666
-- 037:ccccc0006666cccc66666c44666664474444444c444ccc6c7778486c6666666c
-- 038:0000ccccccccc665444c65567c4446660c4444440c4444440c46ccc70c676666
-- 039:ccccc0006666cc0066666ccc66666447444444474444446c777ccc6c6666666c
-- 040:0000ccccccccc665444c65567c4446660c4444440c4444440c46ccc70c676666
-- 041:ccccc0006666cc0066666ccc66666447444444474444446c777ccc6c6666666c
-- 042:7c00ccccc4ccc6660c4c66660c4446660c4444440c4444470c46ccc76c676666
-- 043:ccccc0076666ccc466868c446686844044b4b44c7774446c777ccc6c666666c6
-- 044:c7000000c7c0cccc0c4cc6660c4c66660c4446660c4444440c4444470c46ccc7
-- 045:00000000ccccc0076666ccc466666c446686844044b4b44c7774446c777ccc6c
-- 046:000000000000ccccccccc665444c65567c4446660c4444440c44c4c70c467c77
-- 047:00000000ccccc0006666cc0066666ccc6666644744444447777c4c6c7777c76c
-- 048:00000000ccccccccc46cc64cc4c44c4cc687786ccc6666cc0cc66cc000cccc00
-- 049:00000000ccccccccc46cc64cc4c44c4cc687786ccc6666cc0cc66cc000cccc00
-- 050:0c7676660c77676600c7767c00cc7776000ccc77000c0ccc0006c64c0000cccc
-- 051:6666666c6666666ccc6666c066666cc06666cc00cccc0c000c46c6000cccc000
-- 052:0c7676660c77676600c7767c00cc777600cccc7700c00ccc0060c64c0000cccc
-- 053:6666666c6666666ccc6666c066666cc06666c0c0cccc00c00c46c0600cccc000
-- 054:0c7676660c77676600c7767c00cc777600cccc7700c00ccc0060c64c0000cccc
-- 055:6666666c6666666ccc6666c066666cc06666c0c0cccc00c00c46c0600cccc000
-- 056:0c7676660c77676600c7767c00cc777c00cccc7500c00ccc0060c64c0000cccc
-- 057:6666666c6666666ccc6666c0cc666cc06666c0c0cccc00c00c46c0600cccc000
-- 058:0c7676c80c7767cc00c776cc00cc7776000ccc7700000ccc0000c64c0000cccc
-- 059:888c666ccccc666c33cc66c066666cc06666c000cccc00000c46c0000cccc000
-- 060:0c6766666c7676c80c7767cc00c776cc00cc7776000ccc7700000ccc0000cccc
-- 061:6666666c888c66c6cccc666c33cc66c066666cc06666c000cccc00000cccc000
-- 062:0c67c6c60c7676660c77676600c7767600cc777c00cccc7700c00ccc0060cccc
-- 063:666c6c6c6666666c6666666ccc6666c0c6666cc06666c0c0cccc00c00cccc060
-- 064:00cccc000caaaac0cccaacccca8228acc6aaaa6c0c9aa9c00b9999b000000000
-- 065:0000000000cccc000caaaac0cccaacccca8228acc6aaaa6c0c9aa9c00b0000b0
-- 066:0000cccc000ccaaa09cca9990cc6bbb90ccaabaa0caab88a0c9abc8a0c9aabaa
-- 067:ccccc000aaa2cca0999a2cc092a2a2c0aaaaaabca2a8cabc22ac8abcaaaaaabc
-- 068:000000000000cccc0b0ccaaa09cca9990cc6bbb90ccaabaa0caab88a0c9abc8a
-- 069:00000000ccccc0b0aaa2cca0999a2cc092a2a2c0aaaaaabca2a8cabc2aac8abc
-- 070:000000000000cccc000ccaaa09cca9990cc6bbb90ccaabaa0caab88a0c9abc8a
-- 071:00000000ccccc000aaa2cca0999a2cc092a2a2c0aaaaaabca2a8cabc2aac8abc
-- 072:0000cccc000ccaaa09cca9990bc6bbb90ccaabaa0caab88a0c9abc8a0c9aabaa
-- 073:ccccc000aaa2cca0999a2cb092a2a2c0aaaaaabca2a8cabc22ac8abcaaaaaabc
-- 074:0000cccc000ccaaa09cca9990cc6bbb90ccaabaa0caabbba0c9acccaac9aabaa
-- 075:ccccc000aaa2cca0998a8cc0928282c0aabababca2aaaabc22acccbcaaaaaac9
-- 076:000000000000cccc0b0ccaaa09cca9990cc6bbb90ccaabaa0caabbbabc9accca
-- 077:00000000ccccc0b0aaa2cca099aaacc0928282c0aabababca2aaaabc22acccbb
-- 078:000000000000cccc000ccaaa09cca9990cc6bbb90ccaabaa0caacbca0c9aacaa
-- 079:00000000ccccc000aaa2cca099aaacc092a2a2c0aaaaaabca2acacbc22aacabc
-- 080:0000000000cccc000caaaac0cccaacccca8228acc6aaaa6c0b9aa9b000000000
-- 081:00cccc000caaaac0cccaacccca8228acc6aaaa6c0c9aa9c00c9999c00b0000b0
-- 082:0c9baaab0c99bbbb00c99bbb00cc9bcc000ccb990ac00ccc0000c61c0000cccc
-- 083:bbbbbbbcbbbbbbbcbbbbbbc0ccccbcc09999bc00cccc00c00c1ac0900cccc000
-- 084:0c9aabaa0c9baaab0c99bbbb00c99bbb0acccb9900000bcc0000c61c0000cccc
-- 085:aaaaaabcbbbbbbbcbbbbbbbcbbbbbbc09999bcc0ccccb0900c1ac0000cccc000
-- 086:0c9aabaa0c9baaab0c99bbbb0ac99bbb00cccb9900000bcc0000c61c0000cccc
-- 087:aaaaaabcbbbbbbbcbbbbbbbcbbbbbbc09999bcc9ccccb0000c1ac0000cccc000
-- 088:0c9baaab0c99bbbb00c99bbb00cccbcc0ac0cb9900000bcc0000c61c0000cccc
-- 089:bbbbbbbcbbbbbbbcbbbbbbc0ccccbcc09999bcc0ccccb0900c1ac0000cccc000
-- 090:0c9baaab0c99bbbc00c99bcc00cc9bc3000ccb9900000ccc0000c61c0000cccc
-- 091:bbbbbbbccccbbbbcccccbbc0333cbcc09999bc00cccc00000c1ac0000cccc000
-- 092:ac9aabaa0c9baaab0c99bbbc00c99bcc00cc9bc3000cc99900000ccc0000cccc
-- 093:aaaaaac9bbbbbbbccccbbbbcccccbbc0333cbcc099999c00cccc00000cccc000
-- 094:0c9acbca0c9baaab0c99bbbb00c99bbb00cc9bcc000ccb99000c0ccc000acccc
-- 095:aaacacbcbbbbbbbcbbbbbbbcbbbbbbc0ccccbcc09999bc00cccc0c000cccca00
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
-- 154:0000000000ddddd00dd000dd0d00d00d0d000d0d0d00000d0dd000dd00ddddd0
-- 155:0000000000ddddd00dd999dd0d99599d0d99959d0d99999d0dd999dd00ddddd0
-- 156:0000000000eeeee00ee000ee0e00e00e0e000e0e0e00000e0ee000ee00eeeee0
-- 157:0000000000333330033000330300e00303000e03030000030330003300333330
-- 160:0222222222000000200003332000000020300000200300002200000002222222
-- 161:2222222000000022300030020000030200000002000000020000002222222220
-- 162:0222222022000022200030022000030220000002200003022000030220000302
-- 163:0666666066000066600050066000050660000006600005066000050660000506
-- 164:0aaaaaa0aa0000aaa000b00aa0000b0aa000000aa0000b0aa0000b0aa0000b0a
-- 166:000000000000000c000000cd000cccdd00cecddd00ceeded000ccede00000ccc
-- 167:cccc00008888cc0088888cc0888888c0d88888ccdd88d88cdddddcc0ccccc000
-- 168:000000000000e000000e00000000000e00000000000000e000000e0000000000
-- 169:000000000000e000e00e0000000000000e000000e0000000000e0000e0e00000
-- 170:00000000000000e0000e000000e0000e000000e00000000000000e0e0000e000
-- 171:0000000000000000000e000000e0000000000000e00000000000000000e00000
-- 172:0000000000333330033aaa3303aa5aa303aaa5a303aaaaa3033aaa3300333330
-- 173:000000000cccccc00c6567c00c5667c00c6667c00cccccc00000000000000000
-- 176:0666666666000000600005556000000060500000600500006600000006666666
-- 177:6666666000000066500050060000050600000006000000060000006666666660
-- 178:2000030220000002200000022000000220300002200300022200002202222220
-- 179:6000050660000006600000066000000660500006600500066600006606666660
-- 180:a0000b0aa000000aa000000aa000000aa0b0000aa00b000aaa0000aa0aaaaaa0
-- 182:00000000000000e000000e0000e000000e0000e000000e000000000e0000e0e0
-- 183:000000000000e0000000000000e000000e00000000000000000e000000000000
-- 184:000000000000000000000e000000e0000e00000000000e000000e000000000e0
-- 185:000000000000e000000e0000000000000e000000e0000000000e000000e00000
-- 186:0000000000000000000000000000e000000e0000e00000000000e000000e0000
-- 187:00000e000e00e000e000000000e000000e0000000000e0000e0e000000000000
-- 188:0000000000ddddd00ddaaadd0daa5aad0daaa5ad0daaaaad0ddaaadd00ddddd0
-- 190:0eeeeeeeee000000e0000ddde0000000e0d00000e00d0000ee0000000eeeeeee
-- 191:eeeeeee0000000eed000d00e00000d0e0000000e0000000e000000eeeeeeeee0
-- 192:0aaaaaaaaa000000a0000bbba0000000a0b00000a00b0000aa0000000aaaaaaa
-- 193:aaaaaaa0000000aab000b00a00000b0a0000000a0000000a000000aaaaaaaaa0
-- 194:8000000880000008800000088000000880000008800000088000000880000008
-- 195:d000000dd000000dd000000dd000000dd000000dd000000dd000000dd000000d
-- 196:e000000ee000000ee000000ee000000ee000000ee000000ee000000ee000000e
-- 197:f000000ff000000ff000000ff000000ff000000ff000000ff000000ff000000f
-- 198:f000000f00000000f000000f00000000f000000f00000000f000000f00000000
-- 202:eeeeeeeeee0000eee000e00ee0000e0ee0e0000ee00e000eee0000ee0eeeeee0
-- 203:08888880880000888000d00880000d088000000880000d0880000d0880000d08
-- 204:0dddddd0dd0000ddd000d00dd0000d0dd000000dd0000d0dd0000d0dd0000d0d
-- 205:0eeeeee0ee0000eee000d00ee0000d0ee000000ee0000d0ee0000d0ee0000d0e
-- 206:0ddddddddd000000d0000dddd0000000d0d00000d00d0000dd0000000ddddddd
-- 207:ddddddd0000000ddd000d00d00000d0d0000000d0000000d000000ddddddddd0
-- 208:8000000080000000800000008000000080000000800000008000000080000000
-- 209:0000000800000008000000080000000800000008000000080000000800000008
-- 210:d0000000d0000000d0000000d0000000d0000000d0000000d0000000d0000000
-- 211:0000000d0000000d0000000d0000000d0000000d0000000d0000000d0000000d
-- 212:e0000000e0000000e0000000e0000000e0000000e0000000e0000000e0000000
-- 213:0000000e0000000e0000000e0000000e0000000e0000000e0000000e0000000e
-- 214:f0000000f0000000f0000000f0000000f0000000f0000000f0000000f0000000
-- 215:0000000f0000000f0000000f0000000f0000000f0000000f0000000f0000000f
-- 216:f000000000000000f000000000000000f000000000000000f000000000000000
-- 217:0000000f000000000000000f000000000000000f000000000000000f00000000
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
-- 240:0cccccccccffffffcfffffffcfffffffcfffffffcfffffffccffffff0ccccccc
-- 241:ccccccc0ffffffccffffdffcfffffdfcfffffffcfffffffcffffffccccccccc0
-- 242:0ccccccccc777777c7777555c7777777c7777777c7777777cc7777770ccccccc
-- 243:ccccccc0777777cc5777577c7777757c7777777c7777777c777777ccccccccc0
-- 244:0cccccc0cc9999ccc999b99cc9999b9cc999999cc999999ccc9999cc0cccccc0
-- 245:0cccccc0ccffffcccfffeffccffffefccffffffccffefffcccffffcc0cccccc0
-- 246:0cccccc0ccaaaacccaaabaaccaaaabacca9aaaaccaa9aaacccaaaacc0cccccc0
-- 247:0cccccc0cceeeeccceeedeecceeeedeccefeeeecceefeeeccceeeecc0cccccc0
-- 248:0ccccccccceeeeeeceeeedddceeeeeeecefeeeeeceefeeeecceeeeee0ccccccc
-- 249:ccccccc0eeeeeeccdeeedeeceeeeedeceeeeeeeceeeeeeeceeeeeeccccccccc0
-- 250:0ccccccccc666666c6666555c6666666c6766666c6676666cc6666660ccccccc
-- 251:ccccccc0666666cc5666566c6666656c6666666c6666666c666666ccccccccc0
-- 252:c222232cc222222cc222222cc222222cc212222cc221222ccc2222cc0cccccc0
-- 253:c666656cc666666cc666666cc666666cc676666cc667666ccc6666cc0cccccc0
-- 254:caaaabaccaaaaaaccaaaaaaccaaaaaacca9aaaaccaa9aaacccaaaacc0cccccc0
-- </SPRITES>

-- <MAP>
-- 001:6d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:0000000000000000000000000000000000000000000000000000000000000000004e4e4e4e0000000000000000005e5e5e5e0000005e5e5e5e00000000000000005f5f5f5f5f5f5f5f5f5f005f5f5f5f5f5f5f5f5f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:0000000000000000000000000000000000000000000000000000000000000000004e4e4e4e4e000000000000005e5e5e5e5e5e005e5e5e5e5e5e000000000000005f6e6e6e5f5f7e7e7e5f005f6f6f6f5f6f6f6f5f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:00000000000000007e00000000000000006f00006f0000000000000000000000004e4e00004e4e004f4f4f4f005e5e00005e5e005e5e00005e5e000000000000005f6e5f6e6e5f7e5f7e5f005f6f5f6f5f6f5f6f5f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:000000000000de00afbf000000000000006fee000000ee8e9eee000000000000004e4e0000004e4e4f4f4f4f005e5e00005e5e005e5e00005e5e000000000000005f6e5f5f6e5f7e7e5f5f005f6f6f6f5f6f5f6f5f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:000000000000df007eafbf000000ce00006fef6d0000ef8e9eef000000000000004e4e0000004e4e4f4f004f005e5e5e5e5e5e005e5e00005e5e000000000000005f6e5f6e6e5f7e7e7e5f5f5f6f5f6f5f6f5f6f5f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:000000000000de7e00007e00ce00cf00008e9e6f6f006f000000000000000000004e4e0000004e4e4f4f004f00005e5e5e5e00005e5e00005e5e000000000000005f6e6e6e5f5f7e5f7e7e5f5f6f6f6f5f6f6f6f5f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:000000000000dfde0000de00cf006e0000008e9e00006f0000ee000000000000004e4e0000004e4e4f4f4f4f005e5e5e5e5e5e005e5e00005e5e000000000000005f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:0000000000007edf0000df00aebe0000006fee006f00ee0000ef000000000000004e4e0000004e4e4f4f0000005e5e00005e5e005e5e00005e5e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:000000000000deafbfafbf5f6e6e6e005f6fef006f00ef8e9e6f000000000000004e4e0000004e4e4f004f4f005e5e00005e5e005e5e00005e5e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:000000000000df00007e5f5f6e006e5f5f8e9e8e9e5f8e9e8e9e000000000000004e4e4e4e4e4e4e4f004f4f005e5e5e5e5e5e005e5e5e5e5e5e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:00000000005f5f5f0f1f5f5f5f5f5f5f5f0f1f5f5f5f5f5f5f5f000000000000004e4e4e4e4e4e4e4f00004f00005e5e5e5e0000005e5e5e5e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:000000005f5f5f5f5f5f5f00000000000000000000005f0f1f5f5f5f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:000000005f0f1f5f5f0f1f00000000000000000000005f5f005f5f5f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:0000000f1f5f5f5f5f5f0000000000000000000000000f1f5f5f5f5f5f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:005f0f1f000f1f5f5f0f1f5f5f5f5f5f5f5f0f1f5f5f5f5f5f0f1f5f5f5f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:000000000000000fffffffffffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:13579abddeefffffecb9754322211100
-- 003:234467889a7bbccdddccbba987654321
-- 004:79bcdeefffeedcb97532110001123576
-- 005:ffff00000000000000000fffffffffff
-- 009:00000000000000000000006600000000
-- 012:12345678889bcdeffedcb98887654321
-- 013:2467899abbcccccccccccbbbaa987642
-- 014:ca987654432211a99877665544332211
-- 015:12345666666666666789abcdedcba987
-- </WAVES>

-- <SFX>
-- 000:14c0249e346e442f641074639495b445c400d400e400e400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400301000000000
-- 001:2100310e311a4128514a616f818791c7a1f7b1f0c1f0e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100316000000000
-- 002:010d010e013f11301161118221a321c531d741d061008100a100c100d100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100c11000000000
-- 003:0100117021003190410051b0710091d0a100c1f0d100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100377000000000
-- 004:01f011c0112011a02130319031404170515051a061607170814091309110a120b100b150b100c100c180c130c120d130d120d110e110f100f100f100240000000000
-- 005:14e01430343064307440848094e0b450c4d0d430e440e400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400300000000000
-- 006:0cb01cb42cb32ca42c62fc010c001c0f2c0d4c0b5c0a8c0a8c0afc0afc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00300000000000
-- 008:bcaeac4d9c3a8c296c2b6c306c314c415c416c607c709c80ac90bca0cc00dc00ec00ec00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00410000000000
-- 009:ede0bdeeadea8de87dca6dbf5da74d973d773df03d403d303d204d105d106d007d008d008d009d009d00ad00bd00cd00cd00dd00ed00fd00fd00fd00316000000000
-- 010:deeadedaaedc9ecd7eb66ebf6ea15e935e945e951e865e865e775e676e676e577e577e468e469e35ae02be20ce10ce00de00ee00ee00fe00fe00fe00315000000000
-- 011:efe0dfdebfba7fa86f9a4f8f3f772f672f572f402f402f303f304f304f205f207f208f208f20af20af10af10bf10bf10cf00df00ef00ef00ff00ff00410000000000
-- 012:1c0d2c1e3c4f5c607c81acb2ccd3dc05dc07fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00b10000000000
-- 013:2d0d2d0e3d3f4d305d616d828da3adc5cdd7edd0ed00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00b16000000000
-- 014:1e0b2e1d3e3e5e617e95be80ee00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00a15000000000
-- 015:1f0d1f0e1f3f1f302f614f826fa39fc5bfd7dfd0ef00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00c10000000000
-- 016:5cf05cc05c005c005c905c705c006c506c606c006c006c906c007c007c208c108c009c009c00ac00bc00bc00dc00ec00fc00fc00fc00fc00fc00fc00340000000000
-- 017:5df05dc05d005d005d905d705d006d506d606d006d006d906d007d007d208d108d009d009d00ad00bd00bd00dd00ed00fd00fd00fd00fd00fd00fd00346000000000
-- 018:fe0a2e8ebe012e948e052ec7fe07fe07fe071ef72ed63e95fe648ec29e70fe3dae9cbe5afe29de18ee00ee00fe00fe00fe00fe00fe00fe00fe00fe00255000000000
-- 019:ff0b2f8fbf022f948f062fc6ff06ff05ff051ff42fd33f92ff618fc09f7eff3caf9abf58ff28df18ef00ef00ff00ff00ff00ff00ff00ff00ff00ff00450000000000
-- 020:0cc60cc51cc1fcb02c8f4c5a9c10fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00200000000000
-- 021:0db61db6fdb51da02d6b4d09fd09fd0ffd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00206000000000
-- 022:0e750e754e63fe6f1e5b3e0abe0afe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00205000000000
-- 023:0f761f75ff63ff6f3f5d3f0cff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00300000000000
-- 024:0c001c702c003c904c005cb07c009cd0ac00ccf0dc00ec00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00370000000000
-- 025:0d001d702d003d904d005db07d009dd0ad00cdf0dd00ed00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00376000000000
-- 026:0e001e703e003e904e004eb07e005ed06e007ef08e009e00ae00ce00de00ee00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00275000000000
-- 027:0f001f703f003f904f005fb07f008fd0af00bff0cf00df00df00ef00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00470000000000
-- 028:1ce04c307c30acd0ccc0ec80fc20fc20fc10fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00fc00300000000000
-- 029:2de05d309dd0bd30ddd0dd80ed40ed10fd00fd10fd10fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00fd00306000000000
-- 030:2ee04e307ee0beb0de40ee60fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00fe00205000000000
-- 031:2fe04f307f309f30af40cf80dfe0ef50efd0ff30ff40ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00400000000000
-- 032:100010001000200030003000500070008000a000c000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000300000000000
-- 033:b200b200b200b200b200b200b200b200b200b200b200b200d200a200d200d200b200b200b200d200b200b200b200b200b200b200b200b200b200b200670000000000
-- 034:e100810061005100410041005100610081009100b100c100e100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100300000000000
-- 035:61005100510041004100410051006100710071008100a100b100c100d100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100400000000000
-- 036:f100a10071006100510041003100210021002100310041005100610071009100a100c100d100e100f100f100f100f100f100f100f100f100f100f100300000000000
-- 037:d310b3209322833d735173526351536153615371536153516340633073307320733f832f8333835f936fa3bfb34fc362d371d371e380e38fe34ff30f480000000000
-- 038:1400145024002480240024b03400448054006430740084009400a400b400d400e400e400f400f400f400f400f400f400f400f400f400f400f400f400000000000000
-- 039:143014001460240034a0440054c0640074f084009400a400c400d400d400e400e400f400f400f400f400f400f400f400f400f400f400f400f400f400000000000000
-- 040:e5009500650045003500150005000500050005000500050005001500250035003500450055006500750085009500a500b500d500d500e500f500f500501000000000
-- 041:31a2215311440135012501260126012501b3011f01a8111811182119210a310b410c510e510f5100610071509140a140b130b130c120e120e110f110111000000000
-- 048:d100a10071005100310021001100110011002100410061009100c100d100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100510000000000
-- 049:d1008120410031306180f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100560000000000
-- 050:d1008120410031306180f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f1005e0000000000
-- </SFX>

-- <PATTERNS>
-- 000:400846000840000840000000400846000000000000000000601f46000840000000000000600846600846000000000000800846000000000000000000800846000000000000000000602f46000840000000000000600846600846000000000000400846000000000000000000400846000000000000000000601f46000000000000000000600846600846000000000000800846000000000000000000800846000000000000000000602f46000000000000000000600846600846000000000000
-- 001:000830000000000830602c32400832000000000000000000000830000000a00832600832400832000000000000000000401f32000000000000000000402f32000000a00832600832400832000000000000000000000830000830000000000000000830000000000000600832400832000000000830000830000830000000a00832600832400832000000000000000000401f32000000000830000830402f32000000a00832600832400832000000000000000830000830000000000000000000
-- 002:43ae1a000820b0081a00081003be10000000000000000000000000000000000000000000000000000000000000000000400826000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b3ae1a00082043be1a000000000810000000000000000000000000000000000000000000000000000000000000000000400826000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:400846000840000840000000400846000000000000000000601f46000840000000000000600846600846000000000000800846000000000000000000800846000000000000000000602f46000840000000000000600846600846000000000000400846000000000000000000400846000000000000000000601f46000000000000000000600846600846000000000000800846000000000000000000800846000000000000000000602f46000000000000000000600846600846000000000000
-- 009:b44904000840b00804000000e00804000000f00804000000400806000000f00804000000e00804000000d00804000000b00804000000b00804000000e00804000000f00804000000400806000000f00804000000e00804000000d00804000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 010:b44902000840b00802000000e00802000000f00802000000400804000000f00802000000e00802000000d00802000000b00802000000b00802000000e00802000000f00802000000400804000000f00802000000e00802000000d00802000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 011:e44908000840f00808000000e00808000000f00808000000d00808000000b00808000000b00808000000d00808000000e00808000000f00808000000d00808000000b00808000000b00808000000000800000000000800000000000800000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 012:e44908000840f00808000000e00808000000f00808000000d00808000000b00808000000b00808000000d00808000000000800000000000800000000000800000000000800000000000800000000000800000000000800000000000800000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 013:b44902000000b01f02000800000800000000b00802000800400804000000401f04000800000800000000400804000800b00802000800b01f02000800000800000000b00802000800400804000000401f04000000000800000000400804000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:444902000000401f02000800000800000000400802000800900802000000901f02000800000800000000900802000800400802000800401f02000800000800000000400802000800900802000000901f02000000000800000000900802000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:744908000840800808000000700808000000800808000000600808000000400808000000400808000000d00806000000700808000000800808000000600808000000400808000000400808000000000800000000000800000000000800000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 016:744908000840800808000000700808000000800808000000600808000000400808000000400808000000d00806000000a00806000000d00806000000f00806000000600808000000404c08000000000800000000f04c06000000000800000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 017:744908000840800808000000600808000000400808000000400808000000000800000000000800000000000800000000700808000000800808000000600808000000400808000000400808000000000800000000000800000000000800000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 018:744908000840800808000000700808000000800808000000600808000000400808000000400808000000d00806000000400808000000000800000000604c08000000000800000000409c08000000000800000000000800000000000800000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 019:844e18000000000000000000000000000000000000000000600818000000000000000000b00818000000000000000000400818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 020:d44e18000000000000000000000000000000000000000000b0081800000000000000000040081a000000000000000000900818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 021:d44e18000000000000000000000000000000000000000000b00818000000000000000000f0081800000000000000000040081a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 022:444904000840000800000000000000000000400804000000000000000000000800000000f00802000000000800000000d00802000000000000000000000000000000d00802000000000000000000000000000800d00802000000000000000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 023:944904000840000800000000000000000000900804000000000000000000000800000000800802000000000800000000600802000000000000000000000000000000600802000000000000000000000000000800600802000000000000000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000b00846000000b00846000000e00846000000f00846000000400848000000f00846000000e00846000000d00846000000
-- 024:d99e1a000000000000000000000000000000000000000000b0081a000000000000000000f0081a00000000000000000040081c000000000000000000000800000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 025:b33904000000b01f04000800000800000000b00804000800400806000000401f06000800000800000000400806000800b00804000800b01f04000800000800000000b00804000800400806000000401f06000000000800000000400806000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 029:54498a00000000000000000050088a00000000000000000050088a00000000000000000010088000000000000000000000000000000000000060088a00000000000000000060088a80088a00000000000000000080088a00000000000000000050088a00000000000000000060088a00000000000050088a00088000000000000000000010088000000000000000000000000000000000000060088a00000000000000000060088a80088a00000000000000000080088a000000000000000000
-- 030:50088a00000000000000000060088a00000000000000000050088a00000000000000000010088000000000000000000000088000000000000060088a00000000000000000060088a80088a00000000000000000080088a00000000000000000010088000000000000000088000088000000000000060088a00088000000000000060088a80088a00000000000000000080088a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 031:54498a00000000000000000050088a000000000000d0088800088000000000000000000010088000000000000000000000000000000000000060088a00000000000000000060088a80088a00000000000000000080088a00000000000000000050088a00000000000000000060088a00000000000050088a000880000000000000000000100880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:54498a00000000000000000080088a000000000000d00888000880000000000000000000100880000000000000000000000000000000000000a0088a000000000000000000a0088a80088a00000000000060088a50088a000000000000f0088850088a00000000000000000080088a000000000000d00888000880000000000000000000100880000000000000000000000000000000000000d00888000000000000000000d00888c00888000000000000d00888f00888000000000000d00888
-- 033:54498a00000000000000000080088a000000000000d00888000000000000000000000000100880000000000000000000000000000000000000a0088a000000000000000000a0088a80088a00000000000060088a50088a000000000000f0088850088a00000000000000088080088a000000000000d00888000000000000000000000000000000000000000000000000000000000000000000d00888000000000000000000d00888c00888000000000000d00888f00888000000000000d00888
-- 034:54498a00000000000000000080088a000000000000d00888000000000000000000000000100880000000000000000000000000000000000000a0088a000000000000000000a0088a80088a00000000000060088a50088a000000000000f0088850088a00000000000000088080088a000000000000d00888000880000000000000000000000000000000000000000000000000000000000000d00888000000000000000000d00888c00888000000000000d00888f00888000000000000d00888
-- 035:044100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000880000880000000000000000000000880000000000000000000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800886600886000000000000000000500886000000000000000000f00884000000000000000000
-- 036:d44984000000000000000000500886000000000000000000a00884000000000000000000d00884000000000000000000600886000000000000600886a00886000000000000000000800886000000000000000000c00886000000000000000000d00886000000000000000000500888000000000000000000a00886000000000000000000d00886000000000000000000600886000000000000600886a00886000000000000000000800886000000000000000000c00886000000000000000000
-- 037:d44986000000000000000880500888000000000000000000a00886000000000000000000d00886000000000000000000600886000000000000600886a00886000000000000000000800886000000000000000000c00886000000000000000000d00886000000000000000000500888000000000000000000a00886000000000000000000d00886000000000000000000600888000000000000600888a00886000000000000000000800886000000000000c00886c00886000000000000000000
-- 038:022200000000000000000000000000000000000000000000500892000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500892000000000000000000000000000000000000000000000880000000000000000000000000000000000000000000500892000000000000000000000000000000000000000000000880000000000000000000000000000000000000000000500892000000000000000000000000000000000000000000
-- 039:f44984000880000880000880000880000000000000000880000880000880800886000880a00886000880800886000880500888000000000000000000f00886000000000000000000c00886000000b00886000000b00886000000a00886000880a00886000000800886000880800886000000000000000000800886000000000000000000000000000000800886000000a00886000000a00886000000a00886000000800886000000c00886000000800886000000000000000000800886000000
-- 040:044980000880000880000880000880000000000000000880000880000880000880000880800886000880800886000880500888000000500888000000f00886000000f00886000000c00886000000b00886000000b00886000000a00886000880a00886000000800886000880800886000000000000000000800886000000000000000000000000000000800886000000a00886000000a00886000000a00886000000800886000000c00886000000800886000000000000000000800886000000
-- 041:044980000880000880000880000880000000000000000880000880000880000880000880800886000880600886000880500886000000800886000000000880000000800886000000000880000000000880000000000880000000000880000880f00884000000800886000880000880000000800886000000000880000000000000000000000000000000000880000880d00884000000800886000000000880000000800886000000000880000000000880000000000000000000d00884000000
-- 042:c44984000880800886000880000880000000800886000880000880000880000880000880000880000880000880000880500886000000800886000000000880000000800886000000000880000000000880000000000880000000500886000880f00884000000800886000880000880000000800886000000000880000000000000000000000880000000600886000880500886000000800886000000000880000880800886000000000880000000000880000000000880000000f00886000000
-- 043:044100000000000000000000000000000000000000000000000880000000000880000000000880000000000880000000a00884000000c00884000000f00884000000000000000000000000000000000000000000000000000000000000000000f00884000000c00884000000a00884000000000000000000000000000000000000000000000000000000000000000000a00884000000c00884000000f00884000000000000000000000000000000000000000000000000000000000000000000
-- 044:044980000000000880000000000880000000000000000000000880000000000880000000000880000000000880000000a00884000000c00884000000f00884000000000000000000000000000000000000000000000000000000000000000000a00884100880d00884100880f00884000000000880000000000000000000000000000000000000000000000000000000a00884100880c00884100880f00884000000000000000000000000000000000000000000000000000000000000000000
-- 045:500892000890000000000000000000000000000000000000500892000000000000000000000000000000000000000000a00892000890000000000000000000000000000000000000a00892000000000000000000000000000000000000000000500892000890000000000000000890000000000000000000500892000000000000000000000000000000000000000000a00892000890000000000000000000000000000000000000a00892000000000000000000000000000000000000000000
-- 046:044910033600000000000000000000000000000000000000000000000000000000000000000000000000000000000000544e1a000000000000000000000810000000000810000810000000000000100810000000000000000000000000000000a55e1a000000000000000000000000000000000810000810000000000000000000000000000810000000100810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </PATTERNS>

-- <TRACKS>
-- 000:100000180000180300180300100000180000180300180300100000000000000000000000000000000000000000000000dd0000
-- 001:a00000ac2000ac2c00ac2d00ec2c00ec2d00e00010e001100c2210f003104d50005160004d5000616910a10e00a100001f0200
-- 002:e107200297201697202a97203697201a9720000000000000000000000000000000000000000000000000000000000000500000
-- 003:82072092bf20a6b720b6bf200000000000000000000000000000000000000000000000000000000000000000000000006f0000
-- </TRACKS>

-- <SCREEN>
-- 000:cccccccccccccccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 001:ccffffccccffffccee0000eeee0000eeee0000eeee0000eeee0000eeee0000eeee0000eeee0000eeee0000eeee0000eeee0000eeee0000eeccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffcc
-- 002:cfffeffccfffeffce000e00ee000e00ee000e00ee000e00ee000e00ee000e00ee000e00ee000e00ee000e00ee000e00ee000e00ee000e00ecfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffc
-- 003:cffffefccffffefce0000e0ee0000e0ee0000e0ee0000e0ee0000e0ee0000e0ee0000e0ee0000e0ee0000e0ee0000e0ee0000e0ee0000e0ecffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefc
-- 004:cffffffccffffffce0e0000ee0e0000ee0e0000ee0e0000ee0e0000ee0e0000ee0e0000ee0e0000ee0e0000ee0e0000ee0e0000ee0e0000ecffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffc
-- 005:cffefffccffefffce00e000ee00e000ee00e000ee00e000ee00e000ee00e000ee00e000ee00e000ee00e000ee00e000ee00e000ee00e000ecffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffc
-- 006:ccffffccccffffccee0000eeee0000eeee0000eeee0000eeee0000eeee0000eeee0000eeee0000eeee0000eeee0000eeee0000eeee0000eeccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffcc
-- 007:ccccccc00cccccc00eeeeee00eeeeee00eeeeee00eeeeee00eeeeee00eeeeee00eeeeee00eeeeee00eeeeee00eeeeee00eeeeee00eeeeee00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00ccccccc
-- 008:ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc00cccccccccccccc00cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
-- 009:ccffffcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcccc666666222222ccccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc
-- 010:cfffeffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cfffeffcc66665553222322ccfffeffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cfffeffc
-- 011:cffffefc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffffefcc66666662222232ccffffefc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffffefc
-- 012:cffffffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffffffcc67666662222222ccffffffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffffffc
-- 013:cffefffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffefffcc66766662222222ccffefffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffefffc
-- 014:ccffffcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcccc666666222222ccccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc
-- 015:ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc00cccccccccccccc00cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
-- 016:ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc00cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
-- 017:ccffffcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffccccffffccccffffccccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc
-- 018:cfffeffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cfffeffccfffeffccfffeffccfffeffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cfffeffc
-- 019:cffffefc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffffefccffffefccffffefccffffefc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffffefc
-- 020:cffffffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffffffccffffffccffffffccffffffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffffffc
-- 021:cffefffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffefffccffefffccffefffccffefffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffefffc
-- 022:ccffffcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffccccffffccccffffccccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc
-- 023:ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc00cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
-- 024:ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
-- 025:ccffffcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc0000000000000000ccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc
-- 026:cfffeffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cfffeffc0000000000000000cfffeffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cfffeffc
-- 027:cffffefc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffffefc0000000000000000cffffefc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffffefc
-- 028:cffffffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffffffc0000000000000000cffffffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffffffc
-- 029:cffefffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffefffc0000000000000000cffefffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffefffc
-- 030:ccffffcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc0000000000000000ccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc
-- 031:ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
-- 032:ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
-- 033:ccffffcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc0000880088880000ccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc
-- 034:cfffeffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cfffeffc0008880000088000cfffeffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cfffeffc
-- 035:cffffefc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffffefc0000880008880000cffffefc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffffefc
-- 036:cffffffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffffffc0000880088000000cffffffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffffffc
-- 037:cffefffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffefffc0008888088888000cffefffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffefffc
-- 038:ccffffcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc0000000000000000ccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc
-- 039:ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
-- 040:ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
-- 041:ccffffcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc0000000000000000ccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc
-- 042:cfffeffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cfffeffc0000000000000000cfffeffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cfffeffc
-- 043:cffffefc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffffefc0000000000000000cffffefc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffffefc
-- 044:cffffffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffffffc0000000000000000cffffffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffffffc
-- 045:cffefffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffefffc0000000000000000cffefffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffefffc
-- 046:ccffffcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc0000000000000000ccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc
-- 047:ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
-- 048:ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc00cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
-- 049:ccffffcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffccccffffccccffffccccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc
-- 050:cfffeffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cfffeffccfffeffccfffeffccfffeffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cfffeffc
-- 051:cffffefc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffffefccffffefccffffefccffffefc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffffefc
-- 052:cffffffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffffffccffffffccffffffccffffffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffffffc
-- 053:cffefffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffefffccffefffccffefffccffefffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffefffc
-- 054:ccffffcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffccccffffccccffffccccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc
-- 055:ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc00cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
-- 056:ccccccc000000000c00cc00c000000000000000000cccc00000000000cccccccccccccc000000000000000000000000000000000cc0000cc000000000cccccc000000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
-- 057:ccffffcc000000000cc11cc000000000000000000caaaac000000000ccaaaaaa666666cc00000000000000000000000000000000c4cccc4c00000000ccffffcc0000000000000000ccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc
-- 058:cfffeffc00000000cc1221cc0000000000000000cccaaccc00000000caaaabbb5666566c00000000000000000000000000000000c46cc64c00000000cfffeffc0000000000000000cfffeffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cfffeffc
-- 059:cffffefc00000000c122221c0000000000000000ca8228ac00000000caaaaaaa6666656c00000000000000000000000000000000c6c44c6c00000000cffffefc0000000000000000cffffefc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffffefc
-- 060:cffffffc00000000c28cc82c0000000000000000c6aaaa6c00000000ca9aaaaa6666666c00000000000000000000000000000000c687786c00000000cffffffc0000000000000000cffffffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffffffc
-- 061:cffefffc00000000c322223c00000000000000000c9aa9c000000000caa9aaaa6666666c00000000000000000000000000000000cc6666cc00000000cffefffc0000000000000000cffefffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffefffc
-- 062:ccffffcc000000000c2222c000000000000000000b9999b000000000ccaaaaaa666666cc000000000000000000000000000000000cc66cc000000000ccffffcc0000000000000000ccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc
-- 063:ccccccc00000000000cccc00000000000000000000000000000000000cccccccccccccc00000000000000000000000000000000000cccc00000000000cccccc000000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
-- 064:ccccccc0cc0000cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
-- 065:ccffffccc4cccc4c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc0000000000000000ccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc
-- 066:cfffeffcc46cc64c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cfffeffc0000000000000000cfffeffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cfffeffc
-- 067:cffffefcc6c44c6c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffffefc0000000000000000cffffefc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffffefc
-- 068:cffffffcc687786c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffffffc0000000000000000cffffffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffffffc
-- 069:cffefffccc6666cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffefffc0000000000000000cffefffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffefffc
-- 070:ccffffcc0cc66cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc0000000000000000ccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc
-- 071:ccccccc000cccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
-- 072:ccccccc00000000000000000000000000000000000000000c00cc00c00000000000000000000000000000000000000000000000000cccc00000000000cccccc000000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
-- 073:ccffffcc00000000000000000000000000000000000000000cc11cc00000000000000000000000000000000000000000000000000caaaac000000000ccffffcc0000000000000000ccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc
-- 074:cfffeffc0000000000000000000000000000000000000000cc1221cc000000000000000000000000000000000000000000000000cccaaccc00000000cfffeffc0000000000000000cfffeffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cfffeffc
-- 075:cffffefc0000000000000000000000000000000000000000c122221c000000000000000000000000000000000000000000000000ca8228ac00000000cffffefc0000000000000000cffffefc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffffefc
-- 076:cffffffc0000000000000000000000000000000000000000c28cc82c000000000000000000000000000000000000000000000000c6aaaa6c00000000cffffffc0000000000000000cffffffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffffffc
-- 077:cffefffc0000000000000000000000000000000000000000c322223c0000000000000000000000000000000000000000000000000c9aa9c000000000cffefffc0000000000000000cffefffc00000000000000000000000000000000000000000000000000000000000000000000000000000000cffefffc
-- 078:ccffffcc00000000000000000000000000000000000000000c2222c00000000000000000000000000000000000000000000000000b9999b000000000ccffffcc0000000000000000ccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc
-- 079:ccccccc0000000000000000000000000000000000000000000cccc0000000000000000000000000000000000000000000000000000000000000000000cccccc000000000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
-- 080:ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000000000000000cccccc0000000000c00ccccccccc00c00000000c7c0ccccccccc000000000000000000000000000000000000ccccccc
-- 081:ccffffcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc0000000000000000ccffffcc00000000c2ccc3333332ccc200000000c44cc6656666cccc000000000000ccccccccc0b000000000ccffffcc
-- 082:cfffeffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cfffeffc0000000000000000cfffeffc000000000ccc366333232ccc000000000c4c655666666c44000000000b0ccaaaaaa2cca000000000cfffeffc
-- 083:cffffefc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffffefc0000000000000000cffffefc000000000cc32188888812c0000000000c444666666664470000000009cca999999a2cc000000000cffffefc
-- 084:cffffffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffffffc0000000000000000cffffffc000000000cc21881cc18812c000000000c4444444444444c000000000cc6bbb992a2a2c000000000cffffffc
-- 085:cffefffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffefffc0000000000000000cffefffc000000000c22188cccc8812c000000000c44ccc4444ccc6c000000000ccaabaaaaaaaabc00000000cffefffc
-- 086:ccffffcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc0000000000000000ccffffcc000000000c122181cc18122c000000000c4684877778486c000000000caab88aa2a8cabc00000000ccffffcc
-- 087:ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000000000000000cccccc0000000000c1222222222222c000000000c6766666666666c000000000c9abc8a2aac8abc000000000ccccccc
-- 088:ccccccc00000000000000000000000000000000000000000000000000cccccccccccccc00000000000000000000000000000000000000000000000000cccccc000000000000000000cccccc0000000000c1122222222222c000000000c7676666666666c000000000c9aabaaaaaaaabc000000000ccccccc
-- 089:ccffffcc000000000000000000000000000000000000000000000000ccaaaaaa666666cc000000000000000000000000000000000000000000000000ccffffcc0000000000000000ccffffcc000000000c1112222222222c000000000c7767666666666c000000000c9baaabbbbbbbbc00000000ccffffcc
-- 090:cfffeffc000000000000000000000000000000000000000000000000caaaabbb5666566c000000000000000000000000000000000000000000000000cfffeffc0000000000000000cfffeffc000000000cc11122222212c00000000000c7767ccc6666c0000000000c99bbbbbbbbbbbc00000000cfffeffc
-- 091:cffffefc000000000000000000000000000000000000000000000000caaaaaaa6666656c000000000000000000000000000000000000000000000000cffffefc0000000000000000cffffefc000000000ccc111cccc11cc00000000000cc777666666cc00000000000c99bbbbbbbbbc000000000cffffefc
-- 092:cffffffc000000000000000000000000000000000000000000000000ca9aaaaa6666666c000000000000000000000000000000000000000000000000cffffffc0000000000000000cffffffc000000000c0ccc111111c0c00000000000cccc776666c0c0000000000acccb999999bcc000000000cffffffc
-- 093:cffefffc000000000000000000000000000000000000000000000000caa9aaaa6666666c000000000000000000000000000000000000000000000000cffefffc0000000000000000cffefffc000000000c000ccccccc00c00000000000c00ccccccc00c00000000000000bccccccb09000000000cffefffc
-- 094:ccffffcc000000000000000000000000000000000000000000000000ccaaaaaa666666cc000000000000000000000000000000000000000000000000ccffffcc0000000000000000ccffffcc000000000200c21c0c12c020000000000060c64c0c46c060000000000000c61c0c1ac00000000000ccffffcc
-- 095:ccccccc00000000000000000000000000000000000000000000000000cccccccccccccc00000000000000000000000000000000000000000000000000cccccc000000000000000000cccccc0000000000000cccc0cccc000000000000000cccc0cccc000000000000000cccc0cccc000000000000ccccccc
-- 096:ccccccc000000000000000000000000000000000000000000000000000000000cc0000cc00000000c00cc00c000000000000000000000000000000000cccccc00000cc00000000000cccccc0000000000cccccccccccccc0000000000cccccccccccccc0000000000cccccccccccccc0000000000ccccccc
-- 097:ccffffcc00000000000000000000000000000000000000000000000000000000c4cccc4c000000000cc11cc000000000000000000000000000000000ccffffcc000c2cccccccc000ccffffcc00000000cc111111111111cc00000000cc777777777777cc00000000cc999999999999cc00000000ccffffcc
-- 098:cfffeffc00000000000000000000000000000000000000000000000000000000c46cc64c00000000cc1221cc00000000000000000000000000000000cfffeffc000c112122222c00cfffeffc00000000c11113333111311c00000000c77775555777577c00000000c9999bbbb999b99c00000000cfffeffc
-- 099:cffffefc00000000000000000000000000000000000000000000000000000000c6c44c6c00000000c122221c00000000000000000000000000000000cffffefc00c11212122222c0cffffefc00000000c11111111111131c00000000c77777777777757c00000000c999999999999b9c00000000cffffefc
-- 100:cffffffc00000000000000000000000000000000000000000000000000000000c687786c00000000c28cc82c00000000000000000000000000000000cffffffc0c112551212222c0cffffffc00000000c11111111111111c00000000c77777777777777c00000000c99999999999999c00000000cffffffc
-- 101:cffefffc00000000000000000000000000000000000000000000000000000000cc6666cc00000000c322223c00000000000000000000000000000000cffefffc00cc5c55c52222c0cffefffc00000000c11111111111111c00000000c77777777777777c00000000c99999999999999c00000000cffefffc
-- 102:ccffffcc000000000000000000000000000000000000000000000000000000000cc66cc0000000000c2222c000000000000000000000000000000000ccffffcc000c5a55a55152c0ccffffcc00000000cc111111111111cc00000000cc777777777777cc00000000cc999999999999cc00000000ccffffcc
-- 103:ccccccc00000000000000000000000000000000000000000000000000000000000cccc000000000000cccc00000000000000000000000000000000000cccccc0000c5555555cccc00cccccc0000000000cccccccccccccc0000000000cccccccccccccc0000000000cccccccccccccc0000000000ccccccc
-- 104:ccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc0000cc00cccc00000000000cccccc00000cccccccc00000cccccc0000000000cccccccccccccc0000000000cccccccccccccc0000000000cccccccccccccc0000000000ccccccc
-- 105:ccffffcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c4cccc4c0caaaac000000000ccffffcc000000ccccc00000ccffffcc00000000cc111111111111cc00000000cc777777777777cc00000000cc999999999999cc00000000ccffffcc
-- 106:cfffeffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c46cc64ccccaaccc00000000cfffeffc005ccc0caacccc00cfffeffc00000000c11113333111311c00000000c77775555777577c00000000c9999bbbb999b99c00000000cfffeffc
-- 107:cffffefc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c6c44c6cca8228ac00000000cffffefc000000caaaac00c0cffffefc00000000c11111111111131c00000000c77777777777757c00000000c999999999999b9c00000000cffffefc
-- 108:cffffffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c687786cc6aaaa6c00000000cffffffc00000caaaaac0050cffffffc00000000c11111111111111c00000000c77777777777777c00000000c99999999999999c00000000cffffffc
-- 109:cffefffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc6666cc0c9aa9c000000000cffefffc0000ccaaaaaac000cffefffc00000000c11111111111111c00000000c77777777777777c00000000c99999999999999c00000000cffefffc
-- 110:ccffffcc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc66cc00b9999b000000000ccffffcc0000ca9aaaaac000ccffffcc00000000cc111111111111cc00000000cc777777777777cc00000000cc999999999999cc00000000ccffffcc
-- 111:ccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccc0000000000000000000cccccc00000c9a9aaaac0000cccccc0000000000cccccccccccccc0000000000cccccccccccccc0000000000cccccccccccccc0000000000ccccccc
-- 112:ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000cccccccc0000cccccc0000000000cccccccccccccc0000000000cccccccccccccc0000000000cccccccccccccc0000000000ccccccc
-- 113:ccffffcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc000000cc0ccc0000ccffffcc00000000cc111111111111cc00000000cc777777777777cc00000000cc999999999999cc00000000ccffffcc
-- 114:cfffeffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cfffeffc000000cc0cc00000cfffeffc00000000c11113333111311c00000000c77775555777577c00000000c9999bbbb999b99c00000000cfffeffc
-- 115:cffffefc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffffefc000000cc0cc00000cffffefc00000000c11111111111131c00000000c77777777777757c00000000c999999999999b9c00000000cffffefc
-- 116:cffffffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffffffc0000000c0c000000cffffffc00000000c11111111111111c00000000c77777777777777c00000000c99999999999999c00000000cffffffc
-- 117:cffefffc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cffefffc0000000c0c000000cffefffc00000000c11111111111111c00000000c77777777777777c00000000c99999999999999c00000000cffefffc
-- 118:ccffffcc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccffffcc0000cc0c0ccc0000ccffffcc00000000cc111111111111cc00000000cc777777777777cc00000000cc999999999999cc00000000ccffffcc
-- 119:ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc00000cccc0ccc00000cccccc0000000000cccccccccccccc0000000000cccccccccccccc0000000000cccccccccccccc0000000000ccccccc
-- 120:ccccccc000cccc000000000000000000000000000000000000000000c00cc00c000000000000000000000000000000000000000000000000000000000cccccc00cccccccccccccc00cccccc0000000000cccccccccccccc0000000000cccccccccccccc0000000000cccccccccccccc0000000000ccccccc
-- 121:ccffffcc0caaaac000000000000000000000000000000000000000000cc11cc000000000000000000000000000000000000000000000000000000000ccffffcccc999999999999ccccffffcc00000000cc111111111111cc00000000cc777777777777cc00000000cc999999999999cc00000000ccffffcc
-- 122:cfffeffccccaaccc0000000000000000000000000000000000000000cc1221cc00000000000000000000000000000000000000000000000000000000cfffeffcc9999bbbb999b99ccfffeffc00000000c11113333111311c00000000c77775555777577c00000000c9999bbbb999b99c00000000cfffeffc
-- 123:cffffefcca8228ac0000000000000000000000000000000000000000c122221c00000000000000000000000000000000000000000000000000000000cffffefcc999999999999b9ccffffefc00000000c11111111111131c00000000c77777777777757c00000000c999999999999b9c00000000cffffefc
-- 124:cffffffcc6aaaa6c0000000000000000000000000000000000000000c28cc82c00000000000000000000000000000000000000000000000000000000cffffffcc99999999999999ccffffffc00000000c11111111111111c00000000c77777777777777c00000000c99999999999999c00000000cffffffc
-- 125:cffefffc0c9aa9c00000000000000000000000000000000000000000c322223c00000000000000000000000000000000000000000000000000000000cffefffcc99999999999999ccffefffc00000000c11111111111111c00000000c77777777777777c00000000c99999999999999c00000000cffefffc
-- 126:ccffffcc0b9999b000000000000000000000000000000000000000000c2222c000000000000000000000000000000000000000000000000000000000ccffffcccc999999999999ccccffffcc00000000cc111111111111cc00000000cc777777777777cc00000000cc999999999999cc00000000ccffffcc
-- 127:ccccccc000000000000000000000000000000000000000000000000000cccc00000000000000000000000000000000000000000000000000000000000cccccc00cccccccccccccc00cccccc0000000000cccccccccccccc0000000000cccccccccccccc0000000000cccccccccccccc0000000000ccccccc
-- 128:ccccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccccccccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00ccccccc
-- 129:ccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffcc
-- 130:cfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffccfffeffc
-- 131:cffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefccffffefc
-- 132:cffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffccffffffc
-- 133:cffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffccffefffc
-- 134:ccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffccccffffcc
-- 135:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- </SCREEN>

-- <PALETTE>
-- 000:2834485d275d993e53ef7d575d4048ffffe6ffd691a57579ffffff3b5dc924c2ff89eff71a1c2c9db0c2566c86333c57
-- </PALETTE>
