-- Create a dummy copy of each character
local dummies = {}
for name, character in pairs(data.raw["character"]) do
  local dummy = table.deepcopy(character)
  dummy.name = "katamari-dummy-" .. name
  dummy.inventory_size = 0
  dummy.collision_mask = nil
  dummy.collision_box = nil
  dummy.selection_box = nil
  dummy.selectable_in_game = false
  table.insert(dummies, dummy)
end
data:extend(dummies)
