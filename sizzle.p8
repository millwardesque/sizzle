pico-8 cartridge // http://www.pico-8.com
version 14
__lua__
g_state = nil

g_flags = {
	normal = 0,
	instakill = 1,
	exit = 2,
	indestructible = 3,
}

g_levels = {
	{
		cell_x = 40,
		cell_y = 0,
		bg_x = 0,
		bg_y = 16,
		width = 32,
		height = 16,
		player_x = (40 * 8) + 8,
		player_y = 3 * 128 / 4,
		times = {
			{ time = 5, name = "cpm" },
			{ time = 8, name = "lsm" },
			{ time = 10, name = "zrm" },
			{ time = 15, name = "gdm" },
			{ time = 25, name = "elm" },
		}
	},
	{
		cell_x = 0,
		cell_y = 0,
		bg_x = 0,
		bg_y = 16,
		width = 16,
		height = 16,
		player_x = 1 * 128 / 4,
		player_y = 3 * 128 / 4,
		times = {
			{ time = 5, name = "cpm" },
			{ time = 8, name = "lsm" },
			{ time = 10, name = "zrm" },
			{ time = 15, name = "gdm" },
			{ time = 25, name = "elm" },
		}
	},
	{
		cell_x = 16,
		cell_y = 0,
		bg_x = 0,
		bg_y = 16,
		width = 8,
		height = 16,
		player_x = (16 * 8) + 8,
		player_y = 3 * 128 / 4,
		times = {
			{ time = 5, name = "cpm" },
			{ time = 8, name = "lsm" },
			{ time = 10, name = "zrm" },
			{ time = 15, name = "gdm" },
			{ time = 25, name = "elm" },
		}
	},
	{
		cell_x = 24,
		cell_y = 0,
		bg_x = 0,
		bg_y = 16,
		width = 16,
		height = 16,
		player_x = (24 * 8) + 8,
		player_y = 3 * 128 / 4,
		times = {
			{ time = 5, name = "cpm" },
			{ time = 8, name = "lsm" },
			{ time = 10, name = "zrm" },
			{ time = 15, name = "gdm" },
			{ time = 25, name = "elm" },
		}
	},
}

g_game = nil

--
-- encapsulates the ingame state
-- @todo merge down into g_game manager
--
ingame_state = {
	scene = nil,
	main_camera = nil,
	player = nil,
	tile_manager = nil,
	game_timer = 0,

	enter = function(self)
		self.scene = {}

		-- retrieve the player
		self.player = g_game.player
		add(self.scene, self.player)

		-- retrieve the tile manager
		self.tile_manager = g_game.tile_manager
		add(self.scene, self.tile_manager)
		for tile in all(self.tile_manager.active_tiles) do
			add(self.scene, tile)
		end

		-- retrieve the camera
		self.main_camera = g_game.main_camera
		add(self.scene, self.main_camera)
		self.main_camera.follow_cam.target = self.player

		g_game.game_timer = 0
	end,

	update = function(self)
		g_game.game_timer += 1

		-- process input
		self.player.vel = make_vec2(0, 0)
		if not self.player.is_dead then
			if btn(0) then
				self.player.vel.x -= self.player.walk_speed
			end

			if btn(1) then
				self.player.vel.x += self.player.walk_speed
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

		-- @debug reload the level
		if btnp(5) then
			g_game.reload_level(g_game)
			return
		end

		-- update game objects
		for game_obj in all(self.scene) do
			if (game_obj.update) then
				game_obj.update(game_obj)
			end
		end
	end,

	draw = function(self)
		g_renderer.render()

		print("time: "..flr(g_game.game_timer / 30))
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
		-- draw game-over window
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
		self.score_position = record_time(g_game.get_active_level(g_game), flr(g_game.game_timer / 30), "you")
	end,

	update = function(self)
		if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
			g_game.load_next_level(g_game)
		end
	end,

	draw = function(self)
		camera()
		clip()

		-- draw ui window
		rectfill(12, 30, 116, 114, 6)
		rectfill(14, 32, 114, 112, 3)
		color(7)

		local line_height = 8
		local print_y = 40
		print("level complete!", 36, print_y)
		print_y += line_height
		print("press any key", 38, print_y)
		print_y += line_height * 2

		-- @todo highlight player's latest score.
		print ("best times for level "..g_game.active_level, 20, print_y)
		print_y += line_height

		local position = 1
		for time in all(g_game.get_active_level(g_game).times) do
			if position == self.score_position then
				color(14)
			else
				color(7)
			end
			print (time.name..": "..time.time, 50, print_y)
			print_y += line_height
			position += 1
		end
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
		-- draw game-over window
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
-- create a player
--
function make_player(name, start_x, start_y, sprite, walk_speed, jump_power, jump_duration)
	local p = make_game_object(name, start_x, start_y)

	-- physics
	p.vel = make_vec2(0, 0)
	p.old_pos = make_vec2(start_x, start_y)
	p.jump_power = jump_power
	p.is_jumping = false
	p.jump_elapsed = 0
	p.jump_duration = jump_duration
	p.jump_count = 0
	p.is_on_ground = false
	p.is_jump_held = false
	p.is_dead = false
	p.death_explosion = nil

	-- animations
	local player_anims = {
		idle = { 1, },
		walk = { 2, 3 },
		jump = { 4 },
		wallslide = { 6 },
		fall = { 4, 5 },
		dead = { 7, 8, 9, 10, 11, 0 },
	}

	attach_anim_spr_controller(p, 4, player_anims, "idle", 0)

	-- game stats
	p.walk_speed = walk_speed
	attach_renderable(p, sprite)
	p.renderable.draw_order = 1	-- draw player after other in-game objects

	p.init = function(self)
		self.vel = make_vec2(0, 0)
		self.old_pos = clone_vec2(self.pos)
		self.is_jumping = false
		self.jump_elapsed = 0
		self.jump_count = 0
		self.is_on_ground = false
		self.is_jump_held = false
		self.is_dead = false
		self.anim_controller.loop = true

		if self.death_explosion then
			del(g_state.scene, self.death_explosion)
		end
		self.death_explosion = nil
	end

	p.jump = function(self)
		if (not self.is_jumping and self.is_on_ground) or (not self.is_on_ground and self.jump_count < 2) then
			self.is_jumping = true
			self.jump_elapsed = 0
			self.is_jump_held = true
			self.jump_count += 1
			set_anim_spr_animation(self.anim_controller, 'jump')
		end
	end

	p.stop_jump = function(self)
		self.is_jumping = false
		self.jump_elapsed = 0
	end

	p.wall_slide = function(self)
		self.is_wall_sliding = true
		self.jump_count = 0
		if self.is_jumping then
			self.stop_jump(self)
		end

		set_anim_spr_animation(self.anim_controller, 'wallslide')
	end

	p.stop_wall_slide = function(self)
		self.is_wall_sliding = false
	end

	-- update player
	p.update = function (self)
		if self.is_dead then
			if not self.death_explosion and not is_anim_spr_playing(self.anim_controller) then
				local explosion_duration = 30 * 1.5
				local explosion_particles = 50
				local explosion_speed = 1
				self.death_explosion = make_particle_system("player-death", self.pos, 7, { 7, 7, 8, 9, 10, 11, 11 }, explosion_duration, explosion_particles, explosion_speed)
				add(g_state.scene, self.death_explosion)
			end

			if self.death_explosion and self.death_explosion.is_dead(self.death_explosion) then
				set_game_state(gameover_state)
			end
		else
			if (self.is_jumping) then
				if self.jump_elapsed < self.jump_duration then
					p.vel += -1 * g_physics.gravity * self.jump_power
					self.jump_elapsed += 1
				else
					self.stop_jump(self)
				end
			elseif (self.is_wall_sliding) then
				p.vel += -1 * g_physics.gravity * 0.5
			end

			self.update_physics(self)

			if not self.is_dead then
				if (not self.is_on_ground) then
					if self.vel.x < 0 then
						self.renderable.flip_x = true
						set_anim_spr_animation(self.anim_controller, 'fall')
					elseif self.vel.x >= 0 then
						self.renderable.flip_x = false
						set_anim_spr_animation(self.anim_controller, 'fall')
					end
				else
					if self.vel.x < 0 then
						self.renderable.flip_x = true
						set_anim_spr_animation(self.anim_controller, 'walk')
					elseif self.vel.x > 0 then
						self.renderable.flip_x = false
						set_anim_spr_animation(self.anim_controller, 'walk')
					elseif self.vel.x == 0 then
						self.renderable.flip_x = false
						set_anim_spr_animation(self.anim_controller, 'idle')
					end
				end
			end
		end

		update_anim_spr_controller(self.anim_controller, self)
	end

	-- updates player physics
	p.update_physics = function(self)
		self.vel += g_physics.gravity

		self.old_pos = clone_vec2(self.pos)
		self.pos += self.vel

		local collisions = self.check_for_collisions(self, {}, 1)
		self.is_on_ground = false
		local has_wall_collision = false
		for col in all(collisions) do
			local tile = g_state.tile_manager.get_tile_at_cell(g_state.tile_manager, col.cell.x, col.cell.y)
			g_log.log(tile_str(tile))

			if tile.type == g_flags.normal then
				tile.set_state(tile, "warmup")
			elseif tile.type == g_flags.instakill then
				self.kill(self)
				break
			elseif tile.type == g_flags.exit then
				set_game_state(level_end_state)
				break
			end

			if col.is_ground_collision then
				self.is_on_ground = true
				self.jump_count = 0
				if self.is_jumping then
					self.stop_jump(self)
				end

				if self.is_wall_sliding then
					self.stop_wall_slide(self)
				end
			elseif col.is_wall_collision and not self.is_jumping then
				self.wall_slide(self)
				has_wall_collision = true
			end
		end

		if self.is_wall_sliding and not has_wall_collision then
			self.stop_wall_slide(self)
		end
	end

	p.kill = function(self)
		set_anim_spr_animation(self.anim_controller, 'dead')
		self.anim_controller.loop = false
		self.is_dead = true
	end

	-- checks for collisions with the player
	p.check_for_collisions = function(self, collisions, iteration)
		local max_iterations = 3
		if iteration > max_iterations then 
			return collisions
		end

		local direction = vec2_normalized(self.vel)

		-- check if left foot is on ground
		local old_left_foot = self.old_pos + make_vec2(8 * 0.33, 7)
		local left_foot = self.pos + make_vec2(8 * 0.33, 7)
		local left_foot_intersection = check_swept_collision(old_left_foot, left_foot)

		-- check if right foot is on ground
		local old_right_foot = self.old_pos + make_vec2(8 * 0.66, 7)
		local right_foot = self.pos + make_vec2(8 * 0.66, 7)
		local right_foot_intersection = check_swept_collision(old_right_foot, right_foot)

		-- adjust pos to account for the collision
		if left_foot_intersection ~= nil then
			if self.pos.y > left_foot_intersection.pos.y - 8 then
				self.pos.y = left_foot_intersection.pos.y - 8
				left_foot_intersection.is_ground_collision = true
				add(collisions, left_foot_intersection)
				return self.check_for_collisions(self, collisions, iteration + 1)
			end
		elseif right_foot_intersection ~= nil then
			if self.pos.y > right_foot_intersection.pos.y - 8 then
				self.pos.y = right_foot_intersection.pos.y - 8
				right_foot_intersection.is_ground_collision = true
				add(collisions, right_foot_intersection)
				return self.check_for_collisions(self, collisions, iteration + 1)
			end
		end

		-- check if left side of head hit the ceiling
		local old_left_head = self.old_pos + make_vec2(8 * 0.33, 0)
		local left_head = self.pos + make_vec2(8 * 0.33, 0)
		local left_head_intersection = check_swept_collision(old_left_head, left_head)

		-- check if right side of head hit the ceiling
		local old_right_head = self.old_pos + make_vec2(8 * 0.66, 0)
		local right_head = self.pos + make_vec2(8 * 0.66, 0)
		local right_head_intersection = check_swept_collision(old_right_head, right_head)

		-- adjust pos to account for the collision
		if left_head_intersection ~= nil then
			if self.pos.y < left_head_intersection.pos.y + 8 then
				self.pos.y = left_head_intersection.pos.y + 8
				add(collisions, left_head_intersection)
				return self.check_for_collisions(self, collisions, iteration + 1)
			end
		elseif right_head_intersection ~= nil then
			if self.pos.y < right_head_intersection.pos.y + 8 then
				self.pos.y = right_head_intersection.pos.y + 8
				add(collisions, right_head_intersection)
				return self.check_for_collisions(self, collisions, iteration + 1)
			end
		end

		-- check if the left side of the head is against tile
		local old_left_hand = clone_vec2(self.old_pos)
		local left_hand = clone_vec2(self.pos + make_vec2(0, 8 * 0.5))
		local left_hand_intersection = check_swept_collision(old_left_hand, left_hand)

		-- adjust pos to account for the collision
		if left_hand_intersection ~= nil then
			if self.pos.x < left_hand_intersection.pos.x + 8 then
				self.pos.x = left_hand_intersection.pos.x + 8
				left_hand_intersection.is_wall_collision = true
				add(collisions, left_hand_intersection)
				return self.check_for_collisions(self, collisions, iteration + 1)
			end
		end

		-- check if the right side of the head is against tile
		local old_right_hand = self.old_pos + make_vec2(7, 0)
		local right_hand = clone_vec2(self.pos) + make_vec2(7, 8 * 0.5)
		local right_hand_intersection = check_swept_collision(old_right_hand, right_hand)

		-- adjust pos to account for the collision
		if right_hand_intersection ~= nil then
			if self.pos.x > right_hand_intersection.pos.x - 8 then
				self.pos.x = right_hand_intersection.pos.x - 8
				right_hand_intersection.is_wall_collision = true
				add(collisions, right_hand_intersection)
				return self.check_for_collisions(self, collisions, iteration + 1)
			end
		end

		return collisions
	end

	return p
end

-- 
-- check for collisions between a dynamic pos and a the tilemap using a sweeping algorithm
--
function check_swept_collision(old_pos, new_pos)
	local direction = vec2_normalized(new_pos - old_pos)
	local attempted_magnitude = vec2_magnitude(new_pos - old_pos)
	local sweeper = clone_vec2(old_pos)
	while (intersection == nil and (vec2_magnitude(sweeper - old_pos) < attempted_magnitude)) do
		local tile = g_state.tile_manager.get_map_tile_at_pos(g_state.tile_manager, sweeper)
		if tile ~= nil then
			-- g_log.log("s: "..vec2_str(sweeper).." tc: "..vec2_str(tile.cell))
			if tile.type ~= nil then
				-- g_log.log("collision")
			 	return tile
			end
		end
		sweeper += clone_vec2(direction)
	end

	return nil
end


--
-- creates a timer for a single tile
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
	t.is_dead = false
	
	if t.type == g_flags.normal then
		t.sprites = {16, 17, 18}
	elseif t.type == g_flags.instakill then
		t.sprites = { 32 }
	elseif t.type == g_flags.exit then
		t.sprites = { 19 }
	elseif t.type == g_flags.indestructible then
		t.sprites = { 20 }
	end

	t.update = function(self)
		elapsed_changed = false

		if self.state == 'idle' then
			-- do nothing.
		elseif self.state == 'cooldown' then
			self.elapsed -= self.cooldown_rate

			if self.elapsed <= 0 then
				self.set_state(self, 'idle')
			end

			elapsed_changed = true
		elseif self.state == 'warmup' then
			self.elapsed += self.warmup_rate

			if self.elapsed >= self.max_duration then
				self.set_state(self, 'destroyed')
			else
				self.set_state(self, 'cooldown') -- this can be changed to warmup next frame if the tile is activated again
			end
			elapsed_changed = true
		elseif self.state == 'destroyed' then
			-- @todo destroy tile
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
			
			self.is_dead = false
			self.set_state(self, 'idle')
		end
	end

	t.set_state = function(self, state)
		if not self.is_dead then
			self.state = state
		end

		if self.state == 'idle' then
			self.elapsed = 0
		elseif self.state == 'destroyed' then
			self.is_dead = true
		end
	end

	return t
end

function tile_str(tile)
	return tile.name.." ("..tile.type.."): s="..tile.state.." e="..tile.elapsed.."/"..tile.max_duration
end

--
-- creates a manager for a grid of tiles
function make_tile_manager(start_x, start_y, width, height)
	local tm = make_game_object("tile manager", start_x, start_y)
	tm.tiles = {}
	tm.start_x = start_x
	tm.start_y = start_y
	tm.width = width
	tm.height = height
	tm.tile_timer_duration = 60
	tm.cooldown_rate = 0.5
	tm.warmup_rate = 3
	tm.active_tiles = {}

	tm.init = function(self) 
		-- reset any modified tiles from a previous session
		self.reset(self)

		-- populate the tiles for collidable tiles
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
					add(self.tiles[x + 1], 0) -- can't add nil to a table for some reason.
				end
			end
		end
	end

	tm.update = function(self)
		for tile in all(self.active_tiles) do
			if tile ~= 0 and tile.is_dead then
				del(self.active_tiles, tile)
				del(g_state.scene, tile)
				mset(tile.cell_x, tile.cell_y, 0)
			end
		end
	end

	tm.reset = function(self)
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

	tm.get_tile_at_cell = function(self, x, y)
		return self.tiles[1 + x - self.start_x][1 + y - self.start_y]
	end

	tm.get_map_tile_at_pos = function(self, pos)
		local tile = get_map_tile_at_pos(pos)
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

	return tm
end

--
-- gets the map tile at a pixel pos
--
function get_map_tile_at_pos(pos)
	if pos.x < 0 or pos.y < 0 then
		return nil
	end

	local cell = pos_to_cell(pos)
	local sprite = mget(cell.x, cell.y)
	local tiletype = get_tile_type(sprite)
	return { type = tiletype, sprite = sprite, cell = cell, pos = cell_to_pos(cell.x, cell.y) }
end

function is_cell_collidable(cell_x, cell_y)
	return get_tile_type(mget(cell_x, cell_y)) ~= nil
end

function get_tile_type(sprite)
	if fget(sprite, g_flags.normal) then
		return g_flags.normal
	elseif fget(sprite, g_flags.instakill) then
		return g_flags.instakill
	elseif fget(sprite, g_flags.exit) then
		return g_flags.exit
	elseif fget(sprite, g_flags.indestructible) then
		return g_flags.indestructible
	else
		return nil
	end
end

--
-- converts a worldspace pos to map cell coords
--
function pos_to_cell(pos)
	local cell_x = flr(pos.x / 8)
	local cell_y = flr(pos.y / 8)

	return make_vec2(cell_x, cell_y)
end

--
-- converts map cell coords to a worldspace pos
--
function cell_to_pos(x, y)
	local world_x = x * 8
	local world_y = y * 8

	return make_vec2(world_x, world_y)
end

--
-- records a new time in the best-times list.
--
function record_time(level, new_time, player_name)
	local new_best_times = {}
	local added_new_time = false
	local count = 0
	local insert_position = 0
	max_best_time_records = 5
	for time in all(level.times) do
		if not added_new_time and new_time <= time.time then
			add(new_best_times, { time = new_time, name = player_name })
			added_new_time = true
			count += 1
			insert_position = count
		end

		if count == max_best_time_records then
			break
		end

		add(new_best_times, time)
		count += 1

		if count == max_best_time_records then
			break
		end
	end

	level.times = new_best_times
	return insert_position
end

--
-- makes a game manager
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
		local player_x = 0
		local player_y = 0
		local player_sprite = 1
		local player_speed = 2
		local player_jump_power = 2.25
		local player_jump_duration = 7
		self.player = make_player("player", player_x, player_y, player_sprite, player_speed, player_jump_power, player_jump_duration)
	end

	g.load_level = function(self, level_index)
		if level_index < 1 or level_index > #self.levels then
			return
		end

		new_level = self.levels[level_index]
		self.player.pos = make_vec2(new_level.player_x, new_level.player_y)
		self.player.init(self.player)
		self.active_level = level_index

		self.main_camera = make_camera("main", 0, 0, 0, 0, 128, 128)
		attach_follow_camera(self.main_camera, 48, 32, nil)

		g_physics.init(g_physics, make_vec2(0, 2.75))

		-- create the tiles
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
-- sets the active game state
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
-- particle system.
--
function make_particle_system(name, pos, sprite, animation, lifespan, particle_count, particle_speed)
	local game_obj = make_game_object(name, pos.x, pos.y)
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
			pos = make_vec2(0, 0),
			vel = vec2_normalized(make_vec2(rnd() - 0.5, rnd() - 0.5)) * particle_speed,
		})
	end

	game_obj.is_dead = function(self)
		return self.particle_system.lifespan <= 0
	end

	game_obj.update = function(self)
		if self.particle_system.lifespan > 0 then
			for p in all(self.particle_system.particles) do
				p.pos += p.vel
			end

			update_anim_spr_controller(self.anim_controller, self)

			self.particle_system.lifespan -= 1
		end
	end

	game_obj.renderable.render = function(self, pos)
		if self.game_obj.particle_system.lifespan > 0 then
			for p in all(self.game_obj.particle_system.particles) do
				self.default_render(self, pos + p.pos)
			end
		end
	end

	return game_obj
end

-- 
-- game object
--
function make_game_object(name, pos_x, pos_y)
	local go = {
		pos = make_vec2(pos_x, pos_y),
		name = name
	}
	return go
end

--
-- renderable maker.
--
function attach_renderable(game_obj, sprite)
	local r = {
		game_obj = game_obj,
		sprite = sprite,
		flip_x = false,
		flip_y = false,
		sprite_width = 1,
		sprite_height = 1,
		draw_order = 0,
		palette = nil
	}

	-- default rendering function
	r.render = function(self, pos)

		-- set the palette
		if (self.palette) then
			-- set colours
			for i = 0, 15 do
				pal(i, self.palette[i + 1])
			end

			-- set transparencies
			for i = 17, #self.palette do
				palt(self.palette[i], true)
			end
		end

		-- draw
		spr(self.sprite, pos.x, pos.y, self.sprite_width, self.sprite_height, self.flip_x, self.flip_y)

		-- reset the palette
		if (self.palette) then
			pal()
			palt()
		end
	end

	-- save the default render function in case the object wants to use it in an overridden render function.
	r.default_render = r.render

	game_obj.renderable = r;
	return game_obj;
end

--
-- renderer subsystem
--
g_renderer = {}

--
-- main render pipeline
--
g_renderer.render = function()
	-- collect renderables 
	local renderables = {};
	for game_obj in all(g_state.scene) do
		if (game_obj.renderable) then
			add(renderables, game_obj)
		end
	end

	-- sort by draw-order
	quicksort_draw_order(renderables)

	-- draw the scene
	camera_draw_start(g_state.main_camera)
	
	if g_state == ingame_state then
		local level = g_game.get_active_level(g_game)

		if level.bg_x ~= nil then
			local cam = g_state.main_camera
			map(level.bg_x, level.bg_y, cam.pos.x - cam.cam.draw_pos.x, cam.pos.y - cam.cam.draw_pos.y, level.width, level.height)
		end
		map(level.cell_x, level.cell_y, level.cell_x * 8, level.cell_y * 8, level.width, level.height)
	else
		map(0, 0, 0, 0, 16, 16) -- draw the whole map and let the clipping region remove unnecessary bits
	end

	for game_obj in all(renderables) do
		game_obj.renderable.render(game_obj.renderable, game_obj.pos)
	end

	camera_draw_end(g_state.main_camera)
end

--
-- sort a renderable array by draw-order
-- 
function quicksort_draw_order(list)
	quicksort_draw_order_helper(list, 1, #list)
end

--
-- helper function for sorting renderables by draw-order
function quicksort_draw_order_helper(list, low, high)
	if (low < high) then
		local p = quicksort_draw_order_partition(list, low, high)
		quicksort_draw_order_helper(list, low, p - 1)
		quicksort_draw_order_helper(list, p + 1, high)
	end
end

--
-- partition a renderable list by draw_order
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
-- camera
--
function make_camera(name, pos_x, pos_y, draw_x, draw_y, draw_width, draw_height)
	local c = make_game_object(name, pos_x, pos_y)
	c.cam = {
		draw_pos = make_vec2(draw_x, draw_y),
		draw_width = draw_width,
		draw_height = draw_height,
	}	
	
	return c
end

function camera_draw_start(cam)
	local draw_x = cam.cam.draw_pos.x
	local draw_y = cam.cam.draw_pos.y

	local cam_x = cam.pos.x - draw_x
	local cam_y = cam.pos.y - draw_y

	camera(cam_x, cam_y)
	clip(draw_x, draw_y, cam.cam.draw_width, cam.cam.draw_height)
end

function camera_draw_end(cam)
	camera()
	clip()
end

--
-- camera that can follow a target
--
function attach_follow_camera(cam, bounds_width, bounds_height, target)
	cam.follow_cam = {
		bounds_width = bounds_width,
		bounds_height = bounds_height,
		target = target
	}

	cam.update = function(self)
		if self.follow_cam.target ~= nil then
			-- @todo apply to center of screen, not left edge.
			
			local follow = self.follow_cam
			local target = follow.target
			
			local left_bound = self.pos.x + flr(self.cam.draw_width / 2) - flr(follow.bounds_width / 2)
			local right_bound = self.pos.x + flr(self.cam.draw_width / 2) + flr(follow.bounds_width / 2)
			if target.pos.x < left_bound then
				self.pos.x -= left_bound - target.pos.x
			elseif target.pos.x + 8 > right_bound then
				self.pos.x += target.pos.x + 8 - right_bound
			end

			local top_bound = self.pos.y + flr(self.cam.draw_height / 2) - flr(follow.bounds_height / 2)
			local bottom_bound = self.pos.y + flr(self.cam.draw_height / 2) + flr(follow.bounds_height / 2)
			if target.pos.y < top_bound then
				self.pos.y -= top_bound - target.pos.y
			elseif target.pos.y + 8 > bottom_bound then
				self.pos.y += target.pos.y + 8 - bottom_bound
			end
		end 
	end
end

--
-- animated sprite controller
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
		loop = true,
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
				if controller.loop then
					controller.current_cell = 1
				else
					controller.current_cell = #controller.animations[controller.current_animation]
				end
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

function is_anim_spr_playing(controller)
	return controller.current_animation != nil and controller.current_cell ~= nil and
	   (controller.loop or (not controller.loop and controller.current_cell < #controller.animations[controller.current_animation]))
end

--
-- physics
--
g_physics = {
	gravity = nil,
}

g_physics.init = function(self, gravity)
	self.gravity = gravity
end


--
-- 2d vector
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
	local v = {
		x = x,
		y = y,
	}
	setmetatable(v, vec2_meta)
	return v;
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
-- logger
--
g_log = {
	show_debug = false,
	log_data = {}
}

--
-- logs a message
--
g_log.log = function(message)
	add(g_log.log_data, message)
end

g_log.syslog = function(message)
	printh(message, 'debug.log')
end

--
-- renders the log
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
-- clears the log
--
g_log.clear = function()
	g_log.log_data = {}
end

--
-- global init function.
--
function _init()
	g_game = make_game(g_levels)
	g_game.init(g_game)

	set_game_state(main_menu_state)
end

--
-- global update function
--
function _update()
	if g_state ~= nil then
		g_state.update(g_state)
	end
	
	g_log.log("mem: "..stat(0).." cpu: "..stat(1))
end

--
-- global draw function
--
function _draw()
	cls()

	if g_state ~= nil then
		g_state.draw(g_state)
	end

	-- draw debug log
	g_log.render()
	g_log.clear()
end
__gfx__
00000000009999000099990000999900009999000099990000999900008888000000000000000000000000000000000000000000000000000000000000000000
0000000009ffff9009fffff009fffff009f8ff8009f8ff8009fffff0088888800008800000000000000000000000000000000000000000000000000000000000
000000000f8ff8f009f8ff8009f8ff8009fffff009fffff009f8ff80088888800088880000099000000000000000000000000000000000000000000000000000
000000000ffffff009fffff009fffff009fffff009fffff009fffff0088888800888888000999900000aa0000005500000000000000000000000000000000000
0000000000ffff0000ffff0000ffff00f0ffff0f00ffff00f0ffff00808888080888888000999900000aa0000005500000000000000000000000000000000000
00000000088888800888888008888880088888800888888008888880088888800088880000099000000000000000000000000000000000000000000000000000
000000000f8888f00f8888f00f8888f000888a00f0888a0f0888880f008888000008800000000000000000000000000000000000000000000000000000000000
000000000090090000900a0000a009000090000000900000900a0000008000000000000000000000000000000000000000000000000000000000000000000000
4444444499999999aaaaaaaabbbbbbbb777777770700000000000000060000000000000000000000000000000000000000000000000000000000000000000000
4545454495959599a5a5a5aa3b0000bb607070770000006000010000000070000070000000000000200100200000000000000000000000000000000000000000
4454545499595959aa5a5a5a30b00b0b660707070000000000010000600000000000000000000000020002000000000000000000000000000000000000000000
4545454495959599a5a5a5aa300bb00b606070770060000000d0d000000060000000000000000000008080000000000000000000000000000000000000000000
4454545499595959aa5a5a5a3003300b660607070000000711060110000000070000000000000000100e00100000000000000000000000000000000000000000
4545454495959599a5a5a5aa3030030b606060770000000000d0d000000600600000000000006000008080000000000000000000000000000000000000000000
4454545499595959aa5a5a5a3300003b660606070000600000010000070000000000000000000000020002000000000000000000000000000000000000000000
4444444499999999aaaaaaaa33333333666666667000000000010000000000700000000000000000200100200000000000000000000000000000000000000000
00007000000080007000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006000000080006670000000000766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0056700d00288006666770000776666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10556601105568016666666776666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11556671115286815665550000555665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15556671155286615555000000005555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15566661152868615550000000000555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55566667522666865000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00544400004440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05554400045544000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55455440555554440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04545544545445400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05545454544554000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555440055450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00054400005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666666666666677777777666666660156666666666670000000000000000000000000000000000000000000000000
66666666611666111111116666222222666116666661166676767676555555550001666666667000000000000000000000000000000000000000000000000000
66666666616166166266661662666666661cc166661cc16666666666666666660001566666667000000000000000000000000000000000000000000000000000
6666666661616616626666166622666663cccc1663bcbb1666666666555555550015666666666700000000000000000000000000000000000000000000000000
6666666661661616626666166666226663bcbc1663bbbb1666666666666666660016666666666700000000000000000000000000000000000000000000000000
66666666616616166266661666666626663bb366663bb36666666666511551150015666666666700000000000000000000000000000000000000000000000000
6666666611666116662222222222226666633666666b366666666666666666660001666666667000000000000000000000000000000000000000000000000000
666666666666666666666666666666666666666666b3666666666666111111110156666666666670000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666665566666666666677666666660000000600000060000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666665666666666666667666666660000066006000600000000000000000000000000000000000000000000000000
6366666611162222222611111111111122222222111622222226111d666666660006051005605100000000000000000000000000000000000000000000000000
66663666666166666662666666666666666666665661666666626667666666666050510001550506000000000000000000000000000000000000000000000000
6663636622261111111622222222222211111111222611111116222e666666661566560000556556000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666665666666666666667666666661556556005655655000000000000000000000000000000000000000000000000
66666636666666666666666666666666666666665566666666666677565656560115655055665110000000000000000000000000000000000000000000000000
66666666666666666666666666666666666666665666666666666667555555550001151011551000000000000000000000000000000000000000000000000000
66666666556666666666667700000005700000000007777777777000666666770000000000000000000000000000000000000000000000000000000000000000
66666366566666666666666700000556677000000076666116666700666666670000000000000000000000000000000000000000000000000000000000000000
66663666556666666666667700055661d66770000766661cc1666670666666770000000000000000000000000000000000000000000000000000000000000000
6666366656666666666666670056661ccd666700566661cccc166667666666670000000000000000000000000000000000000000000000000000000000000000
666366665566666666666677056661cc7cd66670566661cccc166667666666770000000000000000000000000000000000000000000000000000000000000000
66366666566666666666666756661cccc7cd66675666661cc1666667666666700000000000000000000000000000000000000000000000000000000000000000
66666666556666666666667756611111ddddd6675666666116666667565655000000000000000000000000000000000000000000000000000000000000000000
66666666566666666666666756666666666666675666666666666667555550000000000000000000000000000000000000000000000000000000000000000000
65666666000000057000000000000000666666765633636363633367000666666666600066666666000000000000000000000000000000000000000000000000
56666666000000566700000000000000666666675636636363663667005555555555560055555555000000000000000000000000000000000000000000000000
66666666000005657670000000000000666666665633663663663667005555555555560055555555000000000000000000000000000000000000000000000000
66666666000056566767000000000000666666665636636363663667000111111111c00011111111000000000000000000000000000000000000000000000000
66666666000565666676700000000000666666665633636363663667000111111111c00011111111000000000000000000000000000000000000000000000000
66666666005656666667670000000000666666665666666666666667005666666666660066666666000000000000000000000000000000000000000000000000
66666666056566666666767000000000666666665666666666666667005555555555560055555555000000000000000000000000000000000000000000000000
66666666565666666666676700000000666666665555555555555557000555555555600055555555000000000000000000000000000000000000000000000000
00000000910000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
71717171715171617151717171717171000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
71715171717151715151717151717171000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
71517171517151715151717171715171000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
71715151717151715171615171517151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
71715151716171715151515171717171000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
71715171517171717171717171617151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
51717171715171617171517151715171000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
71715171715171717171717171717171000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000001010104080000000000000000000000020202020000000000000000000000000000000000000000000000000000000000000000000008000808000000000000000000000008080802020000000000000008080808040408000000000000000008080800080404080808000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000001300000000000000636400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000555600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000014000000000000141400000000000000000000000000000000000000000000777800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000014000000000000141400000010100000000000001010000000000000000071404072000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1400000000000000000000000013000014000000130000141400000000000000000000000000000000000000007170404074720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1400000000000014140000000014000014000000000000141400000000000000100000000000000000000000006140404040490000000000000000006566000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1400000000231010101000000014000014000000000000141400000000000000000000000000000000464600004844404045620000000000000000007576000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1400000000000000000000000014000014000000000000141400000000000000000010000000000000000000004860404040620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1400000000000010000000001014000014000000000000141400000000000010100000000000000000000000005551545454560000007146467200212121210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1400101000000010100000001014000014000000000010141400000010100000000000000000000000000000006140414243490000006147476200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1400101010101010101010101014000014100000001010141414140000000000000000000000001400464646460000000000004646467040406200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2021202021212120202121212020000020212121212121212121212121212121212121212121212121000000000000000000005757575757576700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b1b1b151b00181b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
191b1b181b00001b000000000000180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b1b1b0018000015000000180000191500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b1b19001b1b1800000019150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b19181800001818151500190000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b15181800000015171a15000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b1b001b00000000171500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1500000000151700001918000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000019001b001b1b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00191618001b1b1b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000017181b181b1b180019190000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001b1b151b1b1b1716000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001b1b1b1b1b1b1917151800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0019001b1b1b1b1b1b1b001b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000018001b181b1b1b1b1b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

