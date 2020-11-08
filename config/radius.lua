local radii = {}
local start_radius = 0.5
for i = 1, 30 do
  table.insert(radii, start_radius * math.pow(1.2, i))
end
return radii
