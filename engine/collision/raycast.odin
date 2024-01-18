package collision
import "core:fmt"

Ray_Hit :: struct {
	plane: Plane,
	point: [3]f32,
	distance: f32,
}

line_in_polygon :: proc(o: [3]f32, p: [3]f32, plane: Plane) -> bool {
	e := len(plane.points) //edges
	direction := 0
	for i in 0..<e {
		v0 := plane.points[(i+0)%e] - p
		v1 := plane.points[(i+1)%e] - p
		n := normalize(cross(v1, v0))
		angle := dot(p - o, n)
		if direction == 0 {
			direction = angle < 0?-1:1
		} else if direction == -1 && angle > 0 {
			return false
		} else if direction == 1 && angle < 0 {
			return false
		}
	}
	return true
}

//returns whether it hit, and, if it did, where it hit.
raycast :: proc(origin: [3]f32, direction: [3]f32, p: Plane) -> (Ray_Hit, bool) {
	r1 := dot(direction, p.normal)
	r2 := dot(p.origin - origin, p.normal)
	t := r2 / r1 //ratio of the 2 projections = distance
	i := origin + direction * t
	if t >= 0 && line_in_polygon(origin, i, p) {
		return {p, i, t}, true
	}
	return {}, false
}
