for i, radius in pairs(require("config.radius")) do
  local diameter = string.format("%.1f", 2*radius)
  if radius > 4.75 then
    diameter = string.format("%.0f", 2*radius)
  end
  local flags = {}
  local subgroup = "transport"
  if i > 1 then
    flags = {"hidden"}
    subgroup = nil
  end
  local item = {
    type = "item-with-entity-data",
    name = "katamari-"..i,
    localised_name = {"entity-name.katamari"},
    localised_description = {"item-description.katamari", diameter},
    place_result = "katamari-"..i,
    subgroup = subgroup,
    order = "b[personal-transport]-k[katamari]-" .. string.format("%.2d", i),
    icon = "__katamari__/graphics/icon.png",
    icon_mipmaps = 4,
    icon_size = 64,
    stack_size = 1,
    flags = flags,
  }
  data:extend{item}
end
