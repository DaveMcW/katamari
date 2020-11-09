-- http://dmccooey.com/polyhedra/RsnubDodecahedron.txt
local phi = (1 + math.sqrt(5)) / 2
local x = math.pow((phi + math.sqrt(phi-5/27))/2, 1/3) + math.pow((phi - math.sqrt(phi-5/27))/2, 1/3)
local diameter = math.sqrt(4*x*x - x*x*x*x + 2*phi*x - phi - phi/x + 1)

local A  = math.sqrt((x - 1 - 1/x) * phi) / diameter
local B  = x * math.sqrt(3 - x * x) / diameter
local C = math.sqrt(x * (x + phi) + 1) / diameter
local D  = math.sqrt(3 - x * x) / diameter
local E  = x * math.sqrt(1 - x + (1 + phi) / x) / diameter
local F = math.sqrt(x * x + x) / diameter
local G  = x * x * math.sqrt((x - 1 - 1/x) * phi) / diameter
local H  = math.sqrt(x + 1 - phi) / diameter
local I = math.sqrt(x * x * (1 + 2 * phi) - phi) / phi / diameter
local J  = x * x * math.sqrt(3 - x * x) / diameter
local K  = x * math.sqrt((x - 1 - 1/x) * phi) / diameter
local L = phi * math.sqrt(x * (x + phi) + 1) / x / diameter
local M  = math.sqrt((x + 2) * phi + 2) / phi / diameter
local N  = math.sqrt(1 - x + (1 + phi) / x) / diameter
local P = x * math.sqrt(x * (1 + phi) - phi) / phi / diameter

-- print(A)
-- print(B)
-- print(C)
-- print(D)
-- print(E)
-- print(F)
-- print(G)
-- print(H)
-- print(I)
-- print(J)
-- print(K)
-- print(L)
-- print(M)
-- print(N)
-- print(P)

return {
  {x= A, y= B, z= C},
  {x= A, y=-B, z=-C},
  {x=-A, y= B, z=-C},
  {x=-A, y=-B, z= C},
  {x= C, y= A, z= B},
  {x=-C, y= A, z=-B},
  {x=-C, y=-A, z= B},
  {x= C, y=-A, z=-B},
  {x= B, y= C, z= A},
  {x=-B, y=-C, z= A},
  {x= B, y=-C, z=-A},
  {x=-B, y= C, z=-A},
  {x= D, y= E, z= F},
  {x= D, y=-E, z=-F},
  {x=-D, y= E, z=-F},
  {x=-D, y=-E, z= F},
  {x= F, y= D, z= E},
  {x=-F, y= D, z=-E},
  {x=-F, y=-D, z= E},
  {x= F, y=-D, z=-E},
  {x= E, y= F, z= D},
  {x=-E, y=-F, z= D},
  {x= E, y=-F, z=-D},
  {x=-E, y= F, z=-D},
  {x= G, y= H, z= I},
  {x= G, y=-H, z=-I},
  {x=-G, y= H, z=-I},
  {x=-G, y=-H, z= I},
  {x= I, y= G, z= H},
  {x=-I, y= G, z=-H},
  {x=-I, y=-G, z= H},
  {x= I, y=-G, z=-H},
  {x= H, y= I, z= G},
  {x=-H, y=-I, z= G},
  {x= H, y=-I, z=-G},
  {x=-H, y= I, z=-G},
  {x= J, y= K, z=-L},
  {x= J, y=-K, z= L},
  {x=-J, y= K, z= L},
  {x=-J, y=-K, z=-L},
  {x=-L, y= J, z= K},
  {x= L, y= J, z=-K},
  {x= L, y=-J, z= K},
  {x=-L, y=-J, z=-K},
  {x= K, y=-L, z= J},
  {x=-K, y= L, z= J},
  {x= K, y= L, z=-J},
  {x=-K, y=-L, z=-J},
  {x= M, y= N, z=-P},
  {x= M, y=-N, z= P},
  {x=-M, y= N, z= P},
  {x=-M, y=-N, z=-P},
  {x=-P, y= M, z= N},
  {x= P, y= M, z=-N},
  {x= P, y=-M, z= N},
  {x=-P, y=-M, z=-N},
  {x= N, y=-P, z= M},
  {x=-N, y= P, z= M},
  {x= N, y= P, z=-M},
  {x=-N, y=-P, z=-M},
  {x =  0.0000, y =  0.8507, z =  0.5257},
  {x =  0.0000, y =  0.8507, z = -0.5257},
  {x =  0.0000, y = -0.8507, z =  0.5257},
  {x =  0.0000, y = -0.8507, z = -0.5257},
  {x =  0.5257, y =  0.0000, z =  0.8507},
  {x =  0.5257, y =  0.0000, z = -0.8507},
  {x = -0.5257, y =  0.0000, z =  0.8507},
  {x = -0.5257, y =  0.0000, z = -0.8507},
  {x =  0.8507, y =  0.5257, z =  0.0000},
  {x =  0.8507, y = -0.5257, z =  0.0000},
  {x = -0.8507, y =  0.5257, z =  0.0000},
  {x = -0.8507, y = -0.5257, z =  0.0000},
}
