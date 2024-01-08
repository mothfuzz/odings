package collision
import "../transform"
import "core:math"


Shape :: enum {
	Bounding_Sphere,
	Bounding_Box,
	Mesh,
}

Collider :: struct {
	shape: Shape,
	//might be relative (actor) or absolute (terrain)
	//but any actor with a transform would encode relative coordinates here & use the transform for positioning.
	extents: Extents,
	planes: []Plane,
}

mesh_box :: proc(w, h, d: f32) -> (c: Collider) {
	v := [][3]f32{
		// front
		{-w / 2, -h / 2, +d / 2},
		{+w / 2, -h / 2, +d / 2},
		{+w / 2, +h / 2, +d / 2},
		{-w / 2, +h / 2, +d / 2},
		// back
		{-w / 2, -h / 2, -d / 2},
		{+w / 2, -h / 2, -d / 2},
		{+w / 2, +h / 2, -d / 2},
		{-w / 2, +h / 2, -d / 2},
	}
	c = mesh([]Plane{
		// front
		plane(v[0], v[1], v[2]),
		plane(v[2], v[3], v[0]),
		// right
		plane(v[1], v[5], v[6]),
		plane(v[6], v[2], v[1]),
		// back
		plane(v[7], v[6], v[5]),
		plane(v[5], v[4], v[7]),
		// left
		plane(v[4], v[0], v[3]),
		plane(v[3], v[7], v[4]),
		// bottom
		plane(v[4], v[5], v[1]),
		plane(v[1], v[0], v[4]),
		// top
		plane(v[3], v[2], v[6]),
		plane(v[6], v[7], v[3]),
	})
	return
}

mesh :: proc(planes: []Plane) -> (c: Collider) {
	c.planes = make([]Plane, len(planes))
	copy(c.planes, planes)
	c.extents = plane_extents(planes)
	c.shape = .Mesh
	return
}
bounding_box :: proc(w, h, d: f32) -> (c: Collider) {
	c = mesh_box(w, h, d)
	delete(c.planes)
	c.planes = nil
	c.shape = .Bounding_Box
	return
}
bounding_sphere :: proc(r: f32) -> (c: Collider) {
	c = bounding_box(r*2, r*2, r*2)
	c.shape = .Bounding_Sphere
	return
}

delete_collider :: proc(c: ^Collider) {
	if c.planes != nil {
		delete(c.planes)
		c.planes = nil
	}
}

//assuming that the length of planes is the same
transform_collider_to :: proc(c: ^Collider, t: ^transform.Transform, cc: ^Collider) {
	cc.shape = c.shape
	cc.extents = c.extents
	if c.planes != nil {
		copy(cc.planes, c.planes)
	}
	transform_collider_ref(cc, t)
}

transform_collider_copy :: proc(c: Collider, t: ^transform.Transform) -> (cc: Collider) {
	cc.shape = c.shape
	cc.extents = c.extents
	if c.shape == .Mesh {
		cc.planes = make([]Plane, len(c.planes))
		copy(cc.planes, c.planes)
	} else {
		cc.planes = nil
	}
	transform_collider_ref(&cc, t)
	return
}

//use this
transform_collider_ref :: proc(c: ^Collider, t: ^transform.Transform) {
	if t == nil {
		return
	}
	switch c.shape {
	case .Mesh:
		//this is dummy expensive.
		for p, i in c.planes {
			c.planes[i] = transform_plane(p, t)
		}
		c.extents = plane_extents(c.planes)
	case .Bounding_Box:
		c.extents = transform_extents(c.extents, t)
	case .Bounding_Sphere:
		c.extents.mini *= t.scale
		c.extents.maxi *= t.scale
		c.extents.mini += t.position
		c.extents.maxi += t.position
		//ignore rotation because a rotated sphere is the same sphere
	}
	return
}

transform_collider :: proc{transform_collider_copy, transform_collider_ref, transform_collider_to}

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

collider_overlap :: proc(a: ^Collider, b: ^Collider) -> bool {
	ae := a.extents
	be := b.extents
	//just check boxes for now
	//if they're both meshes we need to do some SAT or something
	if a.shape != .Bounding_Sphere && b.shape != .Bounding_Sphere {
		return box_overlap(ae.mini, ae.maxi, be.mini, be.maxi)
	}
	//otherwise one of them is a sphere
	ra := (ae.maxi.x - ae.mini.x) / 2.0
	rb := (be.maxi.x - be.mini.x) / 2.0
	ca := (ae.mini + ae.maxi) / 2.0
	cb := (be.mini + be.maxi) / 2.0
	if a.shape == .Bounding_Sphere && b.shape == .Bounding_Sphere {
		return sphere_overlap(ca, ra, cb, rb)
	}
	if a.shape == .Bounding_Sphere && b.shape != .Bounding_Sphere {
		return sphere_box_overlap(ca, ra, be.mini, be.maxi)
	}
	if b.shape == .Bounding_Sphere && a.shape != .Bounding_Sphere {
		return sphere_box_overlap(cb, rb, ae.mini, ae.maxi)
	}

	return false
}

overlap :: proc{sphere_overlap, box_overlap, sphere_box_overlap, collider_overlap}
