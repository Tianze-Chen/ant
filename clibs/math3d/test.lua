local math3d = require "math3d"
--[[
	local vec = math3d.ref "vector"	-- new vector ref object
	local mat = math3d.ref "matrix"	-- new matrix ref object

	= : assign an object to a ref object

	P : pop and return id ( ... , 1 -> ... )
	v : pop and return vector4 pointer ( ... , 1 -> ... )
	m : pop and return matrix pointer ( ... , 1 -> ... )
	f : pop and return the first float of a vector4 ( ... , 1 -> ... )
	V : top to string for debug ( ... -> ... )
	1-9 : dup stack index (..., 1 -> ..., 1,1)
		1 : (..., 1 -> ..., 1,1)
		2 : (..., 2, 1 -> ..., 2, 1, 2)
		...
		9 : (...,9,8,7,6,5,4,3,2,1 -> ... , 9,8,7,6,5,4,3,2,1,9)
		22 means ( ..., a, b -> ..., a, b, a, b)
	S : swap stack top (..., 1,2 -> ..., 2,1 )
	R : remove stack top ( ..., 1 -> ... )

	{ 1,2,3,4 }	  push vector4(1,2,3,4)
	{ 1,2,3,4, .... 16 } push matrix4x4
	{} push identity matrix
	{ s = 2 } push scaled matrix (2,2,2)
	{ sx = 1, sy = 2, sz = 3 }
	{ rx = 1, ry = 0, rz = 0 }
	{ tx = 0, ty = 0 , tz = 1 }

	{ type = "proj", fov = 60, aspect = 1024/768 , n = 0.1, f = 100 }	-- proj mat
	{ type = "ortho", l = 0, r = 1, b = 1, t = 0, n = 0, f = 100, h = false } -- ortho mat
	* matrix mul ( ..., 1,2 - > ..., 1*2 )
	* vector4 * matrix4x4 / vec4 * vec4
	+ vector4 + vector4 ( ..., 1,2 - > ..., 1+2 )
	- vec4 - vec4 ( ..., 1,2 - > ..., 1-2 )
	. vec3 * vec3  ( ..., 1,2 -> ..., { dot(1,2) , 0 , 0 ,1 } )
	x cross (vec3 , vec3) ( ..., 1, 2, -> ... , cross(1,2) )
	i inverted matrix  ( ..., 1 -> ..., invert(1) )
	t transposed matrix ( ..., 1 -> ..., transpose(1) )
	n normalize vector3 ( ..., 1 -> ..., {normalize(1) , 1} )
	l generate lootat matrix ( ..., eye, at -> ..., lookat(eye,at) )
]]

local vec = math3d.ref "vector"
local mat = math3d.ref "matrix"	-- matrix ref

local stack = math3d.new()


local v = stack( { type = "proj", fov = 60, aspect = 1024/768 } , "VR")	-- make a proj mat
print(v)
local v1,m1 = stack( { s = 2 } , "VP" )	-- push scale 2x matrix
print(v1,m1)
local v2,m2 = stack( { rx = 1 } , "VP" )	-- push rot (1,0,0) matrix
print(v2,m2)
local m = stack(m1,m2,"*V")
print(m)

stack( vec, { 1,2,3,4 } , "1+=")	-- dup {1,2,3,4} add self and then assign to vec

local vv = stack({1, 2, 3, 1}, {2, 2, 2, 1}, "*V")
print("vec4 mul : " .. vv)

--lookat
stack(mat, "1=")	-- init mat to an indentity matrix (dup self and assign)

local lookat = stack({0, 0, 0, 1}, {0, 0, 1, 0}, "lP")	-- calc lookat matrix
mat(lookat) -- assign lookat matrix to mat
print("lookat matrix : " , mat)
print(math3d.type(mat))	-- matrix true (true means marked)

math3d.reset(stack)
print(vec, ~vec)	-- string and lightuserdata
mat()	-- clear mat

local t = stack(vec, "P")
print(math3d.type(t))	-- vector true
print(stack( t,"Vv"))	-- string lightuserdata

print(stack(math3d.constant "identvec", "VR"))
print(stack(math3d.constant "identmat", "VR"))	-- R: remove top