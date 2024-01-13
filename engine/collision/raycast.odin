package collision
import "core:fmt"

RayHit :: struct {
	plane: Plane,
	point: [3]f32,
	distance: f32,
}

//returns whether it hit, and, if it did, where it hit.
raycast :: proc(origin: [3]f32, direction: [3]f32, p: Plane) -> (RayHit, bool) {
	r1 := dot(direction, p.normal)
	r2 := dot(p.origin - origin, p.normal)
	t := r2 / r1 //ratio of the 2 projections = distance
	i := origin + direction * t
	if t >= 0 && point_in_triangle(i, tri(p)) {
		return {p, i, t}, true
	}
	return {}, false
}
