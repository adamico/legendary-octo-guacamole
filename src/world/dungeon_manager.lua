local Room = require("src/world/room")
local Events = require("src/game/events")
local RoomLayouts = require("src/world/room_layouts")
local FloorPatterns = require("src/world/floor_patterns")
local WavePatterns = require("src/world/wave_patterns")
local ShopItems = require("src/game/config/shop_items")

-- Constants for procedural generation
local ROOM_TILES_W = 29 -- Fixed room width in tiles
local ROOM_TILES_H = 16 -- Fixed room height in tiles (256px fits in 270px screen)
local MIN_ENEMIES_PER_ROOM = 2
local MAX_ENEMIES_PER_ROOM = 5
local ENEMY_DENSITY_DIVISOR = 100      -- Tiles per enemy
local DEFAULT_ENEMY_MIN_DIST = 80      -- Minimum pixels from player
local MAP_MEMORY_ADDRESS = 0x100000    -- Picotron Extended Map Address
local EXT_MAP_W = 256                  -- Large static world map
local EXT_MAP_H = 256                  -- Large static world map
local GRID_STRIDE_X = ROOM_TILES_W - 1 -- Rooms overlap by 1 tile (shared wall)
local GRID_STRIDE_Y = ROOM_TILES_H - 1 -- Rooms overlap by 1 tile (shared wall)
local BASE_OFFSET_X = 128              -- Center offset for grid 0,0 (enough for ~4 rooms in each direction)
local BASE_OFFSET_Y = 128              -- Center offset for grid 0,0 (enough for ~4 rooms in each direction)
local TARGET_ROOM_COUNT = 12
local DIRECTIONS = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}

local DungeonManager = {}

DungeonManager.current_room = nil
DungeonManager.rooms = {} -- Hash map: "x,y" -> Room
DungeonManager.map_data = nil

-- Helper: Count neighbors at a grid position
function DungeonManager.count_neighbors(gx, gy)
   local count = 0
   for _, d in ipairs(DIRECTIONS) do
      if DungeonManager.rooms[(gx + d[1])..","..(gy + d[2])] then
         count += 1
      end
   end
   return count
end

-- Helper: Check if a room has no valid expansion directions
function DungeonManager.is_surrounded(gx, gy)
   return DungeonManager.count_neighbors(gx, gy) >= 4
      or DungeonManager.count_valid_expansion_dirs(gx, gy) == 0
end

-- Helper: Count directions where a new room could be placed (Rule of One)
function DungeonManager.count_valid_expansion_dirs(gx, gy)
   local count = 0
   for _, d in ipairs(DIRECTIONS) do
      local nx, ny = gx + d[1], gy + d[2]
      local key = nx..","..ny
      if not DungeonManager.rooms[key] and DungeonManager.count_neighbors(nx, ny) == 1 then
         count += 1
      end
   end
   return count
end

-- Helper: Get all rooms as a list
function DungeonManager.get_all_rooms()
   local list = {}
   for _, r in pairs(DungeonManager.rooms) do add(list, r) end
   return list
end

function DungeonManager.generate()
   DungeonManager.rooms = {}
   local active_list = {}

   -- Phase 1: Create Start Room at 0,0 (Safe Zone)
   local start_room = DungeonManager.create_room(0, 0, true)
   start_room.room_type = "start"
   DungeonManager.rooms["0,0"] = start_room
   add(active_list, start_room)

   -- Phase 2: Expansion Loop (Random Walk with Rule of One)
   while #DungeonManager.get_all_rooms() < TARGET_ROOM_COUNT and #active_list > 0 do
      -- Pick random room from active list
      local parent = active_list[flr(rnd(#active_list)) + 1]

      -- Pick random direction from constant
      local dir = DIRECTIONS[flr(rnd(#DIRECTIONS)) + 1]
      local nx, ny = parent.grid_x + dir[1], parent.grid_y + dir[2]
      local key = nx..","..ny

      -- Check: empty AND only 1 neighbor (Rule of One prevents 2x2 clusters)
      if not DungeonManager.rooms[key] then
         local neighbors = DungeonManager.count_neighbors(nx, ny)
         if neighbors == 1 then
            local new_room = DungeonManager.create_room(nx, ny, false)
            DungeonManager.rooms[key] = new_room
            add(active_list, new_room)
         end
      end

      -- Remove exhausted rooms (no valid expansion directions left)
      if DungeonManager.is_surrounded(parent.grid_x, parent.grid_y) then
         del(active_list, parent)
      end
   end

   -- Phase 3: Specialization (assign room types based on distance/topology)
   DungeonManager.assign_room_types()

   -- Phase 4: Connection (Connect Neighbor Rooms with corridor)
   DungeonManager.connect_neighbor_rooms()

   -- Phase 5: Carve entire dungeon into map
   DungeonManager.fill_map_with_walls() -- Fill entire map with walls first
   -- Carve floors for all rooms (pure floor tiles for autotiling)
   for _, room in pairs(DungeonManager.rooms) do
      DungeonManager.carve_room_floor(room)
   end

   -- Phase 6: Apply autotiling to walls (corners, H/V variants)
   DungeonManager.autotile_walls()

   -- Phase 7: Place obstacles (rocks, pits) AFTER autotiling
   for _, room in pairs(DungeonManager.rooms) do
      DungeonManager.place_room_obstacles(room)
   end

   -- Phase 8: Carve corridors (opens door passages with frame tiles)
   for _, room in pairs(DungeonManager.rooms) do
      DungeonManager.carve_corridors(room)
   end

   -- Set initial state
   DungeonManager.current_room = start_room

   Log.info("Generated dungeon with "..#DungeonManager.get_all_rooms().." rooms")
end

function DungeonManager.create_room(gx, gy, is_safe)
   -- Fixed room dimensions (Isaac style - fills screen)
   local w = ROOM_TILES_W
   local h = ROOM_TILES_H

   -- Grid-based absolute position (rooms directly adjacent)
   local world_tx = BASE_OFFSET_X + (gx * GRID_STRIDE_X)
   local world_ty = BASE_OFFSET_Y + (gy * GRID_STRIDE_Y)

   local room = Room:new(world_tx, world_ty, w, h, is_safe)

   -- Initialize room metadata
   room.grid_x = gx
   room.grid_y = gy

   return room
end

function DungeonManager.apply_door_sprites(room)
   if not room.doors then return end

   for dir, door in pairs(room.doors) do
      local pos = room:get_door_tile(dir)
      if pos then
         mset(pos.tx, pos.ty, door.sprite)
      end
   end
end

function DungeonManager.carve_corridors(room)
   if not room.doors then return end

   for dir, door in pairs(room.doors) do
      -- Get door position in current room
      local pos = room:get_door_tile(dir)
      if pos then
         -- Set door tile to EMPTY_TILE (transparent) - actual door sprite drawn by rendering
         mset(pos.tx, pos.ty, EMPTY_TILE)

         -- Place door frame tiles based on direction
         if dir == "north" or dir == "south" then
            -- North/South door: frame on left and right
            local left_tile = DOOR_FRAME_V_LEFT[flr(rnd(#DOOR_FRAME_V_LEFT)) + 1]
            local right_tile = DOOR_FRAME_V_RIGHT[flr(rnd(#DOOR_FRAME_V_RIGHT)) + 1]
            mset(pos.tx - 1, pos.ty, left_tile)
            mset(pos.tx + 1, pos.ty, right_tile)
         else
            -- East/West door: frame on top and bottom
            local top_tile = DOOR_FRAME_H_TOP[flr(rnd(#DOOR_FRAME_H_TOP)) + 1]
            local bottom_tile = DOOR_FRAME_H_BOTTOM[flr(rnd(#DOOR_FRAME_H_BOTTOM)) + 1]
            mset(pos.tx, pos.ty - 1, top_tile)
            mset(pos.tx, pos.ty + 1, bottom_tile)
         end
      end
   end
end

-- Phase 1: Carve pure floor tiles (called before autotiling)
function DungeonManager.carve_room_floor(room)
   -- Select and assign layout for this room
   local layout = RoomLayouts.get_random_layout(room.room_type or "combat", room)
   room.layout = layout
   room.destructibles = {} -- Store positions for destructible entity spawning

   local floor = room:get_inner_bounds()

   local pattern = FloorPatterns.get_pattern(layout.floor_pattern or "random")

   -- First pass: carve all as floor tiles (for proper autotiling)
   for ty = floor.y1, floor.y2 do
      for tx = floor.x1, floor.x2 do
         local floor_tile = pattern(tx, ty, FLOOR_TILES)
         mset(tx, ty, floor_tile)
      end
   end
end

-- Phase 2: Place map-based obstacles (e.g. pits) and pre-generate obstacle data
function DungeonManager.place_room_obstacles(room)
   if not room.layout or not room.layout.grid then return end

   local floor_rect = room:get_inner_bounds()

   -- Use get_all_features for precise cell_pattern placement
   local features = RoomLayouts.get_all_features(room.layout, floor_rect.x1, floor_rect.y1)

   -- Pre-generate obstacle data with deterministic sprite selection (while RNG is seeded)
   room.obstacle_data = {}

   -- For shop rooms, pre-select which items will be sold
   local shop_items_selected = nil
   if room.room_type == "shop" then
      -- Count how many shop_item features are in the layout
      local shop_count = 0
      for _, f in ipairs(features) do
         if f.feature == "shop_item" then shop_count += 1 end
      end
      shop_items_selected = ShopItems.pick_random_items(shop_count)
   end
   local shop_item_index = 1

   for _, f in ipairs(features) do
      if f.feature == "pit" then
         mset(f.tx, f.ty, PIT_TILE)
      elseif f.feature == "rock" then
         -- Pre-select sprite during generation for seed determinism
         local sprite = ROCK_TILES[flr(rnd(#ROCK_TILES)) + 1]
         add(room.obstacle_data, {feature = "rock", tx = f.tx, ty = f.ty, sprite = sprite})
      elseif f.feature == "destructible" then
         -- Pre-select sprite during generation for seed determinism
         local sprite = DESTRUCTIBLE_TILES[flr(rnd(#DESTRUCTIBLE_TILES)) + 1]
         add(room.obstacle_data, {feature = "destructible", tx = f.tx, ty = f.ty, sprite = sprite})
      elseif f.feature == "chest" then
         -- Normal chest - sprite is fixed
         add(room.obstacle_data, {feature = "chest", tx = f.tx, ty = f.ty, sprite = CHEST_TILE})
      elseif f.feature == "locked_chest" then
         -- Locked chest - sprite is fixed
         add(room.obstacle_data, {feature = "locked_chest", tx = f.tx, ty = f.ty, sprite = LOCKED_CHEST_TILE})
      elseif f.feature == "shop_item" and shop_items_selected then
         -- Shop item pedestal - store item data for spawning
         local item = shop_items_selected[shop_item_index]
         if item then
            add(room.obstacle_data, {
               feature = "shop_item",
               tx = f.tx,
               ty = f.ty,
               sprite = 58, -- Pedestal base sprite
               item_id = item.id,
               item_name = item.name,
               item_sprite = item.sprite,
               price = item.price,
               apply_fn = item.apply
            })
            shop_item_index += 1
         end
      end
   end

   DungeonManager.apply_door_sprites(room)
end

function DungeonManager.assign_enemies(room, num_enemies, min_dist, types)
   local area = room.tiles.w * room.tiles.h
   local default_count = mid(MIN_ENEMIES_PER_ROOM, flr(area / ENEMY_DENSITY_DIVISOR), MAX_ENEMIES_PER_ROOM)

   room.contents_config = room.contents_config or {}
   room.contents_config.enemies = {
      count = num_enemies or default_count,
      min_dist = min_dist or DEFAULT_ENEMY_MIN_DIST,
      types = types
   }
end

-- Phase 3: Assign room types based on distance and topology
function DungeonManager.assign_room_types()
   -- Calculate Manhattan distance from origin for each room
   for _, room in pairs(DungeonManager.rooms) do
      room.distance = abs(room.grid_x) + abs(room.grid_y)
   end

   -- Find leaf nodes (1 neighbor only, excluding start)
   local leaves = {}
   for _, room in pairs(DungeonManager.rooms) do
      if room.room_type ~= "start" then
         local neighbors = DungeonManager.count_neighbors(room.grid_x, room.grid_y)
         if neighbors == 1 then
            add(leaves, room)
         end
      end
   end

   -- Sort leaves by distance (descending) - farthest first
   for i = 1, #leaves - 1 do
      for j = i + 1, #leaves do
         if leaves[j].distance > leaves[i].distance then
            leaves[i], leaves[j] = leaves[j], leaves[i]
         end
      end
   end

   -- Assign special types: farthest = boss, next = treasure, next = shop
   if #leaves >= 1 then
      leaves[1].room_type = "boss"
   end
   if #leaves >= 2 then
      leaves[2].room_type = "treasure"
   end
   if #leaves >= 3 then
      leaves[3].room_type = "shop"
   end

   -- Remaining rooms are combat rooms with wave patterns
   for _, room in pairs(DungeonManager.rooms) do
      if not room.room_type then
         room.room_type = "combat"
         -- Difficulty scales with distance: 1-2 = easy, 3-4 = medium, 5+ = hard
         local difficulty = min(3, flr(room.distance / 2) + 1)
         local pattern = WavePatterns.get_random_pattern(difficulty)
         room.contents_config = {wave_pattern = pattern}
      end
   end
end

-- Phase 4: Connect neighbor rooms and setup corridors
function DungeonManager.connect_neighbor_rooms()
   local door_dirs = {
      {dx = 1,  dy = 0,  from = "east",  to = "west"},
      {dx = -1, dy = 0,  from = "west",  to = "east"},
      {dx = 0,  dy = -1, from = "north", to = "south"},
      {dx = 0,  dy = 1,  from = "south", to = "north"}
   }

   for _, room in pairs(DungeonManager.rooms) do
      room.doors = room.doors or {}
      for _, d in ipairs(door_dirs) do
         local neighbor_key = (room.grid_x + d.dx)..","..(room.grid_y + d.dy)
         if DungeonManager.rooms[neighbor_key] then
            room.doors[d.from] = {
               sprite = DOOR_OPEN_TILE,
               target_gx = room.grid_x + d.dx,
               target_gy = room.grid_y + d.dy
            }
         end
      end
   end
end

function DungeonManager.fill_map_with_walls()
   for ty = 0, EXT_MAP_H - 1 do
      for tx = 0, EXT_MAP_W - 1 do
         mset(tx, ty, WALL_TILE)
      end
   end
end

function DungeonManager.is_floor_tile(tx, ty)
   local tile = mget(tx, ty)
   if tile == 0 then return true end
   for _, f in ipairs(FLOOR_TILES) do
      if tile == f then return true end
   end
   return false
end

function DungeonManager.autotile_walls()
   local tiles_to_check = {}
   local visited = {}

   for _, room in pairs(DungeonManager.rooms) do
      local floor = room:get_inner_bounds()
      -- Check the wall ring around the floor (1 tile margin on all sides)
      local x1, y1 = floor.x1 - 1, floor.y1 - 1
      local x2, y2 = floor.x2 + 1, floor.y2 + 1

      for ty = y1, y2 do
         for tx = x1, x2 do
            -- Only add wall tiles (skip interior floor tiles)
            local is_interior = tx >= floor.x1 and tx <= floor.x2 and ty >= floor.y1 and ty <= floor.y2
            if not is_interior then
               local key = tx..","..ty
               if not visited[key] then
                  visited[key] = true
                  add(tiles_to_check, {tx = tx, ty = ty})
               end
            end
         end
      end
   end

   -- Bitmask lookup: TL=1, TR=2, BL=4, BR=8
   local CORNER_TILES = {
      [1]  = WALL_TILE_CORNER_BR,    -- TL only: outer corner
      [2]  = WALL_TILE_CORNER_BL,    -- TR only: outer corner
      [4]  = WALL_TILE_CORNER_TR,    -- BL only: outer corner
      [8]  = WALL_TILE_CORNER_TL,    -- BR only: outer corner
      [3]  = WALL_TILE_INNER_TOP,    -- TL+TR: inner top
      [12] = WALL_TILE_INNER_BOTTOM, -- BL+BR: inner bottom
      [10] = WALL_TILE_INNER_RIGHT,  -- TR+BR: inner right
      [5]  = WALL_TILE_INNER_LEFT,   -- TL+BL: inner left
   }

   for _, tile in ipairs(tiles_to_check) do
      local tx, ty = tile.tx, tile.ty
      if DungeonManager.is_floor_tile(tx, ty) then goto continue end

      local floor_above = DungeonManager.is_floor_tile(tx, ty - 1)
      local floor_below = DungeonManager.is_floor_tile(tx, ty + 1)
      local floor_left  = DungeonManager.is_floor_tile(tx - 1, ty)
      local floor_right = DungeonManager.is_floor_tile(tx + 1, ty)

      local new_tile    = nil

      if floor_above or floor_below or floor_left or floor_right then
         if floor_above or floor_below then
            new_tile = WALL_TILE_HORIZONTAL[flr(rnd(#WALL_TILE_HORIZONTAL)) + 1]
         else
            new_tile = WALL_TILE_VERTICAL[flr(rnd(#WALL_TILE_VERTICAL)) + 1]
         end
      else
         -- No orthogonal floors: check diagonals with bitmask
         local diag_mask = 0
         if DungeonManager.is_floor_tile(tx - 1, ty - 1) then diag_mask += 1 end -- TL
         if DungeonManager.is_floor_tile(tx + 1, ty - 1) then diag_mask += 2 end -- TR
         if DungeonManager.is_floor_tile(tx - 1, ty + 1) then diag_mask += 4 end -- BL
         if DungeonManager.is_floor_tile(tx + 1, ty + 1) then diag_mask += 8 end -- BR
         new_tile = CORNER_TILES[diag_mask]
      end

      if new_tile then
         mset(tx, ty, new_tile)
      end

      ::continue::
   end
end

--- Setup a room upon entry (spawning, lifecycle transitions, skull timer)
-- @param room The room to setup
-- @param player The player entity (for spawn distance calculations)
-- @param world The ECS world instance
function DungeonManager.setup_room(room, player, world)
   local Systems = require("src/systems")

   -- Log room entry with wave pattern info
   if room.contents_config and room.contents_config.wave_pattern then
      local pattern = room.contents_config.wave_pattern
      Log.info("Entering room ("..room.grid_x..","..room.grid_y..")")
      Log.info("wave pattern="..pattern.name)
      Log.info("Room layout="..room.layout.name)
   end

   Systems.Spawner.populate(room, player)

   -- Spawn obstacles (Rocks, Destructibles, Chests, ShopItems) if not already spawned
   -- Uses pre-generated obstacle_data from dungeon generation for seed determinism
   if not room.obstacles_spawned and room.obstacle_data then
      local Entities = require("src/entities")
      local rocks_count = 0
      local dest_count = 0
      local chest_count = 0
      local locked_chest_count = 0
      local shop_item_count = 0

      -- Initialize obstacle entity tracking for this room
      room.obstacle_entities = room.obstacle_entities or {}

      for _, f in ipairs(room.obstacle_data) do
         -- Base position: tile coords to pixels
         -- Rocks/Destructibles have hitbox_offset=4, so we offset by -4 to align hitbox with tile
         -- Chests/ShopItems have custom offsets, no adjustment needed
         local wx, wy
         if f.feature == "chest" or f.feature == "locked_chest" or f.feature == "shop_item" then
            wx, wy = f.tx * GRID_SIZE, f.ty * GRID_SIZE
         else
            wx, wy = f.tx * GRID_SIZE - 4, f.ty * GRID_SIZE - 4
         end
         local entity = nil
         if f.feature == "rock" then
            entity = Entities.spawn_obstacle(world, wx, wy, "Rock", f.sprite)
            rocks_count += 1
         elseif f.feature == "destructible" then
            entity = Entities.spawn_obstacle(world, wx, wy, "Destructible", f.sprite)
            dest_count += 1
         elseif f.feature == "chest" then
            entity = Entities.spawn_obstacle(world, wx, wy, "Chest", f.sprite)
            chest_count += 1
         elseif f.feature == "locked_chest" then
            entity = Entities.spawn_obstacle(world, wx, wy, "LockedChest", f.sprite)
            locked_chest_count += 1
         elseif f.feature == "shop_item" then
            entity = Entities.spawn_obstacle(world, wx, wy, "ShopItem", f.item_sprite)
            -- Transfer shop item data from obstacle_data to entity
            entity.item_id = f.item_id
            entity.item_name = f.item_name
            entity.price = f.price
            entity.apply_fn = f.apply_fn
            shop_item_count += 1
         end
         if entity then
            entity.room_key = room.grid_x..","..room.grid_y
            add(room.obstacle_entities, entity)
         end
      end
      Log.info("Spawned obstacles in room ("..
         room.grid_x..","..room.grid_y.."): "..rocks_count.." rocks, "..dest_count..
         " destructibles, "..chest_count.." chests, "..locked_chest_count..
         " locked chests, "..shop_item_count.." shop items")
      room.obstacles_spawned = true
   end

   -- If enemies assigned and room is populated, trigger enter to lock doors
   if #room.enemy_positions > 0 and room.lifecycle:can("enter") then
      room.lifecycle:enter()
      DungeonManager.apply_door_sprites(room)
   end

   -- Restart skull timer if entering a cleared combat room
   if room.lifecycle:is("cleared") and room.room_type == "combat" then
      room.skull_timer = SKULL_SPAWN_TIMER
      room.skull_spawned = false
   end
end

--- Check if an active room has been cleared of enemies
-- @param room The room to check
-- @param world The ECS world instance
function DungeonManager.check_room_clear(room, world)
   if not room.lifecycle:is("active") then return end

   local enemy_count = 0
   room.combat_timer += 1
   world.sys("enemy", function(e)
      -- Exclude skulls from enemy count (pressure mechanic, not room enemies)
      if not e.dead and not world.msk(e).skull then
         enemy_count += 1
      end
   end)()

   if enemy_count == 0 then
      room.lifecycle:clear()
      DungeonManager.apply_door_sprites(room)

      -- Notify listeners via pub/sub (play.lua subscribes for player healing, etc.)
      Events.emit(Events.ROOM_CLEAR, room)
   end
end

function DungeonManager.init()
   DungeonManager.map_data = userdata("i16", EXT_MAP_W, EXT_MAP_H)
   memmap(DungeonManager.map_data, MAP_MEMORY_ADDRESS)
   DungeonManager.generate()
end

--- Find the nearest valid floor tile to a position
--- @param px number Pixel X
--- @param py number Pixel Y
--- @param room table|nil Optional room object to check layout features
--- @return number|nil, number|nil (New valid pixel coordinates, or nil if no valid tile found)
function DungeonManager.snap_to_nearest_floor(px, py, room)
   local cx = flr(px / GRID_SIZE)
   local cy = flr(py / GRID_SIZE)

   -- Check if current tile is valid
   if DungeonManager.is_valid_spawn_tile(cx, cy, room) then
      return px, py
   end

   -- Spiral search for nearest valid tile
   local radius = 1
   local max_radius = 5 -- Search up to 5 tiles away

   while radius <= max_radius do
      for dy = -radius, radius do
         for dx = -radius, radius do
            -- Only check the outer ring
            if abs(dx) == radius or abs(dy) == radius then
               local tx, ty = cx + dx, cy + dy
               if DungeonManager.is_valid_spawn_tile(tx, ty, room) then
                  -- Return center of the valid tile
                  return tx * GRID_SIZE + GRID_SIZE / 2 - 8, ty * GRID_SIZE + GRID_SIZE / 2 - 8
                  -- Note: -8 centers a 16x16 entity.
                  -- Ideally we'd know entity size, but centering on tile is a safe default.
               end
            end
         end
      end
      radius = radius + 1
   end

   return nil, nil -- Fallback: no valid tile found, let caller handle
end

--- Check if a tile is a valid spawn location (floor, no pit/obstacle, within room)
function DungeonManager.is_valid_spawn_tile(tx, ty, room)
   -- 1. Check map bounds
   if tx < 0 or tx >= EXT_MAP_W or ty < 0 or ty >= EXT_MAP_H then return false end

   -- 2. Check room inner bounds (must be provided for spawn checks)
   if room then
      local floor_rect = room:get_inner_bounds()
      if tx < floor_rect.x1 or tx > floor_rect.x2 or
         ty < floor_rect.y1 or ty > floor_rect.y2 then
         return false
      end
   end

   -- 3. Check if floor tile
   if not DungeonManager.is_floor_tile(tx, ty) then return false end

   -- 4. Check for map features (Pits)
   local tile = mget(tx, ty)
   if tile == PIT_TILE then return false end
   if fget(tile, FEATURE_FLAG_PIT) then return false end

   -- 5. Check for layout features (Rocks/Destructibles/Chests) if room provided
   if room and room.layout and room.layout.grid then
      local RoomLayouts = require("src/world/room_layouts")
      local floor_rect = room:get_inner_bounds()
      local room_w = floor_rect.x2 - floor_rect.x1 + 1
      local room_h = floor_rect.y2 - floor_rect.y1 + 1
      local gx = tx - floor_rect.x1
      local gy = ty - floor_rect.y1

      local feature = RoomLayouts.get_feature_at(room.layout, gx, gy, room_w, room_h)
      if feature == "rock" or feature == "destructible" or feature == "pit"
         or feature == "chest" or feature == "locked_chest" then
         return false
      end
   end

   return true
end

return DungeonManager
