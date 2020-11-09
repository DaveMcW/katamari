-- Default entity dimensions are:
-- size = width or height of largest bounding box
-- area = area of largest bounding box
--
-- When the default dimensions are inappropriate, they can be overridden here.
return {
  -- These icons only show a piece of the entity
  ["arithmetic-combinator"] = {size = 1, area = 2},
  ["artillery-turret"] = {size = 4, area = 9},
  ["artillery-wagon"] = {size = 4, area = 12},
  ["cargo-wagon"] = {size = 4, area = 12},
  ["decider-combinator"] = {size = 1, area = 2},
  ["locomotive"] = {size = 4, area = 12},
  ["fluid-wagon"] = {size = 3, area = 12},
  ["steam-turbine"] = {size = 3.5, area = 15},
  -- These selection boxes are smaller than the graphics
  ["car"] = {size = 3, area = 4},
  ["spidertron"] = {size = 4, area = 16},
  ["small-biter"] = {size = 2, area = 1.2},
  ["small-spitter"] = {size = 2, area = 1.2},
  ["small-worm-turret"] = {size = 4, area = 4.4},
  ["medium-biter"] = {size = 3, area = 2.5},
  ["medium-spitter"] = {size = 2.5, area = 2.5},
  ["medium-worm-turret"] = {size = 5, area = 5.5},
  ["big-biter"] = {size = 4, area = 3.8},
  ["big-spitter"] = {size = 4, area = 3.8},
  ["big-worm-turret"] = {size = 6, area = 6.6},
  ["behemoth-biter"] = {size = 5, area = 5},
  ["behemoth-spitter"] = {size = 5, area = 5},
  ["behemoth-worm-turret"] = {size = 7, area = 7.7},
  ["cliff"] = {size = 4, area = 12},
  -- These selection boxes are larger than the graphics
  ["tank"] = {size = 3, area = 8.8},
  ["crude-oil"] = {size = 2, area = 4},
}
