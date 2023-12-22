package collision

import "../transform"

Plane :: struct {
	origin: [3]f32,
	normal: [3]f32,
	points: [3][3]f32,
}

plane :: proc(a, b, c: [3]f32) -> (p: Plane) {
	//centroid
	p.origin = (a + b + c)/3.0
	//(B - A) x (C - A)
	p.normal = normalize(cross(b - a, c - a))
	p.points = {a, b, c}
	return
}

transform_plane :: proc(p: Plane, t: ^transform.Transform) -> (pp: Plane) {
	if t == nil {
		return p
	}
	model := transform.mat4(t)
	pp.origin = (model * mat4point(p.origin)).xyz
	pp.normal = normalize((model * mat4vec(p.normal)).xyz)
	pp.points[0] = (model * mat4point(p.points[0])).xyz
	pp.points[1] = (model * mat4point(p.points[1])).xyz
	pp.points[2] = (model * mat4point(p.points[2])).xyz
	return
}
