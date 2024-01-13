package collision

import "../transform"
import "core:slice"

Plane :: struct {
	origin: [3]f32,
	normal: [3]f32,
	points: [][3]f32,
}

//points assumed coplanar
plane :: proc(points: [][3]f32) -> (p: Plane) {
	assert(len(points) >= 3)

	p.points = make([][3]f32, len(points))
	copy(p.points, points)

	//centroid
	for point in &p.points {
		p.origin += point
	}
	p.origin /= f32(len(points))

	//(B - A) x (C - A)
	a, b, c := tri(p)
	p.normal = normalize(cross(b - a, c - a))

	return
}

tri :: proc(p: Plane) -> ([3]f32, [3]f32, [3]f32) {
	return p.points[0], p.points[1], p.points[2]
}

transform_plane :: proc(p: Plane, t: ^transform.Transform, pp: ^Plane) {
	if t == nil {
		return
	}
	model := transform.mat4(t)
	pp.origin = (model * mat4point(p.origin)).xyz
	pp.normal = normalize((model * mat4vec(p.normal)).xyz)
	for p, i in p.points {
		pp.points[i] = (model * mat4point(p)).xyz
	}
}

transform_planes :: proc(planes: []Plane, t: ^transform.Transform, tplanes: []Plane) {
	//this is dummy expensive.
	for p, i in planes {
		transform_plane(p, t, &tplanes[i])
	}
}

plane_extents :: proc(planes: []Plane) -> Extents {
	inf := max(f32)
	mini := [3]f32{+inf, +inf, +inf}
	maxi := [3]f32{-inf, -inf, -inf}
	for p in planes {
		for point in p.points {
			mini.x = min(mini.x, point.x)
			mini.y = min(mini.y, point.y)
			mini.z = min(mini.z, point.z)
			maxi.x = max(maxi.x, point.x)
			maxi.y = max(maxi.y, point.y)
			maxi.z = max(maxi.z, point.z)
		}
	}
	return Extents{mini, maxi}
}

import "core:mem"
clone_planes :: proc(planes: []Plane, allocator: mem.Allocator = context.allocator) -> (ps: []Plane) {
	ps = make([]Plane, len(planes), allocator)
	copy(ps, planes)
	for p, i in planes {
		ps[i].points = make([][3]f32, len(p.points), allocator)
		copy(ps[i].points, p.points)
	}
	return
}

delete_planes :: proc(planes: []Plane) {
	if planes != nil {
		for p in planes {
			delete(p.points)
		}
		delete(planes)
	}
}

get_planes :: proc(c: ^Collider) -> (planes: []Plane) {
	if mesh, ok := c.shape.(Mesh); ok {
		planes = mesh.planes
	}
	if hull, ok := c.shape.(Convex); ok {
		planes = hull.planes
	}
	return
}
