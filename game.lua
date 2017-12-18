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
		p1_x = (40 * 8) + 8,
		p1_y = 3 * 128 / 4,
	},
	{
		cell_x = 0,
		cell_y = 0,
		bg_x = 0,
		bg_y = 16,
		width = 16,
		height = 16,
		p1_x = 1 * 128 / 4,
		p1_y = 3 * 128 / 4,
	},
	{
		cell_x = 16,
		cell_y = 0,
		bg_x = 0,
		bg_y = 16,
		width = 8,
		height = 16,
		p1_x = (16 * 8) + 8,
		p1_y = 3 * 128 / 4,
	},
	{
		cell_x = 24,
		cell_y = 0,
		bg_x = 0,
		bg_y = 16,
		width = 16,
		height = 16,
		p1_x = (24 * 8) + 8,
		p1_y = 3 * 128 / 4,
	},
}

g_game = nil

-- Encapsulates the ingame state @TODO Merge down into g_game manager
--
ingame_state = {
	scene = nil,
	main_cam = nil,
	player = nil,
	tile_manager = nil,

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
		self.main_cam = g_game.main_cam
		add(self.scene, self.main_cam)
		self.main_cam.follow_cam.target = self.player
		self.main_cam.pos = mk_vec2(self.player.pos.x + 128 / 4, self.player.pos.y  - 3 * 128 / 4)
	end,

	update = function(self)
		-- Process input
		self.player.vel = mk_vec2(0, 0)
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

		-- @DEBUG Reload the level
		if btnp(5) then
			g_game.reload_level(g_game)
			return
		end

		-- Update game objs
		for game_obj in all(self.scene) do
			if (game_obj.update) then
				game_obj.update(game_obj)
			end
		end
	end,

	draw = function(self)
		g_renderer.render()
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
		camera()
		clip()

		-- Draw UI window
		rectfill(12, 30, 116, 114, 6)
		rectfill(14, 32, 114, 112, 3)
		color(7)

		local line_height = 8
		local print_y = 40
		print("level complete!", 36, print_y)
		print_y += line_height
		print("press any key", 38, print_y)
		print_y += line_height * 2
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

-- Create a player
function mk_player(name, start_x, start_y, sprite, walk_speed, jump_power, jump_duration)
	local p = mk_game_obj(name, start_x, start_y)

	-- Physics
	p.vel = mk_vec2(0, 0)
	p.old_pos = mk_vec2(start_x, start_y)
	p.jump_power = jump_power
	p.is_jumping = false
	p.jump_elapsed = 0
	p.jump_duration = jump_duration
	p.jump_count = 0
	p.is_on_ground = false
	p.is_jump_held = false
	p.is_dead = false
	p.death_explosion = nil

	-- Animations
	local p1_anims = {
		idle = { 1, },
		walk = { 2, 3 },
		jump = { 4 },
		wallslide = { 6 },
		fall = { 4, 5 },
		dead = { 7, 8, 9, 10, 11, 0 },
	}

	attach_anim_spr_controller(p, 4, p1_anims, "idle", 0)

	-- Game stats
	p.walk_speed = walk_speed
	attach_renderable(p, sprite)
	p.renderable.draw_order = 1	-- Draw player after other in-game objs

	p.init = function(self)
		self.vel = mk_vec2(0, 0)
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

	p.update = function (self)
		if self.is_dead then
			if not self.death_explosion and not is_anim_spr_playing(self.anim_controller) then
				local explosion_duration = 30 * 1.5
				local explosion_particles = 50
				local explosion_speed = 1
				self.death_explosion = mk_particle_system("player-death", self.pos, 7, { 7, 7, 8, 9, 10, 11, 11 }, explosion_duration, explosion_particles, explosion_speed)
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

	p.check_for_collisions = function(self, collisions, iteration)
		local max_iterations = 3
		if iteration > max_iterations then 
			return collisions
		end

		local direction = vec2_normalized(self.vel)

		-- Check if left foot is on ground
		local old_lf = self.old_pos + mk_vec2(8 * 0.33, 7)
		local lf = self.pos + mk_vec2(8 * 0.33, 7)
		local lf_intersection = check_swept_collision(old_lf, lf)

		-- Check if right foot is on ground
		local old_rf = self.old_pos + mk_vec2(8 * 0.66, 7)
		local rf = self.pos + mk_vec2(8 * 0.66, 7)
		local rf_intersection = check_swept_collision(old_rf, rf)

		-- Adjust pos to account for the collision
		if lf_intersection ~= nil then
			if self.pos.y > lf_intersection.pos.y - 8 then
				self.pos.y = lf_intersection.pos.y - 8
				lf_intersection.is_ground_collision = true
				add(collisions, lf_intersection)
				return self.check_for_collisions(self, collisions, iteration + 1)
			end
		elseif rf_intersection ~= nil then
			if self.pos.y > rf_intersection.pos.y - 8 then
				self.pos.y = rf_intersection.pos.y - 8
				rf_intersection.is_ground_collision = true
				add(collisions, rf_intersection)
				return self.check_for_collisions(self, collisions, iteration + 1)
			end
		end

		-- Check if left side of head hit the ceiling
		local old_lh = self.old_pos + mk_vec2(8 * 0.33, 0)
		local lh = self.pos + mk_vec2(8 * 0.33, 0)
		local lh_intersection = check_swept_collision(old_lh, lh)

		-- Check if right side of head hit the ceiling
		local old_rh = self.old_pos + mk_vec2(8 * 0.66, 0)
		local rh = self.pos + mk_vec2(8 * 0.66, 0)
		local rh_intersection = check_swept_collision(old_rh, rh)

		-- Adjust pos to account for the collision
		if lh_intersection ~= nil then
			if self.pos.y < lh_intersection.pos.y + 8 then
				self.pos.y = lh_intersection.pos.y + 8
				add(collisions, lh_intersection)
				return self.check_for_collisions(self, collisions, iteration + 1)
			end
		elseif rh_intersection ~= nil then
			if self.pos.y < rh_intersection.pos.y + 8 then
				self.pos.y = rh_intersection.pos.y + 8
				add(collisions, rh_intersection)
				return self.check_for_collisions(self, collisions, iteration + 1)
			end
		end

		-- Check if the left side of the head is against tile
		local old_lhand = clone_vec2(self.old_pos)
		local lhand = clone_vec2(self.pos + mk_vec2(0, 8 * 0.5))
		local lhand_intersection = check_swept_collision(old_lhand, lhand)

		-- Adjust pos to account for the collision
		if lhand_intersection ~= nil then
			if self.pos.x < lhand_intersection.pos.x + 8 then
				self.pos.x = lhand_intersection.pos.x + 8
				lhand_intersection.is_wall_collision = true
				add(collisions, lhand_intersection)
				return self.check_for_collisions(self, collisions, iteration + 1)
			end
		end

		-- Check if the right side of the head is against tile
		local old_rhand = self.old_pos + mk_vec2(7, 0)
		local rhand = clone_vec2(self.pos) + mk_vec2(7, 8 * 0.5)
		local rhand_intersection = check_swept_collision(old_rhand, rhand)

		-- Adjust pos to account for the collision
		if rhand_intersection ~= nil then
			if self.pos.x > rhand_intersection.pos.x - 8 then
				self.pos.x = rhand_intersection.pos.x - 8
				rhand_intersection.is_wall_collision = true
				add(collisions, rhand_intersection)
				return self.check_for_collisions(self, collisions, iteration + 1)
			end
		end

		return collisions
	end

	return p
end

-- 
-- Check for collisions between a dynamic pos and a the tilemap using a sweeping algorithm
--
function check_swept_collision(old_pos, new_pos)
	local direction = vec2_normalized(new_pos - old_pos)
	local attempted_magnitude = vec2_magnitude(new_pos - old_pos)
	local sweeper = clone_vec2(old_pos)
	while (intersection == nil and (vec2_magnitude(sweeper - old_pos) < attempted_magnitude)) do
		local tile = g_state.tile_manager.get_map_tile_at_pos(g_state.tile_manager, sweeper)
		if tile ~= nil then
			if tile.type ~= nil then
			 	return tile
			end
		end
		sweeper += clone_vec2(direction)
	end

	return nil
end


-- Creates a timer for a single tile
function mk_tile(name, type, cell_x, cell_y, max_duration, cooldown_rate, warmup_rate)
	local t = mk_game_obj(name, 0, 0)
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
			-- Do nothing.
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
				self.set_state(self, 'cooldown') -- This can be changed to warmup next frame if the tile is activated again
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
-- Creates a manager for a grid of tiles
function mk_tile_manager(start_x, start_y, width, height)
	local tm = mk_game_obj("tile manager", start_x, start_y)
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
					add(self.tiles[x + 1], mk_tile("tile-"..cell_x.."-"..cell_y, tiletype, cell_x, cell_y, self.tile_timer_duration, self.cooldown_rate, self.warmup_rate))
					add(self.active_tiles, self.tiles[x + 1][y + 1])
				else
					add(self.tiles[x + 1], 0) -- Can't add nil to a table for some reason.
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

-- Gets the map tile at a pixel pos
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

-- Converts a worldspace pos to map cell coords
function pos_to_cell(pos)
	local cell_x = flr(pos.x / 8)
	local cell_y = flr(pos.y / 8)

	return mk_vec2(cell_x, cell_y)
end

-- Converts map cell coords to a worldspace pos
function cell_to_pos(x, y)
	local world_x = x * 8
	local world_y = y * 8

	return mk_vec2(world_x, world_y)
end

-- Makes a game manager
function mk_game(levels)
	g = {
		levels = levels,
		active_level = nil,
		player = nil,
		main_cam = nil,
		tile_manager = nil,
		scene = {}
	}

	g.init = function(self)
		local p1_height = 8
		local p1_x = 0
		local p1_y = 0
		local p1_sprite = 1
		local p1_speed = 2
		local p1_jump_power = 2.25
		local p1_jump_duration = 7
		self.player = mk_player("player", p1_x, p1_y, p1_sprite, p1_speed, p1_jump_power, p1_jump_duration)
	end

	g.load_level = function(self, level_index)
		if level_index < 1 or level_index > #self.levels then
			return
		end

		new_level = self.levels[level_index]
		self.player.pos = mk_vec2(new_level.p1_x, new_level.p1_y)
		self.player.init(self.player)
		self.active_level = level_index

		self.main_cam = mk_camera("main", 0, 0, 0, 0, 128, 128)
		attach_follow_camera(self.main_cam, 56, 80, nil)

		g_physics.init(g_physics, mk_vec2(0, 2.75))

		-- Create the tiles
		if self.tile_manager ~= nil then
			self.tile_manager.reset(self.tile_manager)
		end

		self.tile_manager = mk_tile_manager(new_level.cell_x, new_level.cell_y, new_level.width, new_level.height)
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

-- Sets the active game state
function set_game_state(game_state)
	if g_state ~= nil and g_state.exit then
		g_state.exit(g_state)
	end

	g_state = game_state

	if g_state ~= nil and g_state.enter then
		g_state.enter(g_state)
	end
end

-- Particle system.
function mk_particle_system(name, pos, sprite, animation, lifespan, particle_count, particle_speed)
	local game_obj = mk_game_obj(name, pos.x, pos.y)
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
			pos = mk_vec2(0, 0),
			vel = vec2_normalized(mk_vec2(rnd() - 0.5, rnd() - 0.5)) * particle_speed,
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
-- Game obj
--
function mk_game_obj(name, pos_x, pos_y)
	local go = {
		pos = mk_vec2(pos_x, pos_y),
		name = name
	}
	return go
end

-- Renderable maker.
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

	-- Default rendering function
	r.render = function(self, pos)

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
		spr(self.sprite, pos.x, pos.y, self.sprite_width, self.sprite_height, self.flip_x, self.flip_y)

		-- Reset the palette
		if (self.palette) then
			pal()
			palt()
		end
	end

	-- Save the default render function in case the obj wants to use it in an overridden render function.
	r.default_render = r.render

	game_obj.renderable = r;
	return game_obj;
end

-- Renderer subsystem
g_renderer = {}

-- Main render pipeline
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
	camera_draw_start(g_state.main_cam)
	
	if g_state == ingame_state then
		local level = g_game.get_active_level(g_game)

		if level.bg_x ~= nil then
			local cam = g_state.main_cam
			map(level.bg_x, level.bg_y, cam.pos.x - cam.cam.draw_pos.x, cam.pos.y - cam.cam.draw_pos.y, level.width, level.height)
		end
		map(level.cell_x, level.cell_y, level.cell_x * 8, level.cell_y * 8, level.width, level.height)
	else
		map(0, 0, 0, 0, 16, 16) -- draw the whole map and let the clipping region remove unnecessary bits
	end

	for game_obj in all(renderables) do
		game_obj.renderable.render(game_obj.renderable, game_obj.pos)
	end

	camera_draw_end(g_state.main_cam)
end

-- Sort a renderable array by draw-order 
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

-- Partition a renderable list by draw_order
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

-- Camera
function mk_camera(name, pos_x, pos_y, draw_x, draw_y, draw_width, draw_height)
	local c = mk_game_obj(name, pos_x, pos_y)
	c.cam = {
		draw_pos = mk_vec2(draw_x, draw_y),
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

-- Camera that can follow a target
function attach_follow_camera(cam, bounds_width, bounds_height, target)
	cam.follow_cam = {
		bounds_width = bounds_width,
		bounds_height = bounds_height,
		target = target
	}

	cam.update = function(self)
		if self.follow_cam.target ~= nil then
			-- @TODO Apply to center of target
			
			local follow = self.follow_cam
			local target = follow.target
			
			local cam_center = self.pos.x + flr(self.cam.draw_width / 2)
			local left_bound = cam_center - flr(follow.bounds_width / 2)
			local right_bound = cam_center + flr(follow.bounds_width / 2)
			g_log.syslog("TP: "..vec2_str(target.pos).." LB: "..left_bound.." RB: "..right_bound)

			if target.pos.x < left_bound then
				self.pos.x -= (left_bound - target.pos.x)
			elseif target.pos.x + 8 > right_bound then
				self.pos.x += (target.pos.x + 8 - right_bound)
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

-- Animated sprite controller
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

-- Physics
g_physics = {
	gravity = nil,
}

g_physics.init = function(self, gravity)
	self.gravity = gravity
end


-- 2d Vector
local vec2_meta = {}
function vec2_meta.__add(a, b)
	return mk_vec2(a.x + b.x, a.y + b.y)
end

function vec2_meta.__sub(a, b)
	return mk_vec2(a.x - b.x, a.y - b.y)
end

function vec2_meta.__mul(a, b)
	if type(a) == "number" then
		return mk_vec2(a * b.x, a * b.y)
	elseif type(b) == "number" then
		return mk_vec2(b * a.x, b * a.y)
	else
		return mk_vec2(a.x * b.x, a.y * b.y)
	end
end

function vec2_meta.__div(a, b) 
	mk_vec2(a.x / b, a.y / b)
end

function vec2_meta.__eq(a, b) 
	return a.x == b.x and a.y == b.y
end

function mk_vec2(x, y) 
	local v = {
		x = x,
		y = y,
	}
	setmetatable(v, vec2_meta)
	return v;
end

function clone_vec2(v) 
	return mk_vec2(v.x, v.y)
end

function vec2_magnitude(v)
	return sqrt(v.x ^ 2 + v.y ^ 2)
end

function vec2_normalized(v) 
	local mag = vec2_magnitude(v)
	return mk_vec2(v.x / mag, v.y / mag)
end

function vec2_str(v)
	return "("..v.x..", "..v.y..")"
end

-- Logger
g_log = {
	show_debug = false,
	log_data = {}
}

-- Logs a message
g_log.log = function(message)
	add(g_log.log_data, message)
end

g_log.syslog = function(message)
	printh(message, 'debug.log')
end

-- Renders the log
g_log.render = function()
	if (g_log.show_debug) then
		color(7)
		for i = 1, #g_log.log_data do
			print(g_log.log_data[i], 0, 5 + 5 * i)
		end
	end
end

-- Clears the log
g_log.clear = function()
	g_log.log_data = {}
end

-- Global init function.
function _init()
	g_game = mk_game(g_levels)
	g_game.init(g_game)

	set_game_state(main_menu_state)
end

-- Global update function
function _update()
	if g_state ~= nil then
		g_state.update(g_state)
	end
	
	g_log.log("Mem: "..stat(0).." CPU: "..stat(1))
end

-- Global draw function
function _draw()
	cls()

	if g_state ~= nil then
		g_state.draw(g_state)
	end

	-- Draw debug log
	g_log.render()
	g_log.clear()
end