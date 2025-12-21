-- Main systems module: aggregates all system modules
local Collision = require("collision")
local Physics = require("physics")
local Combat = require("combat")
local AI = require("ai")
local Rendering = require("rendering")
local Effects = require("effects")
local Animation = require("animation")


-- Merge all modules into a single Systems table for backward compatibility
local Systems = {}

-- Collision systems
Systems.CollisionHandlers = Collision.CollisionHandlers
Systems.resolve_entity_collisions = Collision.resolve_entity_collisions
Systems.resolve_map_collisions = Collision.resolve_map_collisions
Systems.entity_collision = Collision.entity_collision
Systems.is_solid = Collision.is_solid

-- Physics systems
Systems.controllable = Physics.controllable
Systems.acceleration = Physics.acceleration
Systems.velocity = Physics.velocity

-- Combat systems
Systems.shooter = Combat.shooter
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
Systems.drawable = Rendering.drawable
Systems.draw_shadow = Rendering.draw_shadow
Systems.draw_spotlight = Rendering.draw_spotlight
Systems.draw_health_bar = Rendering.draw_health_bar
Systems.SPOTLIGHT_COLOR = Rendering.SPOTLIGHT_COLOR
Systems.SHADOW_COLOR = Rendering.SHADOW_COLOR

-- Animation FSM systems
Systems.update_fsm = Animation.update_fsm
Systems.animate = Animation.animate

-- Effects systems
Systems.Effects = Effects

return Systems
