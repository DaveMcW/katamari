local START_RADIUS = 0.68
local MIN_PICKUP_SIZE = 0.002
local MAX_PICKUP_SIZE = 0.03
local MAX_SPRITES = 120
local TYPE_BLACKLIST = {
  ["blueprint"] = 1,
  ["blueprint-book"] = 1,
  ["character"] = 1,
  ["character-corpse"] = 1,
  ["corpse"] = 1,
  ["deconstruction-item"] = 1,
  ["explosion"] = 1,
  ["item-request-proxy"] = 1,
  ["projectile"] = 1,
  ["rail-remnants"] = 1,
  ["rocket-silo-rocket"] = 1,
  ["rocket-silo-rocket-shadow"] = 1,
  ["selection-tool"] = 1,
  ["spider-leg"] = 1,
  ["tile-ghost"] = 1,
  ["upgrade-item"] = 1,
}

function on_init()
  global.katamaris = {}
  on_mods_changed()
end

function on_mods_changed()
  -- Cache entity and item dimensions
  global.items = {}
  for _, entity in pairs(game.entity_prototypes) do
    global.items["entity/" .. entity.name] = cache_entity(entity)
  end
  for _, item in pairs(game.item_prototypes) do
    if item.place_result then
      global.items["item/" .. item.name] = cache_entity(item.place_result)
    else
      global.items["item/" .. item.name] = cache_item(item)
    end
  end
  --log(serpent.block(global.items, {numformat = "%.5g"}))

  -- Remove missing sprites
  for _, katamari in pairs(global.katamaris) do
    local i = 1
    while i <= #katamari.sprites do
      if rendering.is_valid(katamari.sprites[i].sprite_id) then
        i = i + 1
      else
        table.remove(katamari.sprites, i)
      end
    end
  end
end

function on_built(event)
  local entity = event.created_entity or event.entity or event.destination
  if not entity or not entity.valid then return end
  if entity.name:sub(1, 9) ~= "katamari-" then return end
  local katamari = {
    entity = entity,
    last_position = entity.position,
    sprites = {},
    next_sprite = 1,
    radius = START_RADIUS,
    volume = 4/3 * math.pi * math.pow(START_RADIUS, 3),
    w=1, x=0, y=0, z=0,  -- Rotation is stored as a quaternion
  }
  global.katamaris[entity.unit_number] = katamari
end

function on_entity_died(event)

end

function on_tick()
  for unit_number, _ in pairs(global.katamaris) do
    update_katamari(unit_number)
  end
end

function cache_entity(entity)
  if TYPE_BLACKLIST[entity.type] then return nil end
  if entity.name:sub(1, 9) == "katamari-" then return end
  local data = {
    size = get_size(entity),
    volume = get_volume(entity),
  }
  if data.volume <= 0 then return nil end
  if entity.type == "transport-belt" then
    -- Transport belt is flat instead of a cube
    -- Also, we need more entities at volume=0.5 for game balance
    data.volume = data.volume * 0.5
  end
  return data
end

function cache_item(item)
  if TYPE_BLACKLIST[item.type] then return nil end
  local data = {
    size = 0.5,
    volume = global.items["entity/item-on-ground"].volume,
  }
  if item.type == "armor" then
    -- Armor should be the same size as the player
    data.size = data.size * 2
    data.volume = data.volume * 8
  end
  return data
end

function get_dimensions(box)
  local width = box.right_bottom.x - box.left_top.x
  local height = box.right_bottom.y - box.left_top.y
  return width, height
end

function get_size(entity)
  local a, b = get_dimensions(entity.collision_box)
  local c, d = get_dimensions(entity.selection_box)
  local e, f = get_dimensions(entity.drawing_box)
  return math.max(a, b, c, d, e, f)
end

function get_volume(entity)
  local width, height = get_dimensions(entity.collision_box)
  local area1 = width * height
  width, height = get_dimensions(entity.selection_box)
  local area2 = width * height
  width, height = get_dimensions(entity.drawing_box)
  local area3 = width * height
  local max_area = math.max(area1, area2, area3)
  return math.pow(max_area, 1.5)
end

function add_sprite(katamari, name, x, y, z)
  if not x or not y or not z then
    -- Generate random point on the sphere
    local lat = math.acos(math.random() * 2 - 1)
    local long = math.random() * 2 * math.pi
    local sin_lat = math.sin(lat)
    x = katamari.radius * sin_lat * math.cos(long)
    y = katamari.radius * sin_lat * math.sin(long)
    z = katamari.radius * math.cos(lat)
  end

  -- Draw sprite on map
  local sprite_id = rendering.draw_sprite{
    sprite = name,
    surface = katamari.entity.surface,
    target = katamari.entity,
    target_offset = {x, y},
    orientation = math.random(),
    x_scale = global.items[name].size,
    y_scale = global.items[name].size,
  }

  -- Save sprite data
  local data = {
    name = name,
    sprite_id = sprite_id,
    size = 1,
    x = x,
    y = y,
    z = z,
  }
  -- Delete old sprite
  if katamari.sprites[katamari.next_sprite] then
    rendering.destroy(katamari.sprites[katamari.next_sprite].sprite_id)
  end
  -- Write new sprite
  katamari.sprites[katamari.next_sprite] = data
  katamari.next_sprite = katamari.next_sprite + 1
  if katamari.next_sprite > MAX_SPRITES then
    katamari.next_sprite = 1
  end
end

function update_katamari(unit_number)
  local katamari = global.katamaris[unit_number]
  if not katamari.entity.valid then
    delete_katamari(unit_number)
    return
  end

  -- Read katamari's movement
  local dx = katamari.entity.position.x - katamari.last_position.x
  local dy = katamari.entity.position.y - katamari.last_position.y
  if dx == 0 and dy == 0 then
    -- Katamari has not moved
    return
  end
  katamari.last_position = katamari.entity.position

  -- Calculate distance travelled
  local distance = math.sqrt(dx*dx + dy*dy)
  if katamari.entity.speed < 0 then
    distance = distance * -1
  end

  -- Calculate rotation angle and axis
  local rotation_angle = distance / katamari.radius
  local axis_angle = katamari.entity.orientation * 2 * math.pi
  local axis_x = math.cos(axis_angle)
  local axis_y = math.sin(axis_angle)
  -- local axis_z = 0

  -- Convert to a quaternion
  -- https://www.cprogramming.com/tutorial/3d/quaternions.html
  local sineA = math.sin(rotation_angle/2)
  local w = math.cos(rotation_angle/2)
  local x = axis_x * sineA
  local y = axis_y * sineA
  -- local z = 0

  -- Multiply by the katamari's quaternion
  -- https://www.cprogramming.com/tutorial/3d/quaternions.html
  local new_w = w*katamari.w - x*katamari.x - y*katamari.y
  local new_x = w*katamari.x + x*katamari.w + y*katamari.z
  local new_y = w*katamari.y - x*katamari.z + y*katamari.w
  local new_z = w*katamari.z + x*katamari.y - y*katamari.x

  -- Update the katamari's quaternion
  katamari.w = new_w
  katamari.x = new_x
  katamari.y = new_y
  katamari.z = new_z
  normalize_quaternion(katamari)

  -- Search for new items
  local entities = katamari.entity.surface.find_entities_filtered{
    position = katamari.entity.position,
    radius = katamari.radius,
  }
  local min_target = katamari.volume * MIN_PICKUP_SIZE
  local max_target = katamari.volume * MAX_PICKUP_SIZE
  for _, entity in pairs(entities) do
    local name = "entity/" .. entity.name
    if entity.type == "item-entity" then
      name = "item/" .. entity.stack.name
    end
    if global.items[name] then
      local volume = global.items[name].volume
      if volume >= min_target and volume <= max_target then
        katamari.volume = katamari.volume + volume
        katamari.radius = math.pow(katamari.volume, 1/3)
        add_sprite(katamari, name)
        entity.destroy()
      end
    end
  end

  -- Draw sprites
  draw_sprites(katamari)
end

function delete_katamari(unit_number)
  local katamari = global.katamaris[unit_number]
  -- Delete sprites
  for i = 1, #katamari.sprites do
    rendering.destroy(katamari.sprites[i].sprite_id)
  end
  global.katamaris[unit_number] = nil
end

function draw_sprites(katamari)
  -- Build rotation matrix
  -- https://en.wikipedia.org/wiki/Rotation_matrix#Quaternion
  local a1 = 1 - 2*katamari.y*katamari.y - 2*katamari.z*katamari.z
  local a2 = 2*katamari.x*katamari.y - 2*katamari.w*katamari.z
  local a3 = 2*katamari.x*katamari.z + 2*katamari.w*katamari.y
  local b1 = 2*katamari.x*katamari.y + 2*katamari.w*katamari.z
  local b2 = 1 - 2*katamari.x*katamari.x - 2*katamari.z*katamari.z
  local b3 = 2*katamari.y*katamari.z - 2*katamari.w*katamari.x
  local c1 = 2*katamari.x*katamari.z - 2*katamari.w*katamari.y
  local c2 = 2*katamari.y*katamari.z + 2*katamari.w*katamari.x
  local c3 = 1 - 2*katamari.x*katamari.x - 2*katamari.y*katamari.y

  for i = 1, #katamari.sprites do
    local sprite = katamari.sprites[i]

    -- Rotate sprite
    local x = a1*sprite.x + a2*sprite.y + a3*sprite.z
    local y = b1*sprite.x + b2*sprite.y + b3*sprite.z
    local z = c1*sprite.x + c2*sprite.y + c3*sprite.z

    -- Update position
    rendering.set_target(sprite.sprite_id, katamari.entity, {x, y})
    rendering.set_render_layer(sprite.sprite_id, math.floor(z * 30 + 129))
  end
end

function normalize_quaternion(q)
  -- Convert to a unit quaternion
  local magnitude = q.w*q.w + q.x*q.x + q.y*q.y + q.z*q.z
  if magnitude > 0.999 and magnitude < 1.001 then
    -- Error of less than 0.001 is good enough
    return
  end
  magnitude = math.sqrt(magnitude)
  q.w = q.w / magnitude
  q.x = q.x / magnitude
  q.y = q.y / magnitude
  q.z = q.z / magnitude
end

local filter = {{filter = "type", type = "car"}}
script.on_init(on_init)
script.on_configuration_changed(on_mods_changed)
script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_built_entity, on_built, filter)
script.on_event(defines.events.on_robot_built_entity, on_built, filter)
script.on_event(defines.events.script_raised_built, on_built, filter)
script.on_event(defines.events.script_raised_revive, on_built, filter)
script.on_event(defines.events.on_entity_cloned, on_built, filter)
script.on_event(defines.events.on_entity_died, on_entity_died, filter)
