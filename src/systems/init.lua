-- Main systems module: aggregates all system modules
local PhysicsCore = require("src/physics")        -- Aggregator for collision, etc.
local PhysicsSys = require("src/systems/physics") -- Acceleration, Velocity
local Shooter = require("src/systems/shooter")
local Timers = require("src/systems/timers")
local Melee = require("src/systems/melee")
local Bomber = require("src/systems/bomber")
local HealthRegen = require("src/systems/health_regen")
local AISys = require("src/systems/ai")
local Rendering = require("src/systems/rendering")
local Lighting = require("src/systems/lighting")
local Shadows = require("src/systems/shadows")
local UI = require("src/systems/ui")
local Effects = require("src/systems/effects")
local Animation = require("src/systems/animation")
local Input = require("src/input")
local Spawner = require("src/systems/spawner")
local Lifecycle = require("src/lifecycle")
local FloatingText = require("src/systems/floating_text")

-- Merge all modules into a single Systems table for backward compatibility
local Systems = {}

-- Collision systems (from PhysicsCore aggregator)
Systems.CollisionHandlers = PhysicsCore.Handlers
Systems.resolve_entities = PhysicsCore.resolve_entities
Systems.update_spatial_grid = PhysicsCore.update_spatial_grid
Systems.resolve_map = PhysicsCore.resolve_map

-- Input (from top-level module)
Systems.read_input = Input.read_input

-- Physics systems (self-iterating)
Systems.acceleration = PhysicsSys.acceleration
Systems.velocity = PhysicsSys.velocity
Systems.knockback_pre = PhysicsSys.knockback_pre
Systems.knockback_post = PhysicsSys.knockback_post
Systems.z_axis = PhysicsSys.z_axis

-- Shooting & Health systems (self-iterating)
Systems.shooter = Shooter.update
Systems.health_regen = HealthRegen.update
Systems.timers = Timers.update
Systems.melee = Melee.update
Systems.bomber = Bomber.update

-- AI systems (self-iterating)
Systems.ai = AISys.update

-- Lighting systems (self-iterating)
Systems.init_extended_palette = Lighting.init_extended_palette
Systems.init_spotlight = Lighting.init_spotlight
Systems.lighting = Lighting.update

-- Shadow systems (self-iterating)
Systems.sync_shadows = Shadows.sync
Systems.draw_shadows = Shadows.draw

-- Rendering systems
Systems.draw_layer = Rendering.draw_layer


-- UI systems (self-iterating)
Systems.draw_health_bars = UI.draw_health_bars
Systems.draw_hitboxes = UI.draw_hitboxes
Systems.draw_aim_lines = UI.draw_aim_lines

-- Animation systems (self-iterating)
Systems.animation = Animation.update

-- Lifecycle systems
Systems.init_lifecycle = Lifecycle.init
Systems.update_lifecycle = Lifecycle.update

-- Effects systems
Systems.Effects = Effects

-- Spawner system
Systems.Spawner = Spawner

-- Floating Text system
Systems.FloatingText = FloatingText

return Systems
