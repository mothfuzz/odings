package collision
import "../transform"
import "core:math"

Sphere :: struct {
	center: [3]f32,
	radius: f32,
}
Capsule :: struct {
	a, b: [3]f32,
	radius: f32,
}
Bounding_Box :: struct {} //empty because relevant info is stored in Extents anyway
Convex :: struct {
	planes: []Plane,
}
Mesh :: struct {
	planes: []Plane,
}


//roughly in order of complexity.
Shape :: union {
	Bounding_Box,
	Sphere,
	Capsule, //capsule = find closest perpendicular point on A-B line, check if distance smaller than radius. Easy!
	//Box is just a certain kind of convex shape.
	Convex, //SAT - separating planes - check all face normals plus every cross product pair for the inbetweens.
	//we would have to submit: series of Polygons with normal + points
	//ordering shoudln't matter if we submit the normal ourselves.
	Mesh,
}

//convex_box :: proc(w, h, d: f32) -> (c: Collider)
//convex_prism :: proc(w, h, d: f32) -> (c: Collider)
//convex_cylinder :: proc(w, h, d: f32, n: int) -> (c: Collider)
//convex_.......

Collider :: struct {
	shape: Shape,
	//might be relative (actor) or absolute (terrain)
	//but any actor with a transform would encode relative coordinates here & use the transform for positioning.
	extents: Extents,
}

mesh :: proc(planes: []Plane) -> (c: Collider) {
	c.shape = Mesh{clone_planes(planes)}
	c.extents = plane_extents(planes)
	return
}

convex :: proc(planes: []Plane) -> (c: Collider) {
	c.shape = Convex{clone_planes(planes)}
	c.extents = plane_extents(planes)
	return
}

bounding_box :: proc(w, h, d: f32, o: [3]f32 = {0, 0, 0}) -> (c: Collider) {
	c.shape = Bounding_Box{}
	c.extents = {{o.x - w / 2, o.y - h / 2, o.z - d / 2},
				 {o.x + w / 2, o.y + h / 2, o.z + d / 2}}
	return
}
bounding_sphere :: proc(r: f32, o: [3]f32 = {0, 0, 0}) -> (c: Collider) {
	c.shape = Sphere{o, r}
	c.extents = {o-r, o+r}
	return
}
capsule :: proc(a, b: [3]f32, r: f32) -> (c: Collider) {
	c.shape = Capsule{a, b, r}
	c.extents = capsule_extents(&c.shape.(Capsule))
	return
}

delete_collider :: proc(c: ^Collider) {
	if mesh, ok := &c.shape.(Mesh); ok {
		delete_planes(mesh.planes)
		mesh.planes = nil
	}
	if hull, ok := &c.shape.(Convex); ok {
		delete_planes(hull.planes)
		hull.planes = nil
	}
}

//assuming that cc has planes & length of planes is the same as c
transform_collider_ref :: proc(c: ^Collider, t: ^transform.Transform, cc: ^Collider) {
	if t == nil {
		return
	}
	switch s in &c.shape {
	case Mesh:
		mesh := cc.shape.(Mesh)
		transform_planes(s.planes, t, mesh.planes)
		cc.extents = plane_extents(mesh.planes)
	case Convex:
		hull := cc.shape.(Convex)
		transform_planes(s.planes, t, hull.planes)
		cc.extents = plane_extents(hull.planes)
	case Bounding_Box:
		cc.extents = transform_extents(c.extents, t)
	case Sphere:
		cc.extents = c.extents
		cc.extents.mini *= t.scale
		cc.extents.maxi *= t.scale
		cc.extents.mini += t.position
		cc.extents.maxi += t.position
		//ignore rotation because a rotated sphere is the same sphere
	case Capsule:
		cc.shape = transform_capsule(&s, t)
		cc.extents = capsule_extents(&cc.shape.(Capsule))
	}
	return
}

import "core:mem"
clone :: proc(c: ^Collider, allocator: mem.Allocator = context.allocator) -> (cc: Collider) {
	cc.shape = c.shape
	cc.extents = c.extents
	if mesh, ok := c.shape.(Mesh); ok {
		cc.shape = Mesh{clone_planes(mesh.planes, allocator)}
	}
	if hull, ok := c.shape.(Convex); ok {
		cc.shape = Convex{clone_planes(hull.planes, allocator)}
	}
	return
}

transform_collider_copy :: proc(c: ^Collider, t: ^transform.Transform, allocator: mem.Allocator = context.allocator) -> (cc: Collider) {
	cc = clone(c, allocator)
	transform_collider_ref(c, t, &cc)
	return
}

transform_collider :: proc{transform_collider_copy, transform_collider_ref}

sphere_overlap :: proc(ca: [3]f32, ra: f32, cb: [3]f32, rb: f32) -> bool {
	return length(cb - ca) <= ra+rb
}
box_overlap :: proc(mina: [3]f32, maxa: [3]f32, minb: [3]f32, maxb: [3]f32) -> bool {
	return mina.x <= maxb.x &&
		maxa.x >= minb.x &&
		mina.y <= maxb.y &&
		maxa.y >= minb.y &&
		mina.z <= maxb.z &&
		maxa.z >= minb.z
}
sphere_box_overlap :: proc(ca: [3]f32, ra: f32, minb: [3]f32, maxb: [3]f32) -> bool {
	x := max(minb.x, min(ca.x, maxb.x))
	y := max(minb.y, min(ca.y, maxb.y))
	z := max(minb.z, min(ca.z, maxb.z))
	p := [3]f32{x, y, z}
	return len2(p - ca) <= ra*ra
}

//assuming already transformed, if at all.
collider_overlap :: proc(a: ^Collider, b: ^Collider) -> bool {
	ea := a.extents
	eb := b.extents

	#partial switch sa in a.shape {
		case Sphere:
		#partial switch sb in b.shape {
			case Sphere:
			return sphere_overlap(sa.center, sa.radius, sb.center, sb.radius)
			case Bounding_Box:
			return sphere_box_overlap(sa.center, sa.radius, eb.mini, eb.maxi)
		}
		case Bounding_Box:
		#partial switch sb in b.shape {
			case Sphere:
			return sphere_box_overlap(sb.center, sb.radius, ea.mini, ea.maxi)
			case Bounding_Box:
			return box_overlap(ea.mini, ea.maxi, eb.mini, eb.maxi)
		}
		//TODO: add tests for capsules & hulls.
		//modify terrain collision to be usable here as well.
	}

	//if none of our more specific cases work, just check the extents
	return box_overlap(ea.mini, ea.maxi, eb.mini, eb.maxi)
}

overlap :: proc{sphere_overlap, box_overlap, sphere_box_overlap, collider_overlap}
