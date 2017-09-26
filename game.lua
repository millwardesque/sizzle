g_state = nil

g_corners = {
	top_left = 1,
	top_right = 2,
	bottom_right = 3,
	bottom_left = 4,
}

--
-- Encapsulates the ingame state
--
ingame_state = {
	scene = nil,
	main_camera = nil,
	player = nil,
	tile_manager = nil,
	game_timer = 0,

	enter = function(self)
		self.scene = {}

		g_physics.init(g_physics)

		-- Create the tiles
		self.tile_manager = make_tile_manager(128, 128)
		self.tile_manager.init(self.tile_manager)
		add(self.scene, self.tile_manager)

		-- Make the camera
		self.main_camera = make_camera(0, 0, 128, 128, 0, 0)

		-- Make the player
		local player_height = 8
		local player_start_x = 2 * 128 / 4 -- @TODO Replace with per-level definition
		local player_start_y = 1 * 128 / 4 -- @TODO Replace with per-level definition
		local player_sprite = 1
		local player_speed = 2
		self.player = make_player("player", player_start_x, player_start_y, player_sprite, player_speed)
		add(self.scene, self.player)

		game_timer = 0
	end,

	update = function(self)
		self.game_timer += 1

		-- Process input
		self.player.velocity = make_vec2(0, 0)
		if btn(0) then
			self.player.velocity.x -= self.player.walk_speed
		end

		if btn(1) then
			self.player.velocity.x += self.player.walk_speed
		end

		-- @DEBUG
		if btn(2) then
			self.player.velocity.y -= self.player.walk_speed
		end

		if btn(3) then
			self.player.velocity.y += self.player.walk_speed
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
	end,

	draw = function(self)
		g_renderer.render()

		print("time: "..flr(self.game_timer / 30))
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

		-- @DEBUG g_log.log("player: "..vec2_str(self.position))
	end

	-- Updates player physics
	new_player.update_physics = function(self)
		self.velocity += g_physics.gravity

		self.old_position = clone_vec2(self.position)
		self.position += self.velocity

		local collisions = self.check_for_collisions(self, {}, 1)
		for col in all(collisions) do
			local tile = g_state.tile_manager.tiles[col.cell.x + 1][col.cell.y + 1]
			g_log.log(tile_str(tile))
			tile.state = "warmup"
		end
	end

	-- Checks for collisions with the player
	new_player.check_for_collisions = function(self, collisions, iteration)
		local max_iterations = 3
		if iteration > max_iterations then 
			return collisions
		end

		local direction = vec2_normalized(self.velocity)

		-- Check if left foot is on ground
		-- g_log.log(iteration..": LF")
		local old_left_foot = self.old_position + make_vec2(8 * 0.33, 7)
		local left_foot = self.position + make_vec2(8 * 0.33, 7)
		local left_foot_intersection = check_swept_collision(old_left_foot, left_foot)

		-- Check if right foot is on ground
		-- g_log.log(iteration..": RF")
		local old_right_foot = self.old_position + make_vec2(8 * 0.66, 7)
		local right_foot = self.position + make_vec2(8 * 0.66, 7)
		local right_foot_intersection = check_swept_collision(old_right_foot, right_foot)

		-- Adjust position to account for the collision
		if left_foot_intersection ~= nil then
			self.position.y = left_foot_intersection.position.y - 8
			add(collisions, left_foot_intersection)
			return self.check_for_collisions(self, collisions, iteration + 1)
		elseif right_foot_intersection ~= nil then
			self.position.y = right_foot_intersection.position.y - 8
			add(collisions, right_foot_intersection)
			return self.check_for_collisions(self, collisions, iteration + 1)
		end

		-- Check if the left side of the head is against tile
		-- g_log.log(iteration..": LH")
		local old_left_head = clone_vec2(self.old_position)
		local left_head = clone_vec2(self.position)
		local left_head_intersection = check_swept_collision(old_left_head, left_head)

		-- Adjust position to account for the collision
		if left_head_intersection ~= nil then
			self.position.x = left_head_intersection.position.x + 8
			add(collisions, left_head_intersection)
			return self.check_for_collisions(self, collisions, iteration + 1)
		end

		-- g_log.log(iteration..": RH")
		-- Check if the right side of the head is against tile
		local old_right_head = self.old_position + make_vec2(7, 0)
		local right_head = clone_vec2(self.position) + make_vec2(7, 0)
		local right_head_intersection = check_swept_collision(old_right_head, right_head)

		-- Adjust position to account for the collision
		if right_head_intersection ~= nil then
			self.position.x = right_head_intersection.position.x - 8
			add(collisions, right_head_intersection)
			return self.check_for_collisions(self, collisions, iteration + 1)
		end

		return collisions
	end

	return new_player
end

--
-- Creates a timer for a single tile
--
function make_tile(name, cell_x, cell_y, max_duration, cooldown_rate, warmup_rate)
	local t = make_game_object(name, 0, 0)
	t.state = 'idle'
	t.elapsed = 0
	t.max_duration = max_duration
	t.cooldown_rate = cooldown_rate
	t.warmup_rate = warmup_rate
	t.cell_x = cell_x
	t.cell_y = cell_y
	t.sprites = {16, 17, 18}

	t.update = function(self)
		elapsed_changed = false

		if self.state == 'idle' then
			-- Do nothing.
		elseif self.state == 'cooldown' then
			self.elapsed -= self.cooldown_rate

			if self.elapsed <= 0 then
				self.elapsed = 0
				self.state = 'idle'
			end

			elapsed_changed = true
		elseif self.state == 'warmup' then
			self.elapsed += self.warmup_rate

			if self.elapsed >= self.max_duration then
				self.elapsed = self.max_duration
				self.state = 'destroyed'
			else
				self.state = 'cooldown'	-- This can be changed to warmup next frame if the tile is activated again
			end
			elapsed_changed = true
		elseif self.state == 'destroyed' then
			-- @TODO Destroy tile
		end

		if elapsed_changed then
			 if self.elapsed < 0.2 then
			 	mset(self.cell_x, self.cell_y, self.sprites[1])
			 elseif self.elapsed / self.max_duration > 0.6 then
			 	mset(self.cell_x, self.cell_y, self.sprites[3])
			 elseif self.elapsed / self.max_duration <= 0.6 then
			 	mset(self.cell_x, self.cell_y, self.sprites[2])
			 end
		end

	end

	return t
end

function tile_str(tile)
	return tile.name..": s= "..tile.state.." e= "..tile.elapsed.."/"..tile.max_duration
end

--
-- Creates a manager for a grid of tiles
function make_tile_manager(width, height)
	local tile_manager = make_game_object("tile manager", start_x, start_y)
	tile_manager.tiles = {}
	tile_manager.width = width
	tile_manager.height = height
	tile_manager.tile_timer_duration = 60
	tile_manager.cooldown_rate = 0.5
	tile_manager.warmup_rate = 1
	tile_manager.active_tiles = {}

	tile_manager.init = function(self) 
		-- Populate the tiles for collidable tiles
		self.tiles = {}
		self.active_tiles = {}

		for x = 0, self.width - 1 do
			add(self.tiles, {})
			for y = 0, self.height - 1 do
				if is_cell_collidable(x, y) then
					add(self.tiles[x + 1], make_tile("Tile-"..x.."-"..y, x, y, self.tile_timer_duration, self.cooldown_rate, self.warmup_rate))
					add(self.active_tiles, self.tiles[x + 1][y + 1])
					add(g_state.scene, self.tiles[x + 1][y + 1])
				else
					add(self.tiles[x + 1], 0) -- Can't add nil to a table for some reason.
				end
			end
		end
	end

	tile_manager.update = function(self)
		for tile in all(self.active_tiles) do
			if tile ~= 0 and tile.state == 'destroyed' then
				del(self.active_tiles, tile)
				del(g_state.scene, tile)
				mset(tile.cell_x, tile.cell_y, 0)
				self.tiles[tile.cell_x + 1][tile.cell_y + 1] = 0
			end
		end
	end

	return tile_manager
end

-- 
-- Check for collisions between a dynamic position and a the tilemap using a sweeping algorithm
--
function check_swept_collision(old_position, new_position)
	local direction = vec2_normalized(new_position - old_position)
	local attempted_magnitude = vec2_magnitude(new_position - old_position)
	local sweeper = clone_vec2(old_position)
	while (intersection == nil and (vec2_magnitude(sweeper - old_position) < attempted_magnitude)) do
		local tile = get_map_tile_at_position(sweeper)
		if tile ~= nil then
			-- g_log.log("s: "..vec2_str(sweeper).." tc: "..vec2_str(tile.cell))
			if fget(tile.sprite, 0) then
				-- g_log.log("COLLISION")
			 	return tile
			end
		end
		sweeper += clone_vec2(direction)
	end

	return nil
end

--
-- Gets the map tile at a pixel position
--
function get_map_tile_at_position(position)
	if position.x < 0 or position.y < 0 then
		return nil
	end

	local cell = position_to_cell(position)
	return { sprite = mget(cell.x, cell.y), cell = cell, position = cell_to_position(cell.x, cell.y) }
end

function is_cell_collidable(cell_x, cell_y)
	return fget(mget(cell_x, cell_y), 0)
end

--
-- Converts a worldspace position to map cell coords
--
function position_to_cell(position)
	local cell_x = flr(position.x / 8)
	local cell_y = flr(position.y / 8)

	return make_vec2(cell_x, cell_y)
end

--
-- Converts map cell coords to a worldspace position
--
function cell_to_position(x, y)
	local world_x = x * 8
	local world_y = y * 8

	return make_vec2(world_x, world_y)
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
	self.gravity = make_vec2(0, 4)
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

function clone_vec2(v) 
	return make_vec2(v.x, v.y)
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
	show_debug = true,
	log_data = {}
}

--
-- Logs a message
--
g_log.log = function(message)
	add(g_log.log_data, message)
end

g_log.syslog = function(message)
	printh(message, 'debug.log')
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