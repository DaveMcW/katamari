local circle = {
  type = "sprite",
  name = "katamari-circle",
  filename = "__katamari__/graphics/circle.png",
  size = 144,
  mipmap_count = 4,
  scale = 0.5,
}
data:extend{circle}

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
