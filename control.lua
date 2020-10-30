local TWO_PI = 2 * math.pi

function set_car(car)
  -- Reset everything
  global.katamaris = {}
  rendering.clear("katamari")

  -- Add car
  local data = {
    entity = car,
    last_position = car.position,
    lat = 0,
    long = 0,
    sprites = {},
    size = 3,
  }
  global.katamaris[car.unit_number] = data
end

function random_point_on_unit_sphere()
  local lat = math.acos(math.random() * 2 - 1)
  local long = math.random() * TWO_PI
  local x = math.sin(lat) * math.cos(long)
  local y = math.sin(lat) * math.sin(long)
  local z = math.cos(lat)
  return x, y, z
end

function add_sprite(car, name)
  local sprite_id = rendering.draw_sprite{
    sprite = "item/" .. name,
    surface = car.surface,
    target = car,
  }
  local x, y, z = random_point_on_unit_sphere()
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

function rotate_offset(angle, x, y, z)
  -- Rotate around Z axis
  local rx = x * math.cos(angle) + y * math.sin(angle)
  local ry = x * -math.sin(angle) + y * math.cos(angle)
  return rx, ry, z
end

function rotate_long(angle, x, y, z)
  -- Rotate around Y axis
  local rx = x * math.cos(angle) + z * -math.sin(angle)
  local rz = x * math.sin(angle) + z * math.cos(angle)
  return rx, y, rz
end

function rotate_lat(angle, x, y, z)
  -- Rotate around X axis
  local ry = y * math.cos(angle) + z * math.sin(angle)
  local rz = y * -math.sin(angle) + z * math.cos(angle)
  return x, ry, rz
end

function draw_sprites(car)
  for i = 1, #car.sprites do
    local sprite = car.sprites[i]
    local x, y, z = sprite.x, sprite.y, sprite.z
    -- Rotate offset
    --x, y, z = rotate_offset(car.long, x, y, z)
    -- Rotate latitude
    x, y, z = rotate_lat(car.lat, x, y, z)
    -- Rotate longitude
    x, y, z = rotate_long(car.entity.orientation * TWO_PI, x, y, z)
    -- Update position
    rendering.set_target(sprite.sprite_id, car.entity, {x * car.size, z * car.size})
    rendering.set_x_scale(sprite.sprite_id, sprite.size * (y/4 + 1))
    rendering.set_y_scale(sprite.sprite_id, sprite.size * (y/4 + 1))
    rendering.set_render_layer(sprite.sprite_id, math.floor(y * 30 + 129))
  end
end

function on_tick()
  for _, car in pairs(global.katamaris) do
    -- Read car's progress
    local dx = car.entity.position.x - car.last_position.x
    local dy = car.entity.position.y - car.last_position.y
    car.last_position = car.entity.position

    -- Calculate distance travelled, in radians
    local distance = math.sqrt(dx*dx + dy*dy) / car.size
    if car.entity.speed < 0 then
      distance = distance * -1
    end
    car.lat = car.lat + distance

    -- Add 5% drift
    car.long = car.long + distance * 0.05

    draw_sprites(car)
  end

end

script.on_event(defines.events.on_tick, on_tick)
