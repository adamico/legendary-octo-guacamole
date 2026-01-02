-- Mutations module
-- Handles mutation selection and management
local MutationsConfig = require("src/game/config/mutations")

local Mutations = {}

--- Pick N distinct random mutations
--- @param count Number of mutations to pick
--- @return table List of mutation definition objects
function Mutations.pick_random_items(count)
   local candidates = {}
   for _, m in pairs(MutationsConfig.Mutation) do
      add(candidates, m)
   end

   local selected = {}
   for i = 1, count do
      if #candidates == 0 then break end
      local idx = flr(rnd(#candidates)) + 1
      add(selected, candidates[idx])
      del(candidates, candidates[idx]) -- Remove to ensure uniqueness
   end

   return selected
end

return Mutations
