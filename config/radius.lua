local radii = {}
local start_radius = 0.5
for i = 1, 25 do
  radii[i] = start_radius * math.pow(1.2, i - 1)
end
return radii
