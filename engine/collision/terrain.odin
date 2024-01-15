package collision

inside_vertices :: proc(p: [3]f32, r2: f32, plane: Plane) -> bool {
	for i in plane.points {
		if len2(p - i) <= r2 {
			return true
		}
	}
	return false
}
sphere_edge :: proc(p: [3]f32, r2: f32, a, b: [3]f32) -> bool {
	d := b - a
	proj := dot(p - a, d) //project p - a onto d (length sqr)
	t := proj / len2(d) //distance along projection / length of line = percentage to nearest perpendicular point
	if between(t, 0, 1) {
		return len2(p - (a + t * d)) <= r2
	}
	return false
}
inside_edges :: proc(p: [3]f32, r2: f32, plane: Plane) -> bool {
	e := len(plane.points)
	for i in 0..<e {
		a := plane.points[(i+0)%e]
		b := plane.points[(i+1)%e]
		if sphere_edge(p, r2, a, b) {
			return true
		}
	}
	return false
}

//checks if a coplanar point is in a triangle
point_in_triangle :: proc(p: [3]f32, a, b, c: [3]f32) -> bool {
	norm := cross(b - a, c - a)
	//compute barycentric coords
	ABC := dot(norm, cross(b - a, c - a))
	PBC := dot(norm, cross(b - p, c - p))
	PCA := dot(norm, cross(c - p, a - p))
	//PAB := dot(norm, cross(a - p, b - p))

	u := PBC / ABC // alpha
	v := PCA / ABC // beta
	//w := PAB / ABC // gamma
	w := 1.0 - u - v // gamma

	return between(u, 0, 1) &&
		between(v, 0, 1) &&
		between(w, 0, 1)
}

import "core:fmt"
move_against_terrain :: proc(position: [3]f32, radius: f32, velocity: [3]f32, planes: []Plane) -> [3]f32 {
	velocity := velocity
	for p in planes {
		pos := position + velocity
		//get vector from point to plane
		dist := pos - p.origin
		//check if normal is facing our sphere first. don't double wall.
		if dot(dist, p.normal) < 0 ||
			dot(normalize(velocity), p.normal) > 0 {
			continue
		}
		//project it onto normal (assumed to be normalized already)
		//this gives us a vector from the point perpendicular to the plane
		//the length of which is the shortest possible distance
		v := p.normal * dot(dist, p.normal)
		r2 := radius * radius
		if len2(v) <= r2 {
			//find the nearest point on the plane along that vector
			//then check if the point is actually within the bounds of the polygon
			if line_in_polygon(pos, pos+v, p) ||
				inside_vertices(pos, r2, p) ||
				inside_edges(pos, r2, p) {
					//if colliding with a wall, subtract velocity going in the wall's direction
					//to prevent movement
					adj := p.normal * dot(velocity, p.normal) //* 2.0 //bouncy :3
					preserve := len2(velocity)
					velocity = velocity - adj
					mag := len2(velocity)
					//attempt to preserve momentum against slopes etc.
					//not physically accurate but it's more fun.
					//if mag > 0 {
						//velocity = velocity * (preserve / mag / 1.0)
					//}
			}
		}
	}
	return velocity
}
