-- Main systems module: aggregates all system modules
local PhysicsCore = require("src/physics")        -- Aggregator for collision, etc.
local PhysicsSys = require("src/systems/physics") -- Acceleration, Velocity
local Shooter = require("src/systems/shooter")
local Timers = require("src/systems/timers")
local HealthRegen = require("src/systems/health_regen")
local AISys = require("src/systems/ai")
local Rendering = require("src/systems/rendering")
local Effects = require("src/systems/effects")
local Animation = require("src/systems/animation")
local LocalInput = require("src/systems/input")
local Spawner = require("src/systems/spawner")
local Lifecycle = require("src/lifecycle") -- Aggregator for lifecycle & death handlers

-- Merge all modules into a single Systems table for backward compatibility
local Systems = {}

-- Collision systems (from PhysicsCore aggregator)
Systems.CollisionHandlers = PhysicsCore.Handlers
Systems.resolve_entities = PhysicsCore.resolve_entities
Systems.resolve_map = PhysicsCore.resolve_map

-- Physics systems (from PhysicsSys)
Systems.read_input = LocalInput.read_input
Systems.acceleration = PhysicsSys.acceleration
Systems.velocity = PhysicsSys.velocity

-- Shooting & Health systems (abstracted)
Systems.shooter = Shooter.update
Systems.health_regen = HealthRegen.update
Systems.timers = Timers.update

-- AI systems
Systems.ai = AISys.update

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
Systems.draw_doors = Rendering.draw_doors

-- Lifecycle systems (using Lifecycle aggregator)
Systems.init_lifecycle = Lifecycle.init
Systems.update_lifecycle = Lifecycle.update

-- Animation systems (sprite updates only)
Systems.animate = Animation.animate

-- Effects systems
Systems.Effects = Effects

-- Spawner system
Systems.Spawner = Spawner

return Systems
