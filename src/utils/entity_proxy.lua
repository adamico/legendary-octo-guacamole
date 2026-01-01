--- @class EntityProxy
--- @field _world ECSWorld
--- @field _id EntityID
--- @field x number
--- @field y number
--- @field z number
--- @field width number
--- @field height number
--- @field vel_x number
--- @field vel_y number
--- @field vel_z number
--- @field accel number
--- @field friction number
--- @field max_speed number
--- @field gravity_z number
--- @field dir_x number
--- @field dir_y number
--- @field facing number
--- @field invuln_timer number
--- @field shoot_cooldown number
--- @field melee_cooldown number
--- @field hp_drain_timer number
--- @field stun_timer number
--- @field slow_timer number
--- @field lifespan number
--- @field slow_factor number
--- @field hp number
--- @field max_hp number
--- @field overflow_hp number
--- @field knockback_vel_x number
--- @field knockback_vel_y number
--- @field damage number
--- @field type string
--- @field projectile_type string
--- @field enemy_type string
--- @field minion_type string
--- @field path_state table
--- @field fsm any
--- @field dasher_fsm any
--- @field chick_fsm any
--- @field patrol_dir_x number
--- @field patrol_dir_y number
--- @field hit_wall boolean
--- @field dash_target_dx number
--- @field dash_target_dy number
--- @field current_direction string
--- @field dasher_timer number
--- @field rotation_angle number
--- @field rotation_timer number
--- @field puzzled_timer number
--- @field windup_duration number
--- @field vision_range number
--- @field dash_speed_multiplier number
--- @field stun_duration number
--- @field dasher_collision any
--- @field attack_timer number
--- @field bonuses_applied boolean
--- @field attachment_timer number
--- @field attachment_target EntityProxy|nil
--- @field attack_range number
--- @field chase_target EntityProxy|nil
--- @field follow_trigger_dist number
--- @field follow_stop_dist number
--- @field emotion string
--- @field food_seek_range number
--- @field food_heal_amount number
--- @field seeking_follow_active boolean
--- @field follow_speed_mult number
--- @field chase_speed_mult number
--- @field chase_stuck_frames number
--- @field unreachable_blacklist table
--- @field minion_vision_bonus number
--- @field minion_damage_bonus number
--- @field attack_damage number
--- @field attack_knockback number
--- @field attack_cooldown number
--- @field minion_cooldown_reduction number
--- @field minion_hp_bonus number
--- @field outline_color number
--- @field owner EntityID
--- @field map_collidable boolean
--- @field hitboxes table
--- @field player boolean
--- @field enemy boolean
--- @field projectile boolean
--- @field pickup boolean
--- @field obstacle boolean
--- @field minion boolean
--- @field background boolean
--- @field chest boolean
--- @field controllable boolean
--- @field destructible boolean
--- @field emotional boolean
--- @field flying boolean
--- @field locked boolean
--- @field middleground boolean
--- @field shop_item boolean
--- @field skull boolean
--- @field sprite boolean
--- @field static boolean
--- @field world_obj boolean
--- @field yolk_splat boolean
--- @field melee_hitbox boolean
--- @field bomb_cooldown number Transient field for bomber system cooldown
--- @field explosion_radius number Transient field for bomber system explosion radius
--- @field is_chest boolean Transient field for chest system
--- @field purchased boolean Transient field for shop system
--- @field price number Transient field for shop system
--- @field item_name string Transient field for shop system
--- @field emotion_timer number Transient field for emotions system
--- @field emotion_phase number Transient field for emotions system
--- @field impact_damage number Shooter component field
--- @field shot_speed number Shooter component field
--- @field range number Shooter component field
--- @field fire_rate number Shooter component field
--- @field coins number Inventory component field
--- @field keys number Inventory component field
--- @field bombs number Inventory component field
--- @field level number XP component field
--- @field xp number XP component field
--- @field xp_to_next_level number XP component field
--- @field item_id string Shop data field
--- @field apply_fn function Shop data field
--- @field room_key string Map position field
--- @field tile_x number Map position field
--- @field tile_y number Map position field
--- @field sub_x number Movement field
--- @field sub_y number Movement field
--- @field sub_z number Movement field
--- @field ignore_map_collision boolean Flag
--- @field height_z number Z-vertical field
local EntityProxy = {}
EntityProxy.__index = EntityProxy

-- Mapping from legacy property names to {component, field}
local ComponentMap = {
   -- Transform
   x = {"position", "x"},
   y = {"position", "y"},
   z = {"position", "z"},
   width = {"size", "width"},
   height = {"size", "height"},

   -- Movement
   vel_x = {"velocity", "vel_x"},
   vel_y = {"velocity", "vel_y"},
   vel_z = {"velocity", "vel_z"},
   accel = {"acceleration", "accel"},
   friction = {"acceleration", "friction"},
   max_speed = {"acceleration", "max_speed"},
   gravity_z = {"acceleration", "gravity_z"},

   -- Direction
   dir_x = {"direction", "dir_x"},
   dir_y = {"direction", "dir_y"},
   facing = {"direction", "facing"},

   -- Timers
   invuln_timer = {"timers", "invuln_timer"},
   shoot_cooldown = {"timers", "shoot_cooldown"},
   melee_cooldown = {"timers", "melee_cooldown"},
   hp_drain_timer = {"timers", "hp_drain_timer"},
   stun_timer = {"timers", "stun_timer"},
   slow_timer = {"timers", "slow_timer"},
   lifespan = {"timers", "lifespan"},
   slow_factor = {"timers", "slow_factor"},

   -- Health
   hp = {"health", "hp"},
   max_hp = {"health", "max_hp"},
   overflow_hp = {"health", "overflow_hp"},

   -- Combat
   knockback_vel_x = {"velocity", "knockback_vel_x"},
   knockback_vel_y = {"velocity", "knockback_vel_y"},

   -- Projectile specific
   damage = {"projectile_combat", "damage"}, -- Warning: ambiguous

   -- Shooter
   impact_damage = {"shooter", "impact_damage"},
   shot_speed = {"shooter", "shot_speed"},
   range = {"shooter", "range"},
   fire_rate = {"shooter", "fire_rate"},

   -- Inventory
   coins = {"inventory", "coins"},
   keys = {"inventory", "keys"},
   bombs = {"inventory", "bombs"},

   -- XP
   level = {"xp", "level"},
   xp = {"xp", "xp"},
   xp_to_next_level = {"xp", "xp_to_next_level"},

   -- Type
   type = {"type", "value"},
   projectile_type = {"projectile_type", "value"},
   enemy_type = {"enemy_type", "value"},
   minion_type = {"minion_type", "value"},

   -- AI
   path_state = {"path_state", "value"},


   -- Owners
   owner = {"projectile_owner", "owner"},

   -- Flags
   map_collidable = {"collidable", "map_collidable"},
   obstacle_type = {"obstacle_type", "value"},
   room_key = {"room_key", "value"},

   -- Shop Data
   item_id = {"shop_data", "item_id"},
   price = {"shop_data", "price"},
   item_name = {"shop_data", "item_name"},
   apply_fn = {"shop_data", "apply_fn"},

   -- Map Position
   tile_x = {"map_pos", "tx"},
   tile_y = {"map_pos", "ty"},
}

-- Mapping for boolean flags (checking existence of component)
local TagMap = {
   -- map_collidable moved to ComponentMap (it's a field)
   -- No, collidable is a component.
   -- If we treat tags as boolean components:
   player = "player",
   enemy = "enemy",
   projectile = "projectile",
   pickup = "pickup",
   obstacle = "obstacle",
   minion = "minion",
   background = "background",
   chest = "chest",
   controllable = "controllable",
   destructible = "destructible",
   emotional = "emotional",
   flying = "flying",
   locked = "locked",
   middleground = "middleground",
   shop_item = "shop_item",
   skull = "skull",
   sprite = "sprite",
   static = "static",
   world_obj = "world_obj",
   yolk_splat = "yolk_splat",
   melee_hitbox = "melee_hitbox",
}

--- @param world ECSWorld
--- @param id EntityID
--- @return EntityProxy
function EntityProxy.new(world, id)
   local proxy = {
      _world = world,
      _id = id
   }
   setmetatable(proxy, EntityProxy)
   return proxy
end

function EntityProxy:__index(key)
   -- 1. Check direct proxy fields (like _id, _world)
   -- (Handled by raw access normally, but __index catches missing ones)

   -- 2. Check Component Map
   local map = ComponentMap[key]
   if map then
      local comp_name, field_name = map[1], map[2]
      local archetype = self._world._id_to_archetype[self._id]
      if not archetype then return nil end -- Entity dead?

      local buffer = archetype._buffers[comp_name]
      if buffer then
         local index = archetype._id_to_index[self._id]
         return buffer.field_buffers[field_name][index]
      end
      return nil
   end

   -- 3. Check Tag Map
   local tag_comp = TagMap[key]
   if tag_comp then
      -- Special case: map_collidable check logic?
      -- No, just check if simple tag component exists
      local archetype = self._world._id_to_archetype[self._id]
      if not archetype then return false end
      return archetype._buffers[tag_comp] ~= nil
   end

   -- 4. Special overrides
   if key == "id" then return self._id end
   if key == "hitboxes" then
      -- Return value from collidable.hitboxes
      local archetype = self._world._id_to_archetype[self._id]
      if not archetype then return nil end
      local buffer = archetype._buffers["collidable"]
      if buffer then
         local index = archetype._id_to_index[self._id]
         return buffer.field_buffers["hitboxes"][index]
      end
   end

   return nil
end

function EntityProxy:__newindex(key, value)
   -- 1. Check Component Map
   local map = ComponentMap[key]
   if map then
      local comp_name, field_name = map[1], map[2]
      local archetype = self._world._id_to_archetype[self._id]
      if not archetype then return end

      local buffer = archetype._buffers[comp_name]
      if buffer then
         local index = archetype._id_to_index[self._id]
         buffer.field_buffers[field_name][index] = value
         return
      end
      -- If component missing, do we add it? No, schema is fixed usually.
      -- Just ignore or error? Ignore for now to mimic loose lua tables.
      return
   end

   -- 2. Check Tag Map
   local tag_comp = TagMap[key]
   if tag_comp then
      if value then
         self._world:add_components(self._id, {[tag_comp] = true})
      else
         self._world:remove_components(self._id, {tag_comp})
      end
      return
   end

   -- 3. Allow setting custom transient fields on the proxy table itself
   -- (This allows things like `entity.hit_obstacle = true` to work within the scope of the proxy usage)
   rawset(self, key, value)
end

return EntityProxy
