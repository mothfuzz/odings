package collision

import "../transform"
import "core:math"

Extents :: struct {
	mini: [3]f32,
	maxi: [3]f32,
}

transform_extents :: proc(e: Extents, t: ^transform.Transform) -> Extents {
	if t == nil {
		return e
	}
	m4 := transform.mat4(t)
	points := [8][3]f32{
		{e.mini.x, e.mini.y, e.mini.z},
		{e.maxi.x, e.mini.y, e.mini.z},
		{e.mini.x, e.maxi.y, e.mini.z},
		{e.maxi.x, e.maxi.y, e.mini.z},
		{e.mini.x, e.mini.y, e.maxi.z},
		{e.maxi.x, e.mini.y, e.maxi.z},
		{e.mini.x, e.maxi.y, e.maxi.z},
		{e.maxi.x, e.maxi.y, e.maxi.z},
	}
	inf := max(f32)
	mini := [3]f32{1, 1, 1} * +inf
	maxi := [3]f32{1, 1, 1} * -inf
	for p in points {
		//multiply by homogenous coords
		pp: [3]f32 = (m4 * mat4point(p)).xyz
		if pp.x < mini.x {
			mini.x = pp.x
		}
		if pp.y < mini.y {
			mini.y = pp.y
		}
		if pp.z < mini.z {
			mini.z = pp.z
		}
		if pp.x > maxi.x {
			maxi.x = pp.x
		}
		if pp.y > maxi.y {
			maxi.y = pp.y
		}
		if pp.z > maxi.z {
			maxi.z = pp.z
		}
	}
	return Extents{mini, maxi}
}
