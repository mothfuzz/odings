package collision

import "core:math"

mat4point :: proc(v: [3]f32) -> [4]f32 {
	return {v.x, v.y, v.z, 1.0}
}
mat4vec :: proc(v: [3]f32) -> [4]f32 {
	return {v.x, v.y, v.z, 0.0}
}


len2 :: proc(v: [3]f32) -> f32 {
	return v.x * v.x + v.y * v.y + v.z * v.z
}
length :: proc(v: [3]f32) -> f32 {
	return math.sqrt(len2(v))
}

dot :: proc(a, b: [3]f32) -> f32 {
	return a.x * b.x + a.y * b.y + a.z * b.z
}

cross :: proc(a, b: [3]f32) -> (c: [3]f32) {
	c.x = a.y*b.z - a.z*b.y
	c.y = a.z*b.x - a.x*b.z
	c.z = a.x*b.y - a.y*b.x
	return
}
normalize :: proc(v: [3]f32) -> [3]f32 {
	return v / length(v)
}

between :: proc(v, a, b: f32) -> bool {
	return v >= a && v <= b
}
