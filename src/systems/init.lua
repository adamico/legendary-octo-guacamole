-- Main systems module: aggregates all system modules
local Collision = require("collision")
local Physics = require("physics")
local Combat = require("combat")
local AI = require("ai")
local Rendering = require("rendering")
local Effects = require("effects")
local Animation = require("animation")
local LocalInput = require("input")
local Spawner = require("spawner")


-- Merge all modules into a single Systems table for backward compatibility
local Systems = {}

-- Collision systems
Systems.CollisionHandlers = Collision.CollisionHandlers
Systems.resolve_entities = Collision.resolve_entities
Systems.resolve_map = Collision.resolve_map
Systems.check_overlap = Collision.check_overlap
Systems.is_solid = Collision.is_solid

-- Physics systems
Systems.read_input = LocalInput.read_input
Systems.acceleration = Physics.acceleration
Systems.velocity = Physics.velocity

-- Combat systems
Systems.projectile_fire = Combat.projectile_fire
Systems.health_manager = Combat.health_manager
Systems.health_regen = Combat.health_regen
Systems.invulnerability_tick = Combat.invulnerability_tick
Systems.DeathHandlers = Combat.DeathHandlers

-- AI systems
Systems.enemy_ai = AI.enemy_ai

-- Rendering systems
Systems.init_extended_palette = Rendering.init_extended_palette
Systems.init_spotlight = Rendering.init_spotlight
Systems.reset_spotlight = Rendering.reset_spotlight
Systems.change_sprite = Rendering.change_sprite
Systems.animatable = Rendering.animatable
Systems.draw_layer = Rendering.draw_layer
Systems.sync_shadows = Rendering.sync_shadows
Systems.draw_shadow_entity = Rendering.draw_shadow_entity
Systems.draw_spotlight = Rendering.draw_spotlight
Systems.draw_health_bar = Rendering.draw_health_bar
Systems.draw_hitbox = Rendering.draw_hitbox
Systems.palette_swappable = Rendering.palette_swappable


-- Animation FSM systems
Systems.update_fsm = Animation.update_fsm
Systems.animate = Animation.animate

-- Effects systems
Systems.Effects = Effects

-- Spawner system
Systems.Spawner = Spawner

return Systems
