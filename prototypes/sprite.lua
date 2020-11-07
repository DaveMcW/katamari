-- Create a sprite for each whitelist decorative
local DECORATIVE_WHITELIST = require("config.decorative_whitelist")
for name, decorative in pairs(data.raw["optimized-decorative"]) do
  if DECORATIVE_WHITELIST[name] then
    local picture = decorative.pictures[1]
    local size = picture.size or math.min(picture.width, picture.height)
    local x = 0
    local y = 0
    if picture.width and picture.height then
      if picture.width > picture.height then x = 1 end
      if picture.height > picture.width then y = 1 end
    end
    local sprite = {
      type = "sprite",
      name = "katamari-decorative-" .. name,
      filename = picture.filename,
      size = size,
      x = x,
      y = y,
    }
    data:extend{sprite}
  end
end

-- The katamari background circle
local circle = {
  type = "sprite",
  name = "katamari-circle",
  filename = "__katamari__/graphics/circle.png",
  size = 144,
  mipmap_count = 4,
  scale = 0.5,
}
data:extend{circle}

-- The 12 bumps on the katamari
for i = 1, 12 do
  local sprite = {
    type = "sprite",
    name = "katamari-knob-" .. i,
    filename = "__katamari__/graphics/knob-" .. i .. ".png",
    size = 64,
    mipmap_count = 4,
    scale = 0.5,
    flags = {"no-crop", "mipmap"},
  }
  data:extend{sprite}
end
