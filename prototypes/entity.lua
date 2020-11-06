local katamari = table.deepcopy(data.raw.car.tank)
katamari.name = "katamari-1"
katamari.placeable_by = {item ="katamari", count = 1}
katamari.minable.result = "katamari"
katamari.collision_box = {{-0.6, -0.6}, {0.6, 0.6}}
katamari.selection_box = {{-0.6, -0.6}, {0.6, 0.6}}
for _, layer in pairs(katamari.animation.layers) do
  layer.scale = 0.3
  layer.hr_version.scale = 0.15
end
katamari.weight = 100
katamari.inventory_size = 0
katamari.energy_source = {type = "void"}
katamari.consumption = "10kW"
katamari.light = {
  type = "basic",
  intensity = 1,
  size = 20,
}
katamari.burner = nil
katamari.turret_animation = nil
katamari.damaged_trigger_effect = nil
katamari.guns = nil
katamari.working_sound = nil
katamari.track_particle_triggers = nil
katamari.stop_trigger = nil
katamari.stop_trigger_speed = nil
katamari.fast_replaceable_group = "katamari"
data:extend{katamari}


-- 1.1
-- 1.2
-- 1.3
-- 1.4
-- 1.5
-- 1.6
-- 1.8
-- 2.0
-- 2.2
-- 2.4
-- 2.7
-- 3
-- 3.3
-- 3.6
-- 4
-- 4.5
-- 5
-- 5.5
-- 6
-- 25
