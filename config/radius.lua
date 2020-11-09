-- Return the radius of each katamari entity
local result = {}
local radius = 0.35
for i = 1, 25 do
  result[i] = radius
  radius = radius * 1.2
end
return result
