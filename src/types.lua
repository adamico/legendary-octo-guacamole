--- @meta

-- This file contains type definitions for ECS components to assist LuaLS.
-- These classes represent the Structure-of-Arrays (SoA) buffers passed to system queries.

--- @class AccelerationComponent
--- @field accel number[]
--- @field friction number[]
--- @field max_speed number[]
--- @field gravity_z number[]

--- @class VelocityComponent
--- @field vel_x number[]
--- @field vel_y number[]
--- @field vel_z number[]
--- @field knockback_vel_x number[]
--- @field knockback_vel_y number[]
--- @field sub_x number[]
--- @field sub_y number[]

--- @class DirectionComponent
--- @field dir_x number[]
--- @field dir_y number[]
--- @field facing string[]

--- @class TimersComponent
--- @field shoot_cooldown number[]
--- @field invuln_timer number[]
--- @field hp_drain_timer number[]
--- @field stun_timer number[]
--- @field slow_timer number[]
--- @field slow_factor number[]
--- @field melee_cooldown number[]
--- @field lifespan number[]

--- @class PositionComponent
--- @field x number[]
--- @field y number[]
--- @field z number[]

--- @class LifetimeComponent
--- @field age number[]
--- @field max_age number[]

--- @class TypeComponent
--- @field value string[]

--- @class TagsComponent
--- @field value boolean[]
