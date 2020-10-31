local TWO_PI = 2 * math.pi

function on_init()
  global.katamaris = {}
  on_mods_changed()
end

function on_mods_changed()
  -- Remove missing sprites
  for _, katamari in pairs(global.katamaris) do
    local i = 1
    while i <= #katamari.sprites do
      if rendering.is_valid(ball.sprites[i].sprite_id) then
        i = i + 1
      else
        table.remove(katamari.sprites, i)
      end
    end
  end
end

function set_car(car)
  -- Reset everything
  global.katamaris = {}
  rendering.clear("katamari")

  -- Add car
  local data = {
    entity = car,
    last_position = car.position,
    sprites = {},
    radius = 1.5,
    w = 1,  -- Rotation is stored as a quaternion
    x = 0,
    y = 0,
    z = 0,
  }
  global.katamaris[car.unit_number] = data
end

function add_sprite(car, name, x, y, z)
  local scale = 1
  local sprite_id = rendering.draw_sprite{
    sprite = name,
    surface = car.surface,
    target = car,
    x_scale = scale,
    y_scale = scale,
  }
  if not x or not y or not z then
    x, y, z = random_point_on_unit_sphere()
  end
  local data = {
    name = name,
    sprite_id = sprite_id,
    size = 1,
    x = x,
    y = y,
    z = z,
  }
  table.insert(global.katamaris[car.unit_number].sprites, data)
end

function on_tick()
  for _, car in pairs(global.katamaris) do
    update_car(car)
  end
end

function update_car(car)
  -- Read car's progress
  local dx = car.entity.position.x - car.last_position.x
  local dy = car.entity.position.y - car.last_position.y
  if dx == 0 and dy == 0 then
    -- Car has not moved
    return
  end
  car.last_position = car.entity.position

  -- Calculate distance travelled
  local distance = math.sqrt(dx*dx + dy*dy)
  if car.entity.speed < 0 then
    distance = distance * -1
  end

  -- Calculate rotation angle and axis
  local rotation_angle = distance / car.radius
  local axis_angle = car.entity.orientation * TWO_PI
  local axis_x = math.cos(axis_angle)
  local axis_y = math.sin(axis_angle)

  -- Convert to a quaternion
  -- https://www.cprogramming.com/tutorial/3d/quaternions.html
  local sineA = math.sin(rotation_angle/2)
  local w = math.cos(rotation_angle/2)
  local x = axis_x * sineA
  local y = axis_y * sineA
  -- local z = 0

  -- Multiply by the car's quaternion
  -- https://www.cprogramming.com/tutorial/3d/quaternions.html
  local new_w = w*car.w - x*car.x - y*car.y
  local new_x = w*car.x + x*car.w + y*car.z
  local new_y = w*car.y - x*car.z + y*car.w
  local new_z = w*car.z + x*car.y - y*car.x

  -- Update the car's quaternion
  car.w = new_w
  car.x = new_x
  car.y = new_y
  car.z = new_z
  normalize_quaternion(car)

  -- Draw sprites
  draw_sprites(car)
end

function draw_sprites(car)
  -- Build rotation matrix
  -- https://en.wikipedia.org/wiki/Rotation_matrix#Quaternion
  local a1 = 1 - 2*car.y*car.y - 2*car.z*car.z
  local a2 = 2*car.x*car.y - 2*car.w*car.z
  local a3 = 2*car.x*car.z + 2*car.w*car.y
  local b1 = 2*car.x*car.y + 2*car.w*car.z
  local b2 = 1 - 2*car.x*car.x - 2*car.z*car.z
  local b3 = 2*car.y*car.z - 2*car.w*car.x
  local c1 = 2*car.x*car.z - 2*car.w*car.y
  local c2 = 2*car.y*car.z + 2*car.w*car.x
  local c3 = 1 - 2*car.x*car.x - 2*car.y*car.y

  for i = 1, #car.sprites do
    local sprite = car.sprites[i]

    -- Rotate sprite
    local x = a1*sprite.x + a2*sprite.y + a3*sprite.z
    local y = b1*sprite.x + b2*sprite.y + b3*sprite.z
    local z = c1*sprite.x + c2*sprite.y + c3*sprite.z

    -- Update position
    rendering.set_target(sprite.sprite_id, car.entity, {x * car.radius, y * car.radius})
    rendering.set_render_layer(sprite.sprite_id, math.floor(z * 30 + 129))
  end
end

function normalize_quaternion(car)
  local magnitude = car.w*car.w + car.x*car.x + car.y*car.y + car.z*car.z
  if magnitude < 1.01 and magnitude > 0.99 then
    return
  end
  magnitude = math.sqrt(magnitude)
  car.w = car.w / magnitude
  car.x = car.x / magnitude
  car.y = car.y / magnitude
  car.z = car.z / magnitude
end

function random_point_on_unit_sphere()
  local lat = math.acos(math.random() * 2 - 1)
  local long = math.random() * TWO_PI
  local x = math.sin(lat) * math.cos(long)
  local y = math.sin(lat) * math.sin(long)
  local z = math.cos(lat)
  return x, y, z
end

script.on_init(on_init)
script.on_configuration_changed(on_mods_changed)
script.on_event(defines.events.on_tick, on_tick)
