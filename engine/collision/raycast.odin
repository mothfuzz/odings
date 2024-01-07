package collision
import "core:fmt"


/*
scene.RayHit :: struct {
	id: ActorId,
	using hit: collision.RayHit,
}
*/
//scene.raycast :: proc(origin: [3]f32, direction: [3]f32, distance: int = 0) -> []scene.RayHit
//scene.nearest :: proc(origin: [3]f32, direction: [3]f32, distance: int = 0) -> (scene.RayHit, bool)

RayHit :: struct {
	plane: Plane,
	point: [3]f32,
	distance: f32,
}

//returns whether it hit, and, if it did, what plane/point it hit.
raycast :: proc(origin: [3]f32, direction: [3]f32, planes: []Plane) -> (RayHit, bool) {
	for p in planes {
		r1 := dot(direction, p.normal)
		r2 := dot(p.origin - origin, p.normal)
		t := r2 / r1 //ratio of the 2 projections = distance
		i := origin + direction * t
		if t >= 0 && point_in_triangle(i, expand_values(p.points)) {
			return {p, i, t}, true
		}
	}
	return {}, false
}
