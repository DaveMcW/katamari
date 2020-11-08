local GROWTH_COST = 10
local MIN_PICKUP_SIZE = 1 / 120
local MAX_PICKUP_SIZE = 1 / 12
local MAX_SPRITES = 120
local KNOB_SCALE = 0.9
local CIRCLE_SCALE = 2 / (144 * 0.5 / 32)  -- diameter divided by sprite size
local TWO_PI = 2 * math.pi
local INVERSE_ROOT_2 = 1 / math.sqrt(2)
local ENTITY_BLACKLIST = require("config.entity_blacklist")
local ITEM_BLACKLIST = require("config.item_blacklist")
local DECORATIVE_WHITELIST = require("config.decorative_whitelist")
local CUSTOM_ENTITIES = require("config.custom_entities")
local RADII = require("config.radius")
local TRANSPORT_BELT_CONNECTABLE = {
  ["loader"] = 1,
  ["splitter"] = 1,
  ["transport-belt"] = 1,
  ["underground-belt"] = 1,
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
  for _, decorative in pairs(game.decorative_prototypes) do
    global.items["katamari-decorative-" .. decorative.name] = cache_decorative(decorative)
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
  for unit_number, katamari in pairs(global.katamaris) do
    update_katamari(unit_number)
  end
end

function on_built(event)
  local entity = event.created_entity or event.entity or event.destination
  if not entity or not entity.valid then return end
  if entity.name:sub(1, 9) ~= "katamari-" then return end
  local size = tonumber(entity.name:sub(10))
  local radius = RADII[size]
  if not radius then
    entity.destroy{raise_destroy = true}
    return
  end

  -- Create katamari table
  local katamari = {
    entity = entity,
    last_position = entity.position,
    sprites = {},
    knobs = {},
    next_sprite = 1,
    size = size,
    radius = radius,
    area = 4 * math.pi * radius * radius,
    w=1, x=0, y=0, z=0,  -- Rotation is stored as a quaternion
  }
  global.katamaris[entity.unit_number] = katamari

  -- Draw circle
  draw_circle(katamari)

  -- Add 12 knobs
  -- https://en.wikipedia.org/wiki/Regular_icosahedron#Cartesian_coordinates
  create_knob(katamari,  0.0000,  0.5257,  0.8507)
  create_knob(katamari,  0.0000,  0.5257, -0.8507)
  create_knob(katamari,  0.0000, -0.5257,  0.8507)
  create_knob(katamari,  0.0000, -0.5257, -0.8507)
  create_knob(katamari,  0.8507,  0.0000,  0.5257)
  create_knob(katamari,  0.8507,  0.0000, -0.5257)
  create_knob(katamari, -0.8507,  0.0000,  0.5257)
  create_knob(katamari, -0.8507,  0.0000, -0.5257)
  create_knob(katamari,  0.5257,  0.8507,  0.0000)
  create_knob(katamari,  0.5257, -0.8507,  0.0000)
  create_knob(katamari, -0.5257,  0.8507,  0.0000)
  create_knob(katamari, -0.5257, -0.8507,  0.0000)
end

function on_player_driving_changed_state(event)
  if not event.entity then return end
  if event.entity.name:sub(1, 9) ~= "katamari-" then return end
  local katamari = global.katamaris[event.entity.unit_number]
  if not katamari then return end
  if katamari.growing then return end
  -- Update katamari driver
  local player = game.players[event.player_index]
  if player.driving then
    if player.character then
      -- Rotate katamari towards the player
      if katamari.entity.speed == 0 then
        local dx = katamari.entity.position.x - player.character.position.x
        local dy = player.character.position.y - katamari.entity.position.y
        katamari.entity.orientation = math.atan2(dx, dy) / TWO_PI
      end
      -- Clean up old dummy driver
      if katamari.driver and katamari.driver.valid then
        katamari.driver.destroy()
      end
      -- Create a dummy driver as a clone of the player
      katamari.driver = katamari.entity.surface.create_entity{
        name = player.character.name,
        force = katamari.entity.force,
        position = katamari.entity.position,
      }
      -- Give the dummy driver the same armor as the player
      local player_inventory = player.character.get_inventory(defines.inventory.character_armor)
      local dummy_inventory = katamari.driver.get_inventory(defines.inventory.character_armor)
      for i = 1, #player_inventory do
        if player_inventory[i].valid_for_read then
          dummy_inventory.insert{name = player_inventory[i].name, count = player_inventory[i].count}
        end
      end
      -- Disable dummy driver interactions
      katamari.driver.destructible = false
      katamari.driver.operable = false
      -- Force recalculation of dummy driver position
      katamari.last_orientation = nil
    end
  else
    if katamari.driver and katamari.driver.valid then
      -- Teleport player to the dummy driver's position
      local position = katamari.driver.surface.find_non_colliding_position(
        katamari.driver.name,
        katamari.driver.position,
        katamari.radius * 1.4 + 2,
        0.1
      )
      if position then
        player.teleport(position)
      end
      -- Destroy dummy driver
      katamari.driver.destroy()
    end
    katamari.driver = nil
  end
end

function create_knob(katamari, x, y, z)
  -- Save sprite data
  local data = {
    x = x,
    y = y,
    z = z,
  }
  table.insert(katamari.knobs, data)
  draw_knob(katamari, data)
end

-- Delete katamari
function delete_katamari(unit_number)
  local katamari = global.katamaris[unit_number]
  -- Delete dummy driver
  if katamari.driver and katamari.driver.valid and not katamari.growing then
    katamari.driver.destroy()
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
  katamari.last_orientation = katamari.entity.orientation
  katamari.last_position = katamari.entity.position

  -- Update dummy driver
  if katamari.driver and katamari.driver.valid then
    local direction = math.floor((katamari.entity.orientation * 8 + 0.5) % 8)
    if katamari.entity.speed < 0 then
      direction = (direction + 4) % 8
    end
    if dx ~= 0 or dy ~= 0 or orientation ~= katamari.entity.orientation then
      local driver_angle = katamari.entity.orientation * TWO_PI
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
  local axis_angle = katamari.entity.orientation * TWO_PI
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

  -- Eat decoratives
  local width = katamari.radius * INVERSE_ROOT_2
  local p = katamari.entity.position
  local area = {{p.x - width, p.y - width}, {p.x + width, p.y + width}}
  local decoratives = katamari.entity.surface.find_decoratives_filtered{area = area}
  for _, decorative in pairs(decoratives) do
    katamari = eat_decorative(katamari, decorative)
  end

  -- Eat entities
  local entities = katamari.entity.surface.find_entities_filtered{
    position = katamari.entity.position,
    radius = katamari.radius,
  }
  for _, entity in pairs(entities) do
    if entity.valid then
      if TRANSPORT_BELT_CONNECTABLE[entity.type] then
        katamari = eat_transport_items(katamari, entity)
      end
      katamari = eat_entity(katamari, entity)
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

  -- Adjust circle
  local diameter = katamari.radius * CIRCLE_SCALE
  if diameter ~= katamari.last_diameter then
    rendering.set_x_scale(katamari.circle, diameter)
    rendering.set_y_scale(katamari.circle, diameter)
    katamari.last_diameter = diameter
  end

  -- Rotate knobs
  for i = 1, #katamari.knobs do
    local sprite = katamari.knobs[i]
    local x = a1*sprite.x + a2*sprite.y + a3*sprite.z
    local y = b1*sprite.x + b2*sprite.y + b3*sprite.z
    local z = c1*sprite.x + c2*sprite.y + c3*sprite.z
    local target_offset = {x * katamari.radius, y * katamari.radius}
    local render_layer = 128
    if z > -0.0872 then
      render_layer = 130
    end
    rendering.set_sprite(sprite.sprite_id, get_knob_name(z))
    rendering.set_x_scale(sprite.sprite_id, katamari.radius * KNOB_SCALE)
    rendering.set_y_scale(sprite.sprite_id, katamari.radius * KNOB_SCALE)
    rendering.set_target(sprite.sprite_id, katamari.entity, target_offset)
    rendering.set_orientation(sprite.sprite_id, math.atan2(x, -y) / TWO_PI)
    rendering.set_render_layer(sprite.sprite_id, render_layer)
  end

  -- Rotate sprites
  for i = 1, #katamari.sprites do
    local sprite = katamari.sprites[i]
    local x = a1*sprite.x + a2*sprite.y + a3*sprite.z
    local y = b1*sprite.x + b2*sprite.y + b3*sprite.z
    local z = c1*sprite.x + c2*sprite.y + c3*sprite.z
    local target_offset = {x * katamari.radius, y * katamari.radius}
    -- Rendering takes 90% of the runtime
    -- TODO: Skip render calls when possible
    rendering.set_target(sprite.sprite_id, katamari.entity, target_offset)
    rendering.set_render_layer(sprite.sprite_id, math.floor(z * 30 + 130))
  end
end

function eat_entity(katamari, entity)
  -- Look up entity
  local name = "entity/" .. entity.name
  if entity.type == "item-entity" then
    name = "item/" .. entity.stack.name
  end
  if not global.items[name] then return katamari end
  local area = global.items[name].area

  -- Minimum size required to eat
  if area <= katamari.area * MAX_PICKUP_SIZE then
    entity.destroy{raise_destroy = true}
    -- Minimum size required to grow
    if area >= katamari.area * MIN_PICKUP_SIZE then
      add_sprite(katamari, name)
      katamari = grow_katamari(katamari, area)
    end
  end
  return katamari
end

function eat_transport_items(katamari, entity)
  -- Deconstruct entity so LuaTransportLine contains only the items we want
  local to_be_deconstructed = entity.to_be_deconstructed()
  if not to_be_deconstructed then
    entity.order_deconstruction(entity.force)
  end
  -- Read LuaTransportLine
  for i = 1, entity.get_max_transport_line_index() do
    local transport_line = entity.get_transport_line(i)
    for name, count in pairs(transport_line.get_contents()) do
      local sprite_name = "item/" .. name
      local data = global.items[sprite_name]
      -- Minimum size required to eat
      if data and data.area <= katamari.area * MAX_PICKUP_SIZE then
        transport_line.remove_item{name = name, count = count}
        -- Minimum size required to grow
        if data.area >= katamari.area * MIN_PICKUP_SIZE then
          for j = 1, count do
            add_sprite(katamari, sprite_name)
          end
          katamari = grow_katamari(katamari, data.area * count)
        end
      end
    end
  end
  local items = entity.get_transport_line(1)
  -- Cancel deconstruction
  if not to_be_deconstructed then
    entity.cancel_deconstruction(entity.force)
  end
  return katamari
end

function eat_decorative(katamari, target)
  -- Look up decorative
  local name = "katamari-decorative-" .. target.decorative.name
  if not global.items[name] then return katamari end
  local area = global.items[name].area
  -- Minimum size required to eat
  if area <= katamari.area * MAX_PICKUP_SIZE then
    katamari.entity.surface.destroy_decoratives{
      position = target.position,
      name = target.decorative.name,
    }
    -- Only add the handpicked set of decoratives
    if DECORATIVE_WHITELIST[target.decorative.name] then
      -- Minimum size required to grow
      if area >= katamari.area * MIN_PICKUP_SIZE then
        for i = 1, target.amount do
          add_sprite(katamari, name)
        end
        katamari = grow_katamari(katamari, area * target.amount)
      end
    end
  end
  return katamari
end

function grow_katamari(katamari, area)
  -- Heal
  local healing = katamari.entity.prototype.max_health * area / katamari.area
  katamari.entity.health = katamari.entity.health + healing

  -- Increase size
  katamari.area = katamari.area + area / GROWTH_COST
  katamari.radius = math.sqrt(katamari.area / math.pi / 4)

  -- Upgrade entity
  if not RADII[katamari.size + 1] then return katamari end
  if RADII[katamari.size + 1] > katamari.radius then return katamari end
  katamari.size = katamari.size + 1
  local new_entity = katamari.entity.surface.create_entity{
    name = "katamari-" .. katamari.size,
    force = katamari.entity.force,
    position = katamari.entity.position,
  }
  if not new_entity then return katamari end

  -- Copy properties
  new_entity.orientation = katamari.entity.orientation
  new_entity.speed = katamari.entity.speed
  local missing_health = katamari.entity.prototype.max_health - katamari.entity.health
  new_entity.health = new_entity.health - missing_health
  new_entity.riding_state = katamari.entity.riding_state

  -- Transfer driver
  katamari.growing = true
  local driver = katamari.entity.get_driver()
  local passenger = katamari.entity.get_passenger()
  katamari.entity.destroy()
  new_entity.set_driver(driver)
  new_entity.set_passenger(passenger)

  -- Replace katamari
  local new_katamari = {}
  for key, value in pairs(katamari) do
    new_katamari[key] = value
  end
  global.katamaris[new_entity.unit_number] = new_katamari
  new_katamari.entity = new_entity
  new_katamari.growing = nil

  -- Redraw renderings
  draw_circle(new_katamari)
  for i = 1, #new_katamari.knobs do
    draw_knob(new_katamari, new_katamari.knobs[i])
  end
  for i = 1, #katamari.sprites do
    draw_sprite(new_katamari, new_katamari.sprites[i])
  end
  return new_katamari
end

function get_knob_name(z)
  -- Less than 5 degrees from the north pole of the unit sphere
  if z > 0.9962 then
    return "katamari-knob-1"
  -- 5 to 15 degrees
  elseif z > 0.9659 then
    return "katamari-knob-2"
  -- 15 to 25 degrees
  elseif z > 0.9063 then
    return "katamari-knob-3"
  -- 25 to 35 degrees
  elseif z > 0.8192 then
    return "katamari-knob-4"
  -- 35 to 45 degrees
  elseif z > 0.7071 then
    return "katamari-knob-5"
  -- 45 to 55 degrees
  elseif z > 0.5736 then
    return "katamari-knob-6"
  -- 55 to 65 degrees
  elseif z > 0.4226 then
    return "katamari-knob-7"
  -- 65 to 75 degrees
  elseif z > 0.2588 then
    return "katamari-knob-8"
  -- 75 to 85 degrees
  elseif z > 0.0872 then
    return "katamari-knob-9"
  -- 85 to 95 degrees
  elseif z > -0.0872 then
    return "katamari-knob-10"
  -- 95 to 105 degrees
  elseif z > -0.2588 then
    return "katamari-knob-11"
  -- More than 105 degrees
  else
    return "katamari-knob-12"
  end
end

-- Calculate entity size and area
function cache_entity(entity)
  if ENTITY_BLACKLIST[entity.type] then return nil end
  if entity.name:sub(1, 9) == "katamari-" then return nil end
  if CUSTOM_ENTITIES[entity.name] then
    return CUSTOM_ENTITIES[entity.name]
  end
  return {size = get_size(entity), area = get_area(entity)}
end

-- Calculate item size and area
function cache_item(item)
  if ITEM_BLACKLIST[item.type] then
    -- We can pick up these items, but they don't increase katamari size
    return {size = 0, area = 0}
  end
  if item.type == "armor" then
    -- Armor should be the same size as the player
    return {size = 1, area = 1}
  end
  -- Default to item-on-ground dimensions
  return {size = 0.5, area = global.items["entity/item-on-ground"].area}
end

function cache_decorative(decorative)
  local size = math.min(get_width_height(decorative.collision_box))
  local area = size * size
  if DECORATIVE_WHITELIST[decorative.name] then
    area = DECORATIVE_WHITELIST[decorative.name]
  end
  return {size = 1, area = area}
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
  --TODO: game.print(name)
  -- Compare with old sprite
  if katamari.sprites[katamari.next_sprite] then
    if global.items[name].area < katamari.sprites[katamari.next_sprite].area then
      -- Must be bigger than the old sprite
      katamari.next_sprite = katamari.next_sprite + 1
      if katamari.next_sprite > MAX_SPRITES then
        katamari.next_sprite = 1
      end
      return
    else
      -- Destroy old sprite
      rendering.destroy(katamari.sprites[katamari.next_sprite].sprite_id)
    end
  end

  if not x or not y or not z then
    -- Generate random point on the sphere
    local lat = math.acos(math.random() * 2 - 1)
    local long = math.random() * TWO_PI
    local sin_lat = math.sin(lat)
    x = sin_lat * math.cos(long)
    y = sin_lat * math.sin(long)
    z = math.cos(lat)
  end

  -- Save sprite data
  local data = {
    name = name,
    area = global.items[name].area,
    orientation = math.random(),
    x = x,
    y = y,
    z = z,
  }
  katamari.sprites[katamari.next_sprite] = data
  katamari.next_sprite = katamari.next_sprite + 1
  if katamari.next_sprite > MAX_SPRITES then
    katamari.next_sprite = 1
  end

  -- Draw sprite
  draw_sprite(katamari, data)
end

function draw_circle(katamari)
  katamari.circle = rendering.draw_sprite{
    sprite = "katamari-circle",
    surface = katamari.entity.surface,
    target = katamari.entity,
    x_scale = katamari.radius * CIRCLE_SCALE,
    y_scale = katamari.radius * CIRCLE_SCALE,
    render_layer = "object",
  }
end

-- Draw sprite on the map
function draw_knob(katamari, knob)
  local render_layer = 128
  if knob.z > -0.0872 then
    render_layer = 130
  end
  local sprite_id = rendering.draw_sprite{
    sprite = get_knob_name(knob.z),
    surface = katamari.entity.surface,
    target = katamari.entity,
    target_offset = {knob.x * katamari.radius, knob.y * katamari.radius},
    x_scale = katamari.radius * KNOB_SCALE,
    y_scale = katamari.radius * KNOB_SCALE,
    orientation = math.atan2(knob.x, -knob.y) / TWO_PI,
    render_layer = render_layer,
  }
  knob.sprite_id = sprite_id
end

-- Draw sprite on the map
function draw_sprite(katamari, sprite)
  local sprite_id = rendering.draw_sprite{
    sprite = sprite.name,
    surface = katamari.entity.surface,
    target = katamari.entity,
    orientation = sprite.orientation,
    x_scale = global.items[sprite.name].size,
    y_scale = global.items[sprite.name].size,
  }
  sprite.sprite_id = sprite_id
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
