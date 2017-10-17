g_state = nil

g_corners = {
	top_left = 1,
	top_right = 2,
	bottom_right = 3,
	bottom_left = 4,
}

g_flags = {
	normal = 0,
	instakill = 1,
	level_exit = 2,
	indestructible = 3,
}

g_levels = {
	{
		cell_x = 0,
		cell_y = 0,
		width = 16,
		height = 16,
		player_start_x = 1 * 128 / 4,
		player_start_y = 3 * 128 / 4,
	},
	{
		cell_x = 16,
		cell_y = 0,
		width = 8,
		height = 16,
		player_start_x = (16 * 8) + 8,
		player_start_y = 3 * 128 / 4,
	},
	{
		cell_x = 24,
		cell_y = 0,
		width = 16,
		height = 16,
		player_start_x = (24 * 8) + 8,
		player_start_y = 3 * 128 / 4,
	},
}

g_game = nil

--
-- Encapsulates the ingame state
-- @TODO Merge down into g_game manager
--
ingame_state = {
	scene = nil,
	main_camera = nil,
	player = nil,
	tile_manager = nil,
	game_timer = 0,

	enter = function(self)
		self.scene = {}

		-- Retrieve the player
		self.player = g_game.player
		add(self.scene, self.player)

		-- Retrieve the tile manager
		self.tile_manager = g_game.tile_manager
		add(self.scene, self.tile_manager)
		for tile in all(self.tile_manager.active_tiles) do
			add(self.scene, tile)
		end

		-- Retrieve the camera
		self.main_camera = g_game.main_camera
		add(self.scene, self.main_camera)
		self.main_camera.follow_cam.target = self.player

		self.game_timer = 0
	end,

	update = function(self)
		self.game_timer += 1

		-- Process input
		self.player.velocity = make_vec2(0, 0)
		if not self.player.is_dead then
			if btn(0) then
				self.player.velocity.x -= self.player.walk_speed
			end

			if btn(1) then
				self.player.velocity.x += self.player.walk_speed
			end

			if btn(4) and not self.player.is_jumping and not self.player.is_jump_held then
				self.player.jump(self.player)
			elseif not btn(4) and self.player.is_jumping then
				self.player.stop_jump(self.player)
			end

			if not btn(4) then
				self.player.is_jump_held = false
			end
		end 

		-- @DEBUG Reload the level
		if btnp(5) then
			g_game.reload_level(g_game)
			return
		end

		-- Update game objects
		for game_obj in all(self.scene) do
			if (game_obj.update) then
				game_obj.update(game_obj)
			end
		end
	end,

	draw = function(self)
		g_renderer.render()

		print("time: "..flr(self.game_timer / 30))
	end,

	exit = function(self)
	end,
}

gameover_state = {
	enter = function(self)
	end,

	update = function(self)
		if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
			g_game.reload_level(g_game)
		end
	end,

	draw = function(self)
		-- Draw game-over window
		camera()
		clip()

		rectfill(12, 30, 116, 86, 6)
		rectfill(14, 32, 114, 84, 3)
		color(7)

		local line_height = 10
		local print_y = 40
		print("game over!", 46, print_y)
		print_y += line_height
		print("press any key to restart", 16, print_y)
	end,

	exit = function(self)
	end,
}

level_end_state = {
	enter = function(self)
	end,

	update = function(self)
		if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
			g_game.load_next_level(g_game)
		end
	end,

	draw = function(self)
		-- Draw game-over window
		camera()
		clip()

		rectfill(12, 30, 116, 86, 6)
		rectfill(14, 32, 114, 84, 3)
		color(7)

		local line_height = 10
		local print_y = 40
		print("level complete!", 36, print_y)
		print_y += line_height
		print("press any key", 38, print_y)
	end,

	exit = function(self)
	end,
}

main_menu_state = {
	enter = function(self)
	end,

	update = function(self)
		if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
			g_game.load_next_level(g_game)
		end
	end,

	draw = function(self)
		-- Draw game-over window
		camera()
		clip()

		rectfill(12, 30, 116, 86, 6)
		rectfill(14, 32, 114, 84, 3)
		color(7)

		local line_height = 10
		local print_y = 40
		print("sizzle!", 52, print_y)
		print_y += line_height
		print("press any key to play", 22, print_y)
	end,

	exit = function(self)
	end,
}

--
-- Create a player
--
function make_player(name, start_x, start_y, sprite, walk_speed, jump_power, jump_duration)
	local new_player = make_game_object(name, start_x, start_y)

	-- Physics
	new_player.velocity = make_vec2(0, 0)
	new_player.old_position = make_vec2(start_x, start_y)
	new_player.jump_power = jump_power
	new_player.is_jumping = false
	new_player.jump_elapsed = 0
	new_player.jump_duration = jump_duration
	new_player.jump_count = 0
	new_player.is_on_ground = false
	new_player.is_jump_held = false
	new_player.is_dead = false
	new_player.death_explosion = nil

	-- Animations
	local player_anims = {
		idle = { 1, },
		walk = { 2, 3 },
		jump = { 4 },
		fall = { 4, 5 },
		dead = { 0 },
	}

	attach_anim_spr_controller(new_player, 4, player_anims, "idle", 0)

	-- Game stats
	new_player.walk_speed = walk_speed
	attach_renderable(new_player, sprite)
	new_player.renderable.draw_order = 1	-- Draw player after other in-game objects

	new_player.init = function(self)
		self.velocity = make_vec2(0, 0)
		self.old_position = clone_vec2(self.position)
		self.is_jumping = false
		self.jump_elapsed = 0
		self.jump_count = 0
		self.is_on_ground = false
		self.is_jump_held = false
		self.is_dead = false

		if self.death_explosion then
			del(g_state.scene, self.death_explosion)
		end
		self.death_explosion = nil
	end

	new_player.jump = function(self)
		if (not self.is_jumping and self.is_on_ground) or (not self.is_on_ground and self.jump_count < 2) then
			self.is_jumping = true
			self.jump_elapsed = 0
			self.is_jump_held = true
			self.jump_count += 1
			set_anim_spr_animation(self.anim_controller, 'jump')
		end
	end

	new_player.stop_jump = function(self)
		self.is_jumping = false
		self.jump_elapsed = 0
	end

	-- Update player
	new_player.update = function (self)
		if self.is_dead then
			if self.death_explosion.is_dead(self.death_explosion) then
				set_game_state(gameover_state)
			end
		else
			if (self.is_jumping) then
				if self.jump_elapsed < self.jump_duration then
					new_player.velocity += g_physics.gravity * -self.jump_power
					self.jump_elapsed += 1
				else
					self.stop_jump(self)
				end
			end

			self.update_physics(self)

			if not self.is_dead then
				if (not self.is_on_ground) then
					if self.velocity.x < 0 then
						self.renderable.flip_x = true
						set_anim_spr_animation(self.anim_controller, 'fall')
					elseif self.velocity.x >= 0 then
						self.renderable.flip_x = false
						set_anim_spr_animation(self.anim_controller, 'fall')
					end
				else
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
				end
			end
		end

		update_anim_spr_controller(self.anim_controller, self)
	end

	-- Updates player physics
	new_player.update_physics = function(self)
		self.velocity += g_physics.gravity

		self.old_position = clone_vec2(self.position)
		self.position += self.velocity

		local collisions = self.check_for_collisions(self, {}, 1)
		self.is_on_ground = false
		for col in all(collisions) do
			local tile = g_state.tile_manager.get_tile_at_cell(g_state.tile_manager, col.cell.x, col.cell.y)
			g_log.log(tile_str(tile))

			if tile.type == g_flags.normal then
				tile.state = "warmup"
			elseif tile.type == g_flags.instakill then
				self.kill(self)
				break
			elseif tile.type == g_flags.level_exit then
				set_game_state(level_end_state)
				break
			end

			if col.is_ground_collision and tile.type ~= g_flags.instakill then
				self.is_on_ground = true
				self.jump_count = 0
				if self.is_jumping then
					self.stop_jump(self)
				end
			end
		end
	end

	new_player.kill = function(self)
		local explosion_duration = 30 * 1.5
		local explosion_particles = 50
		local explosion_speed = 1
		self.death_explosion = make_particle_system("player-death", self.position, 7, { 7, 7, 8, 9, 10, 11, 11 }, explosion_duration, explosion_particles, explosion_speed)
		add(g_state.scene, self.death_explosion)
		set_anim_spr_animation(self.anim_controller, 'dead')
		self.is_dead = true
	end

	-- Checks for collisions with the player
	new_player.check_for_collisions = function(self, collisions, iteration)
		local max_iterations = 3
		if iteration > max_iterations then 
			return collisions
		end

		local direction = vec2_normalized(self.velocity)

		-- Check if left foot is on ground
		local old_left_foot = self.old_position + make_vec2(8 * 0.33, 7)
		local left_foot = self.position + make_vec2(8 * 0.33, 7)
		local left_foot_intersection = check_swept_collision(old_left_foot, left_foot)

		-- Check if right foot is on ground
		local old_right_foot = self.old_position + make_vec2(8 * 0.66, 7)
		local right_foot = self.position + make_vec2(8 * 0.66, 7)
		local right_foot_intersection = check_swept_collision(old_right_foot, right_foot)

		-- Adjust position to account for the collision
		if left_foot_intersection ~= nil then
			if self.position.y > left_foot_intersection.position.y - 8 then
				self.position.y = left_foot_intersection.position.y - 8
				left_foot_intersection.is_ground_collision = true
				add(collisions, left_foot_intersection)
				return self.check_for_collisions(self, collisions, iteration + 1)
			end
		elseif right_foot_intersection ~= nil then
			if self.position.y > right_foot_intersection.position.y - 8 then
				self.position.y = right_foot_intersection.position.y - 8
				right_foot_intersection.is_ground_collision = true
				add(collisions, right_foot_intersection)
				return self.check_for_collisions(self, collisions, iteration + 1)
			end
		end

		-- Check if left side of head hit the ceiling
		local old_left_head = self.old_position + make_vec2(8 * 0.33, 0)
		local left_head = self.position + make_vec2(8 * 0.33, 0)
		local left_head_intersection = check_swept_collision(old_left_head, left_head)

		-- Check if right side of head hit the ceiling
		local old_right_head = self.old_position + make_vec2(8 * 0.66, 0)
		local right_head = self.position + make_vec2(8 * 0.66, 0)
		local right_head_intersection = check_swept_collision(old_right_head, right_head)

		-- Adjust position to account for the collision
		if left_head_intersection ~= nil then
			if self.position.y < left_head_intersection.position.y + 8 then
				self.position.y = left_head_intersection.position.y + 8
				add(collisions, left_head_intersection)
				return self.check_for_collisions(self, collisions, iteration + 1)
			end
		elseif right_head_intersection ~= nil then
			if self.position.y < right_head_intersection.position.y + 8 then
				self.position.y = right_head_intersection.position.y + 8
				add(collisions, right_head_intersection)
				return self.check_for_collisions(self, collisions, iteration + 1)
			end
		end

		-- Check if the left side of the head is against tile
		local old_left_hand = clone_vec2(self.old_position)
		local left_hand = clone_vec2(self.position + make_vec2(0, 8 * 0.5))
		local left_hand_intersection = check_swept_collision(old_left_hand, left_hand)

		-- Adjust position to account for the collision
		if left_hand_intersection ~= nil then
			if self.position.x < left_hand_intersection.position.x + 8 then
				self.position.x = left_hand_intersection.position.x + 8
				add(collisions, left_hand_intersection)
				return self.check_for_collisions(self, collisions, iteration + 1)
			end
		end

		-- Check if the right side of the head is against tile
		local old_right_hand = self.old_position + make_vec2(7, 0)
		local right_hand = clone_vec2(self.position) + make_vec2(7, 8 * 0.5)
		local right_hand_intersection = check_swept_collision(old_right_hand, right_hand)

		-- Adjust position to account for the collision
		if right_hand_intersection ~= nil then
			if self.position.x > right_hand_intersection.position.x - 8 then
				self.position.x = right_hand_intersection.position.x - 8
				add(collisions, right_hand_intersection)
				return self.check_for_collisions(self, collisions, iteration + 1)
			end
		end

		return collisions
	end

	return new_player
end

-- 
-- Check for collisions between a dynamic position and a the tilemap using a sweeping algorithm
--
function check_swept_collision(old_position, new_position)
	local direction = vec2_normalized(new_position - old_position)
	local attempted_magnitude = vec2_magnitude(new_position - old_position)
	local sweeper = clone_vec2(old_position)
	while (intersection == nil and (vec2_magnitude(sweeper - old_position) < attempted_magnitude)) do
		local tile = g_state.tile_manager.get_map_tile_at_position(g_state.tile_manager, sweeper)
		if tile ~= nil then
			-- g_log.log("s: "..vec2_str(sweeper).." tc: "..vec2_str(tile.cell))
			if tile.type ~= nil then
				-- g_log.log("COLLISION")
			 	return tile
			end
		end
		sweeper += clone_vec2(direction)
	end

	return nil
end


--
-- Creates a timer for a single tile
--
function make_tile(name, type, cell_x, cell_y, max_duration, cooldown_rate, warmup_rate)
	local t = make_game_object(name, 0, 0)
	t.state = 'idle'
	t.elapsed = 0
	t.max_duration = max_duration
	t.cooldown_rate = cooldown_rate
	t.warmup_rate = warmup_rate
	t.cell_x = cell_x
	t.cell_y = cell_y
	t.type = type
	
	if t.type == g_flags.normal then
		t.sprites = {16, 17, 18}
	elseif t.type == g_flags.instakill then
		t.sprites = { 32 }
	elseif t.type == g_flags.level_exit then
		t.sprites = { 19 }
	elseif t.type == g_flags.indestructible then
		t.sprites = { 20 }
	end

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
			if self.elapsed / self.max_duration < 0.2 then
				mset(self.cell_x, self.cell_y, self.sprites[1])
			elseif self.elapsed / self.max_duration > 0.6 then
				mset(self.cell_x, self.cell_y, self.sprites[3])
			elseif self.elapsed / self.max_duration <= 0.6 then
				mset(self.cell_x, self.cell_y, self.sprites[2])
			end
		end

	end

	t.reset = function(self)
		if self.type == g_flags.normal then
			mset(self.cell_x, self.cell_y, self.sprites[1])
			self.state = 'idle'
			self.elapsed = 0
		end
	end

	return t
end

function tile_str(tile)
	return tile.name.." ("..tile.type.."): s="..tile.state.." e="..tile.elapsed.."/"..tile.max_duration
end

--
-- Creates a manager for a grid of tiles
function make_tile_manager(start_x, start_y, width, height)
	local tile_manager = make_game_object("tile manager", start_x, start_y)
	tile_manager.tiles = {}
	tile_manager.start_x = start_x
	tile_manager.start_y = start_y
	tile_manager.width = width
	tile_manager.height = height
	tile_manager.tile_timer_duration = 60
	tile_manager.cooldown_rate = 0.5
	tile_manager.warmup_rate = 3
	tile_manager.active_tiles = {}

	tile_manager.init = function(self) 
		-- Reset any modified tiles from a previous session
		self.reset(self)

		-- Populate the tiles for collidable tiles
		self.tiles = {}
		self.active_tiles = {}

		for x = 0, self.width - 1 do
			add(self.tiles, {})
			local cell_x = x + self.start_x
			for y = 0, self.height - 1 do
				local cell_y = y + self.start_y
				if is_cell_collidable(cell_x, cell_y) then
					local tiletype = get_tile_type(mget(cell_x, cell_y))
					add(self.tiles[x + 1], make_tile("tile-"..cell_x.."-"..cell_y, tiletype, cell_x, cell_y, self.tile_timer_duration, self.cooldown_rate, self.warmup_rate))
					add(self.active_tiles, self.tiles[x + 1][y + 1])
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
			end
		end
	end

	tile_manager.reset = function(self)
		g_log.syslog("Resetting tile manager")
		for x = 1, self.width do
			if self.tiles[x] ~= nil then
				for y = 1, self.height do
					if self.tiles[x][y] ~= 0 then
						self.tiles[x][y].reset(self.tiles[x][y])
					end
				end
			end
		end
	end

	tile_manager.get_tile_at_cell = function(self, x, y)
		-- @DEBUG g_log.syslog("p: ("..x..", "..y..") vs. ("..(1 + x - self.start_x)..", "..(1 + y - self.start_y)..")")
		return self.tiles[1 + x - self.start_x][1 + y - self.start_y]
	end

	tile_manager.get_map_tile_at_position = function(self, position)
		local tile = get_map_tile_at_position(position)
		if tile ~= nil then
			if (tile.cell.x >= self.start_x and tile.cell.x < self.start_x + self.width and
				tile.cell.y >= self.start_y and tile.cell.y < self.start_y + self.height) then
				return tile
			else
				return nil
			end
		else
			return nil
		end
	end

	return tile_manager
end

--
-- Gets the map tile at a pixel position
--
function get_map_tile_at_position(position)
	if position.x < 0 or position.y < 0 then
		return nil
	end

	local cell = position_to_cell(position)
	local sprite = mget(cell.x, cell.y)
	local tiletype = get_tile_type(sprite)
	return { type = tiletype, sprite = sprite, cell = cell, position = cell_to_position(cell.x, cell.y) }
end

function is_cell_collidable(cell_x, cell_y)
	return get_tile_type(mget(cell_x, cell_y)) ~= nil
end

function get_tile_type(sprite)
	if fget(sprite, g_flags.normal) then
		return g_flags.normal
	elseif fget(sprite, g_flags.instakill) then
		return g_flags.instakill
	elseif fget(sprite, g_flags.level_exit) then
		return g_flags.level_exit
	elseif fget(sprite, g_flags.indestructible) then
		return g_flags.indestructible
	else
		return nil
	end
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
-- Makes a game manager
--
function make_game(levels)
	g = {
		levels = levels,
		active_level = nil,
		player = nil,
		main_camera = nil,
		tile_manager = nil,
		scene = {}
	}

	g.init = function(self)
		local player_height = 8
		local player_start_x = 0
		local player_start_y = 0
		local player_sprite = 1
		local player_speed = 2
		local player_jump_power = 2.25
		local player_jump_duration = 7
		self.player = make_player("player", player_start_x, player_start_y, player_sprite, player_speed, player_jump_power, player_jump_duration)
	end

	g.load_level = function(self, level_index)
		if level_index < 1 or level_index > #self.levels then
			return
		end

		new_level = self.levels[level_index]
		self.player.position = make_vec2(new_level.player_start_x, new_level.player_start_y)
		self.player.init(self.player)
		self.active_level = level_index

		self.main_camera = make_camera("main", 0, 0, 0, 0, 128, 128)
		attach_follow_camera(self.main_camera, 48, 32, nil)

		g_physics.init(g_physics, make_vec2(0, 2.75))

		-- Create the tiles
		if self.tile_manager ~= nil then
			self.tile_manager.reset(self.tile_manager)
		end

		self.tile_manager = make_tile_manager(new_level.cell_x, new_level.cell_y, new_level.width, new_level.height)
		self.tile_manager.init(self.tile_manager)

		set_game_state(ingame_state)
	end

	g.load_next_level = function(self)
		if self.active_level == nil then
			self.load_level(self, 1)
		elseif self.active_level == #self.levels then
			self.load_level(self, 1)
		else
			self.load_level(self, self.active_level + 1)
		end
	end

	g.reload_level = function(self)
		if self.active_level == nil then
			self.load_level(self, 1)
		else
			self.load_level(self, self.active_level)
		end
	end

	g.get_active_level = function(self)
		if self.active_level == nil then
			return nil
		else
			return self.levels[self.active_level]
		end
	end

	return g
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
-- Particle system.
--
function make_particle_system(name, position, sprite, animation, lifespan, particle_count, particle_speed)
	local game_obj = make_game_object(name, position.x, position.y)
	attach_renderable(game_obj, sprite)

	local anims = {
		explode = animation,
	}
	attach_anim_spr_controller(game_obj, 8, anims, "explode", 0)

	game_obj.particle_system = {
		particles = {},
		speed = speed,
		lifespan = lifespan,
	}

	for i = 1, particle_count do
		add(game_obj.particle_system.particles, {
			position = make_vec2(0, 0),
			velocity = vec2_normalized(make_vec2(rnd() - 0.5, rnd() - 0.5)) * particle_speed,
		})
	end

	game_obj.is_dead = function(self)
		return self.particle_system.lifespan <= 0
	end

	game_obj.update = function(self)
		if self.particle_system.lifespan > 0 then
			for p in all(self.particle_system.particles) do
				p.position += p.velocity
			end

			update_anim_spr_controller(self.anim_controller, self)

			self.particle_system.lifespan -= 1
		end
	end

	game_obj.renderable.render = function(self, position)
		if self.game_obj.particle_system.lifespan > 0 then
			for p in all(self.game_obj.particle_system.particles) do
				self.default_render(self, position + p.position)
			end
		end
	end

	return game_obj
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
function make_camera(name, pos_x, pos_y, draw_x, draw_y, draw_width, draw_height)
	local new_cam = make_game_object(name, pos_x, pos_y)
	new_cam.cam = {
		draw_pos = make_vec2(draw_x, draw_y),
		draw_width = draw_width,
		draw_height = draw_height,
	}	
	
	return new_cam
end

function camera_draw_start(cam)
	local draw_x = cam.cam.draw_pos.x
	local draw_y = cam.cam.draw_pos.y

	local cam_x = cam.position.x - draw_x
	local cam_y = cam.position.y - draw_y

	camera(cam_x, cam_y)
	clip(draw_x, draw_y, cam.cam.draw_width, cam.cam.draw_height)
end

function camera_draw_end(cam)
	camera()
	clip()
end

--
-- Camera that can follow a target
--
function attach_follow_camera(cam, bounds_width, bounds_height, target)
	cam.follow_cam = {
		bounds_width = bounds_width,
		bounds_height = bounds_height,
		target = target
	}

	cam.update = function(self)
		if self.follow_cam.target ~= nil then
			-- @TODO Apply to center of screen, not left edge.
			
			local follow = self.follow_cam
			local target = follow.target
			
			local left_bound = self.position.x + flr(self.cam.draw_width / 2) - flr(follow.bounds_width / 2)
			local right_bound = self.position.x + flr(self.cam.draw_width / 2) + flr(follow.bounds_width / 2)
			if target.position.x < left_bound then
				self.position.x -= left_bound - target.position.x
			elseif target.position.x + 8 > right_bound then
				self.position.x += target.position.x + 8 - right_bound
			end

			local top_bound = self.position.y + flr(self.cam.draw_height / 2) - flr(follow.bounds_height / 2)
			local bottom_bound = self.position.y + flr(self.cam.draw_height / 2) + flr(follow.bounds_height / 2)
			if target.position.y < top_bound then
				self.position.y -= top_bound - target.position.y
			elseif target.position.y + 8 > bottom_bound then
				self.position.y += target.position.y + 8 - bottom_bound
			end
		end 
	end
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

g_physics.init = function(self, gravity)
	self.gravity = gravity
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
	show_debug = false,
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
			print(g_log.log_data[i], 0, 5 + 5 * i)
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
	g_game = make_game(g_levels)
	g_game.init(g_game)

	set_game_state(main_menu_state)
end

--
-- Global update function
--
function _update()
	if g_state ~= nil then
		g_state.update(g_state)
	end
	
	g_log.log("Mem: "..stat(0))
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