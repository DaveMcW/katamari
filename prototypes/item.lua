for i, radius in pairs(require("config.radius")) do
  local item = {
    type = "item-with-entity-data",
    name = "katamari-"..i,
    localised_name = {"entity-name.katamari"},
    localised_description = {"item-description.katamari", string.format("%.1f", 2*radius)},
    place_result = "katamari-"..i,
    subgroup = "transport",
    order = "b[personal-transport]-k[katamari]",
    icon = "__katamari__/graphics/icon.png",
    icon_mipmaps = 4,
    icon_size = 64,
    stack_size = 1,
  }
  data:extend{item}
end
