-- Use different knob sprites to simulate 3D rotation
return function(angle)
  -- Less than 5 degrees from the north pole of the unit sphere
  if angle > 0.9962 then
    return "katamari-knob-1"
  -- 5 to 15 degrees
  elseif angle > 0.9659 then
    return "katamari-knob-2"
  -- 15 to 25 degrees
  elseif angle > 0.9063 then
    return "katamari-knob-3"
  -- 25 to 35 degrees
  elseif angle > 0.8192 then
    return "katamari-knob-4"
  -- 35 to 45 degrees
  elseif angle > 0.7071 then
    return "katamari-knob-5"
  -- 45 to 55 degrees
  elseif angle > 0.5736 then
    return "katamari-knob-6"
  -- 55 to 65 degrees
  elseif angle > 0.4226 then
    return "katamari-knob-7"
  -- 65 to 75 degrees
  elseif angle > 0.2588 then
    return "katamari-knob-8"
  -- 75 to 85 degrees
  elseif angle > 0.0872 then
    return "katamari-knob-9"
  -- 85 to 95 degrees
  elseif angle > -0.0872 then
    return "katamari-knob-10"
  -- 95 to 105 degrees
  elseif angle > -0.2588 then
    return "katamari-knob-11"
  -- More than 105 degrees
  else
    return "katamari-knob-12"
  end
end
