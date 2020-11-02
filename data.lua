local katamari = table.deepcopy(data.raw.car.tank)
katamari.name = "katamari-1"
katamari.placeable_by = {item ="katamari", count = 1}
katamari.minable.result = "katamari"
katamari.collision_box = {{-0.6, -0.6}, {0.6, 0.6}}
katamari.selection_box = {{-0.6, -0.6}, {0.6, 0.6}}
for _, layer in pairs(katamari.animation.layers) do
  layer.scale = 0.3
  layer.hr_version.scale = 0.15
end
katamari.turret_animation = nil
katamari.burner = nil
katamari.energy_source = {type = "void"}
katamari.damaged_trigger_effect = nil
katamari.inventory_size = 0
katamari.guns = nil
katamari.working_sound = nil
katamari.fast_replaceable_group = "katamari"
data:extend{katamari}

local item = {
  type = "item-with-entity-data",
  name = "katamari",
  place_result = "katamari-1",
  subgroup = "transport",
  order = "b[personal-transport]-k[katamari]",
  icon = "__base__/graphics/icons/small-plane.png",
  icon_mipmaps = 4,
  icon_size = 64,
  stack_size = 1,
}
data:extend{item}

local recipe = {
  type = "recipe",
  name = "katamari",
  result = "katamari",
  energy_required = 10,
  ingredients = {
    {"plastic-bar", 1200},
    {"low-density-structure", 120},
    {"heavy-oil-barrel", 12},
  },
}
data:extend{recipe}

-- Low density structure unlocks katamari recipe
local effect = {type = "unlock-recipe", recipe = "katamari"}
table.insert(data.raw.technology["low-density-structure"].effects, effect)

-- 1.1
-- 1.2
-- 1.3
-- 1.4
-- 1.5
-- 1.6
-- 1.8
-- 2.0
-- 2.2
-- 2.4
-- 2.7
-- 3
-- 3.3
-- 3.6
-- 4
-- 4.5
-- 5
-- 5.5
-- 6
-- 25
