local recipe = {
  type = "recipe",
  name = "katamari",
  result = "katamari-1",
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
