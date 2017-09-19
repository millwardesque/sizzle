g_state = nil

--
-- Encapsulates the ingame state
--
ingame_state = {
	scene = nil,
	main_camera = nil,
	player = nil,

	enter = function(self)
		self.scene = {}

		g_physics.init(g_physics)

		-- Make the camera
		self.main_camera = make_camera(0, 0, 128, 128, 0, 0)

		-- Make the player
		local player_height = 8
		local player_start_x = 1 * 128 / 4 -- @TODO Replace with per-level definition
		local player_start_y = 3 * 128 / 4 -- @TODO Replace with per-level definition
		self.player = make_player("player", player_start_x, player_start_y, 1, 2)
		add(self.scene, self.player)
	end,

	update = function(self)
		-- Process input
		self.player.velocity = make_vec2(0, 0)
		if btn(0) then
			self.player.velocity.x -= self.player.walk_speed
		end

		if btn(1) then
			self.player.velocity.x += self.player.walk_speed
		end

		-- @DEBUG Reset the game
		if btn(4) then
			set_game_state(ingame_state)
			return
		end

		-- Update game objects
		for game_obj in all(self.scene) do
			if (game_obj.update) then
				game_obj.update(game_obj)
			end
		end

		-- @TODO Collision detection

		for o in all(self.scene) do
			g_log.log("scene: "..o.name)
		end
	end,

	draw = function(self)
		g_renderer.render()
	end,

	exit = function(self)
	end
}


--
-- Create a player
--
function make_player(name, start_x, start_y, sprite, walk_speed)
	local new_player = make_game_object(name, start_x, start_y)

	-- Physics
	new_player.velocity = make_vec2(0, 0)
	new_player.old_position = make_vec2(start_x, start_y)

	-- Animations
	local player_anims = {
		idle = { 1 },
		walk = { 2, 3 }
	}

	attach_anim_spr_controller(new_player, 4, player_anims, "idle", 0)

	-- Game stats
	new_player.walk_speed = walk_speed
	attach_renderable(new_player, sprite)
	new_player.renderable.draw_order = 1	-- Draw player after other in-game objects

	-- Update player
	new_player.update = function (self)
		self.update_physics(self)

		if self.velocity.x < 0 then
			self.renderable.flip_x = true
			set_anim_spr_animation(self.anim_controller, 'walk')
		elseif self.velocity.x > 0 then
			self.renderable.flip_x = false
			set_anim_spr_animation(self.anim_controller, 'walk')
		elseif self.velocity.x == 0 then
			self.renderable.flip_x = false
			set_anim_spr_animation(self.anim_controller, 'idle')
		end

		update_anim_spr_controller(self.anim_controller, self)
	end

	-- Updates player physics
	new_player.update_physics = function(self)
		self.old_position = self.position
		self.velocity += g_physics.gravity
		self.position += self.velocity

		self.check_for_collisions(self, 1)
	end

	-- Checks for collisions with the player
	new_player.check_for_collisions = function(self, iteration)
		-- @TODO Get a list of sprites the player is overlapping 
		-- @TODO For each sprite with collision flag:
		-- @TODO	If player overlaps this sprite, back off along inverted velocity vector
		-- @TOOD        Restart algorithm
	end

	return new_player
end

--
-- Sets the active game state
--
function set_game_state(game_state)
	if g_state ~= nil and g_state.exit then
		g_state.exit(g_state)
	end

	g_state = game_state

	if g_state ~= nil and g_state.enter then
		g_state.enter(g_state)
	end
end

-- 
-- Game Object
--
function make_game_object(name, pos_x, pos_y)
	local game_obj = {
		position = make_vec2(pos_x, pos_y),
		name = name
	}
	return game_obj
end

--
-- Renderable maker.
--
function attach_renderable(game_obj, sprite)
	local renderable = {
		game_obj = game_obj,
		sprite = sprite,
		flip_x = false,
		flip_y = false,
		sprite_width = 1,
		sprite_height = 1,
		draw_order = 0,
		palette = nil
	}

	-- Default rendering function
	renderable.render = function(self, position)

		-- Set the palette
		if (self.palette) then
			-- Set colours
			for i = 0, 15 do
				pal(i, self.palette[i + 1])
			end

			-- Set transparencies
			for i = 17, #self.palette do
				palt(self.palette[i], true)
			end
		end

		-- Draw
		spr(self.sprite, position.x, position.y, self.sprite_width, self.sprite_height, self.flip_x, self.flip_y)

		-- Reset the palette
		if (self.palette) then
			pal()
			palt()
		end
	end

	-- Save the default render function in case the object wants to use it in an overridden render function.
	renderable.default_render = renderable.render

	game_obj.renderable = renderable;
	return game_obj;
end

--
-- Renderer subsystem
--
g_renderer = {}

--
-- Main render pipeline
--
g_renderer.render = function()
	-- Collect renderables 
	local renderables = {};
	for game_obj in all(g_state.scene) do
		if (game_obj.renderable) then
			add(renderables, game_obj)
		end
	end

	-- Sort by draw-order
	quicksort_draw_order(renderables)

	-- Draw the scene
	camera_draw_start(g_state.main_camera)
	
	map(0, 0, 0, 0, 128, 128) -- draw the whole map and let the clipping region remove unnecessary bits

	for game_obj in all(renderables) do
		game_obj.renderable.render(game_obj.renderable, game_obj.position)
	end

	camera_draw_end(g_state.main_camera)
end

--
-- Sort a renderable array by draw-order
-- 
function quicksort_draw_order(list)
	quicksort_draw_order_helper(list, 1, #list)
end

--
-- Helper function for sorting renderables by draw-order
function quicksort_draw_order_helper(list, low, high)
	if (low < high) then
		local p = quicksort_draw_order_partition(list, low, high)
		quicksort_draw_order_helper(list, low, p - 1)
		quicksort_draw_order_helper(list, p + 1, high)
	end
end

--
-- Partition a renderable list by draw_order
--
function quicksort_draw_order_partition(list, low, high)
	local pivot = list[high]
	local i = low - 1
	local temp
	for j = low, high - 1 do
		if (list[j].renderable.draw_order < pivot.renderable.draw_order) then
			i += 1
			temp = list[j]
			list[j] = list[i]
			list[i] = temp
 		end
	end

	if (list[high].renderable.draw_order < list[i + 1].renderable.draw_order) then
		temp = list[high]
		list[high] = list[i + 1]
		list[i + 1] = temp
	end

	return i + 1
end

--
-- Camera
--
function make_camera(draw_x, draw_y, draw_width, draw_height, shoot_x, shoot_y)
	local t = {
 		draw_pos = make_vec2(draw_x, draw_y),
 		draw_width = draw_width,
 		draw_height = draw_height,
 		shoot_pos = make_vec2(shoot_x, shoot_y),
 	}
	return t
end

function camera_draw_start(cam)
	local draw_x = cam.draw_pos.x
	local draw_y = cam.draw_pos.y

	local cam_x = cam.shoot_pos.x - draw_x
	local cam_y = cam.shoot_pos.y - draw_y

	camera(cam_x, cam_y)
	clip(draw_x, draw_y, cam.draw_width, cam.draw_height)
end

function camera_draw_end(cam)
	camera()
	clip()
end

--
-- Animated sprite controller
--
function attach_anim_spr_controller(game_obj, frames_per_cell, animations, start_anim, start_frame_offset)
	game_obj.anim_controller = {
		current_animation = start_anim,
		current_cell = 1,
		frames_per_cell = frames_per_cell,
		current_frame = 1 + start_frame_offset,
		animations = animations,
		flip_x = false,
		flip_y = false,
	}
	return game_obj
end

function update_anim_spr_controller(controller, game_obj)
	controller.current_frame += 1
	if (controller.current_frame > controller.frames_per_cell) then
		controller.current_frame = 1

		if (controller.current_animation != nil and controller.current_cell != nil) then
			controller.current_cell += 1
			if (controller.current_cell > #controller.animations[controller.current_animation]) then
				controller.current_cell = 1
			end
		end
	end

	if (game_obj.renderable and controller.current_animation != nil and controller.current_cell != nil) then
		game_obj.renderable.sprite = controller.animations[controller.current_animation][controller.current_cell]
	elseif (game_obj.renderable) then
		game_obj.renderable.sprite = nil
	end
end

function set_anim_spr_animation(controller, animation)
	if controller.current_animation != animation then
		controller.current_frame = 0
		controller.current_cell = 1
		controller.current_animation = animation
	end
end

--
-- Physics
--
g_physics = {
	gravity = nil,
}

g_physics.init = function(self)
	self.gravity = make_vec2(0, 2)
end


--
-- 2d Vector
--
local vec2_meta = {}
function vec2_meta.__add(a, b)
	return make_vec2(a.x + b.x, a.y + b.y)
end

function vec2_meta.__sub(a, b)
	return make_vec2(a.x - b.x, a.y - b.y)
end

function vec2_meta.__mul(a, b)
	if type(a) == "number" then
		return make_vec2(a * b.x, a * b.y)
	elseif type(b) == "number" then
		return make_vec2(b * a.x, b * a.y)
	else
		return make_vec2(a.x * b.x, a.y * b.y)
	end
end

function vec2_meta.__div(a, b) 
	make_vec2(a.x / b, a.y / b)
end

function vec2_meta.__eq(a, b) 
	return a.x == b.x and a.y == b.y
end

function make_vec2(x, y) 
	local table = {
		x = x,
		y = y,
	}
	setmetatable(table, vec2_meta)
	return table;
end

function vec2_magnitude(v)
	return sqrt(v.x ^ 2 + v.y ^ 2)
end

function vec2_normalized(v) 
	local mag = vec2_magnitude(v)
	return make_vec2(v.x / mag, v.y / mag)
end

function vec2_str(v)
	return "("..v.x..", "..v.y..")"
end

--
-- Logger
--
g_log = {
	show_debug = false,
	log_data = {}
}

--
-- Logs a message
--
g_log.log = function(message)
	add(g_log.log_data, message)
end

--
-- Renders the log
--
g_log.render = function()
	if (g_log.show_debug) then
		color(7)
		for i = 1, #g_log.log_data do
			print(g_log.log_data[i])
		end
	end
end

--
-- Clears the log
--
g_log.clear = function()
	g_log.log_data = {}
end

--
-- Global init function.
--
function _init()
	set_game_state(ingame_state)
end

--
-- Global update function
--
function _update()
	if g_state ~= nil then
		g_state.update(g_state)
	end
	
	g_log.log("CPU: "..stat(1))
end

--
-- Global draw function
--
function _draw()
	cls()

	if g_state ~= nil then
		g_state.draw(g_state)
	end

	-- Draw debug log
	g_log.render()
	g_log.clear()
end