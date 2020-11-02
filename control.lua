local START_RADIUS = 0.5
local GROWTH_COST = 10
local MIN_PICKUP_SIZE = 1 / 120
local MAX_PICKUP_SIZE = 1 / 12
local MAX_SPRITES = 120
local ENTITY_BLACKLIST = {
  ["arrow"] = 1,
  ["artillery-flare"] = 1,
  ["artillery-projectile"] = 1,
  ["beam"] = 1,
  ["character"] = 1,
  ["character-corpse"] = 1,
  ["corpse"] = 1,
  ["explosion"] = 1,
  ["entity-ghost"] = 1,
  ["flame-thrower-explosion"] = 1,
  ["fire"] = 1,
  ["flying-text"] = 1,
  ["highlight-box"] = 1,
  ["item-request-proxy"] = 1,
  ["leaf-particle"] = 1,
  ["projectile"] = 1,
  ["particle"] = 1,
  ["particle-source"] = 1,
  ["rail-remnants"] = 1,
  ["rocket-silo-rocket"] = 1,
  ["rocket-silo-rocket-shadow"] = 1,
  ["smoke"] = 1,
  ["smoke-with-trigger"] = 1,
  ["speech-bubble"] = 1,
  ["spider-leg"] = 1,
  ["sticker"] = 1,
  ["stream"] = 1,
  ["tile-ghost"] = 1,
}
local ITEM_BLACKLIST = {
  ["blueprint"] = 1,
  ["blueprint-book"] = 1,
  ["deconstruction-item"] = 1,
  ["selection-tool"] = 1,
  ["upgrade-item"] = 1,
}
local CUSTOM_SIZES = {
  -- These icons only show a piece of the entity
  ["arithmetic-combinator"] = 1,
  ["artillery-turret"] = 4,
  ["artillery-wagon"] = 4,
  ["cargo-wagon"] = 4,
  ["decider-combinator"] = 1,
  ["locomotive"] = 4,
  ["fluid-wagon"] = 3,
  ["steam-turbine"] = 3.5,
  -- These selection boxes don't match the graphics
  ["car"] = 3,
  ["spidertron"] = 4,
}

function on_init()
  global.katamaris = {}
  on_configuration_changed()
end

function on_configuration_changed()
  -- Low density structure unlocks katamari recipe
  for _, force in pairs(game.forces) do
    if force.technologies["low-density-structure"].researched then
      force.recipes["katamari"].enabled = true
    end
  end

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
        if katamari.next_sprite > i then
          katamari.next_sprite = katamari.next_sprite - 1
        end
      end
    end
  end
end

function on_tick()
  -- Update katamaris
  for unit_number, _ in pairs(global.katamaris) do
    update_katamari(unit_number)
  end
end

function on_built(event)
  local entity = event.created_entity or event.entity or event.destination
  if not entity or not entity.valid then return end
  if entity.name:sub(1, 9) ~= "katamari-" then return end
  -- Create katamari table
  global.katamaris[entity.unit_number] = {
    entity = entity,
    last_position = entity.position,
    sprites = {},
    next_sprite = 1,
    radius = START_RADIUS,
    area = 4 * math.pi * START_RADIUS * START_RADIUS,
    w=1, x=0, y=0, z=0,  -- Rotation is stored as a quaternion
  }
  -- Disable gui
  entity.operable = false
end

function on_player_driving_changed_state(event)
  -- Update katamari driver
  if not event.entity then return end
  if event.entity.name:sub(1, 9) ~= "katamari-" then return end
  local katamari = global.katamaris[event.entity.unit_number]
  local player = game.players[event.player_index]
  if player.driving then
    -- Create a dummy driver as a clone of the player
    if player.character then
      katamari.driver = katamari.entity.surface.create_entity{
        name = player.character.name,
        force = katamari.entity.force,
        position = katamari.entity.position,
      }
      -- Give the dummy the same armor as the player
      local inventory = player.character.get_inventory(defines.inventory.character_armor)
      for i = 1, #inventory do
        if inventory[i].valid_for_read then
          katamari.driver.insert{name = inventory[i].name, count = inventory[i].count}
        end
      end
      -- Disable dummy driver interactions
      katamari.driver.destructible = false
      katamari.driver.operable = false
      katamari.last_orientation = nil
    end
  else
    if katamari.driver then
      -- Teleport player to the dummy driver's position
      local position = katamari.driver.surface.find_non_colliding_position(
        katamari.driver.name,
        katamari.driver.position,
        katamari.radius * 1.5 + 2,
        0.1
      )
      if not position then
        position = katamari.driver.position
      end
      player.teleport(position)
      -- Destroy dummy driver
      katamari.driver.destroy()
    end
    katamari.driver = nil
  end
end

-- Delete katamari
function delete_katamari(unit_number)
  local katamari = global.katamaris[unit_number]
  -- Delete sprites
  for i = 1, #katamari.sprites do
    rendering.destroy(katamari.sprites[i].sprite_id)
  end
  global.katamaris[unit_number] = nil
end

-- Update katamari
function update_katamari(unit_number)
  -- Make sure the entity still exists
  local katamari = global.katamaris[unit_number]
  if not katamari.entity.valid then
    delete_katamari(unit_number)
    return
  end

  -- Read entity movement
  local dx = katamari.entity.position.x - katamari.last_position.x
  local dy = katamari.entity.position.y - katamari.last_position.y
  local orientation = katamari.last_orientation
  katamari.last_position = katamari.entity.position
  katamari.last_orientation = katamari.entity.orientation

  -- Update dummy driver
  if katamari.driver then
    local direction = math.floor((katamari.entity.orientation * 8 + 0.5) % 8)
    if katamari.entity.speed < 0 then
      direction = (direction + 4) % 8
    end
    if dx ~= 0 or dy ~= 0 or orientation ~= katamari.entity.orientation then
      local driver_angle = katamari.entity.orientation * 2 * math.pi
      local driver_x = katamari.entity.position.x - (katamari.radius + 0.5) * 1.5 * math.sin(driver_angle)
      local driver_y = katamari.entity.position.y + 0.5 + (katamari.radius + 0.5) * 1.5 * math.cos(driver_angle)
      katamari.driver.teleport{driver_x, driver_y}
      katamari.driver.walking_state = {walking = true, direction = direction}
    else
      katamari.driver.walking_state = {walking = false, direction = direction}
    end
  end

  if dx == 0 and dy == 0 then
    -- Katamari does not need to rotate
    return
  end

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

  -- Multiply by the katamari quaternion
  -- https://www.cprogramming.com/tutorial/3d/quaternions.html
  local new_w = w*katamari.w - x*katamari.x - y*katamari.y
  local new_x = w*katamari.x + x*katamari.w + y*katamari.z
  local new_y = w*katamari.y - x*katamari.z + y*katamari.w
  local new_z = w*katamari.z + x*katamari.y - y*katamari.x

  -- Update the katamari quaternion
  katamari.w = new_w
  katamari.x = new_x
  katamari.y = new_y
  katamari.z = new_z
  normalize_quaternion(katamari)

  -- Search for targets
  local max_target = katamari.area * MAX_PICKUP_SIZE
  local min_target = katamari.area * MIN_PICKUP_SIZE
  local entities = katamari.entity.surface.find_entities_filtered{
    position = katamari.entity.position,
    radius = katamari.radius,
  }
  for _, entity in pairs(entities) do
    if entity.valid then
      local name = "entity/" .. entity.name
      if entity.type == "item-entity" then
        name = "item/" .. entity.stack.name
      end
      if global.items[name] then
        local area = global.items[name].area
        if area <= max_target then
          -- Eat target
          entity.destroy({raise_destroy = true})
          -- Minimum size required to grow
          if area >= min_target then
            katamari.area = katamari.area + area / GROWTH_COST
            katamari.radius = math.sqrt(katamari.area / math.pi / 4)
            add_sprite(katamari, name)
          end
        end
      end
    end
  end

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

  -- Rotate sprites to match the katamari
  for i = 1, #katamari.sprites do
    local sprite = katamari.sprites[i]
    local x = a1*sprite.x + a2*sprite.y + a3*sprite.z
    local y = b1*sprite.x + b2*sprite.y + b3*sprite.z
    local z = c1*sprite.x + c2*sprite.y + c3*sprite.z
    target_offset = {x * katamari.radius, y * katamari.radius}
    rendering.set_target(sprite.sprite_id, katamari.entity, target_offset)
    rendering.set_render_layer(sprite.sprite_id, math.floor(z * 30 + 129))
  end
end

-- Calculate entity size and area
function cache_entity(entity)
  if ENTITY_BLACKLIST[entity.type] then return nil end
  if entity.name:sub(1, 9) == "katamari-" then return end
  local data = {
    size = get_size(entity),
    area = get_area(entity),
  }
  if CUSTOM_SIZES[entity.name] then
    data.size = CUSTOM_SIZES[entity.name]
  end
  return data
end

-- Calculate item size and area
function cache_item(item)
  local data = {
    size = 0.5,
    area = global.items["entity/item-on-ground"].area,
  }
  if ITEM_BLACKLIST[item.type] then
    -- We can pick up these items, but they don't increase katamari size
    data.size = 0
    data.area = 0
  elseif item.type == "armor" then
    -- Armor should be the same size as the player
    data.size = 1
    data.area = 1
  end
  return data
end

-- Calculate width and height
function get_width_height(box)
  local width = box.right_bottom.x - box.left_top.x
  local height = box.right_bottom.y - box.left_top.y
  return width, height
end

-- Find the largest dimension
function get_size(entity)
  local a, b = get_width_height(entity.collision_box)
  local c, d = get_width_height(entity.selection_box)
  local e, f = get_width_height(entity.drawing_box)
  return math.max(a, b, c, d, e, f)
end

-- Find the largest area among the various boxes
function get_area(entity)
  local width, height = get_width_height(entity.collision_box)
  local area1 = width * height
  width, height = get_width_height(entity.selection_box)
  local area2 = width * height
  width, height = get_width_height(entity.drawing_box)
  local area3 = width * height
  return math.max(area1, area2, area3)
end

-- Add a sprite to the katamari
function add_sprite(katamari, name, x, y, z)
  if not x or not y or not z then
    -- Generate random point on the sphere
    local lat = math.acos(math.random() * 2 - 1)
    local long = math.random() * 2 * math.pi
    local sin_lat = math.sin(lat)
    x = sin_lat * math.cos(long)
    y = sin_lat * math.sin(long)
    z = math.cos(lat)
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

-- Convert to a unit quaternion
function normalize_quaternion(q)
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

-- Katamari has type=car
local filter = {{filter = "type", type = "car"}}
script.on_init(on_init)
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_built_entity, on_built, filter)
script.on_event(defines.events.on_robot_built_entity, on_built, filter)
script.on_event(defines.events.script_raised_built, on_built, filter)
script.on_event(defines.events.script_raised_revive, on_built, filter)
script.on_event(defines.events.on_entity_cloned, on_built, filter)
script.on_event(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
