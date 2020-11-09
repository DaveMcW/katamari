for i, radius in pairs(require("config.radius")) do
  local collision = radius * 0.5
  local entity = {
    type = "car",
    name = "katamari-"..i,
    localised_name = {"entity-name.katamari"},
    placeable_by = {item ="katamari-"..i, count = 1},
    minable = {result = "katamari-"..i, mining_time = radius * 2},
    collision_box = {{-collision, -collision}, {collision, collision}},
    selection_box = {{-radius, -radius}, {radius, radius}},
    inventory_size = 0,
    weight = 200,
    energy_source = {type = "void"},
    consumption = (4 * radius) .. "kW",
    braking_power = (2 * radius) .. "kW",
    effectivity = 1,
    tank_driving = true,
    rotation_speed = 0.002 / math.sqrt(radius),
    max_health = math.floor(1 + 4 * radius * radius) * 100,
    energy_per_hit_point = 100,
    immune_to_rock_impacts = true,
    immune_to_tree_impacts = true,
    friction = 0.002,
    light = {
      type = "basic",
      intensity = 1,
      size = radius * 3,
    },
    fast_replaceable_group = "katamari",
    icon = "__katamari__/graphics/icon.png",
    icon_mipmaps = 4,
    icon_size = 64,
    animation = { layers = {
      {
        filename = "__katamari__/thumbnail.png",
        direction_count = 1,
        size = 144,
        scale = 0.39 * radius,
        priority = "low",
        hr_version = {
          filename = "__katamari__/graphics/hr-katamari.png",
          direction_count = 1,
          size = 288,
          scale = 0.195 * radius,
          priority = "low",
        },
      },
    }},
    render_layer = "lower-object-above-shadow",
    minimap_representation = {
      filename = "__katamari__/graphics/icon.png",
      size = 64,
      mipmap_count = 4,
      flags = {"icon"},
    }
  }
  data:extend{entity}
end
