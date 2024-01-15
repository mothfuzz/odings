package collision

//this sucks actually, migrate to convex hull asap
mesh_box :: proc(w, h, d: f32) -> (c: Collider) {
	v := [][3]f32{
		// front (0, 1, 2, 3)
		{-w / 2, -h / 2, +d / 2},
		{+w / 2, -h / 2, +d / 2},
		{+w / 2, +h / 2, +d / 2},
		{-w / 2, +h / 2, +d / 2},
		// back (4, 5, 6, 7)
		{-w / 2, -h / 2, -d / 2},
		{+w / 2, -h / 2, -d / 2},
		{+w / 2, +h / 2, -d / 2},
		{-w / 2, +h / 2, -d / 2},
	}
	c = mesh([]Plane{
		// front
		plane({v[0], v[1], v[2]}),
		plane({v[2], v[3], v[0]}),
		// right
		plane({v[1], v[5], v[6]}),
		plane({v[6], v[2], v[1]}),
		// back
		plane({v[7], v[6], v[5]}),
		plane({v[5], v[4], v[7]}),
		// left
		plane({v[4], v[0], v[3]}),
		plane({v[3], v[7], v[4]}),
		// bottom
		plane({v[4], v[5], v[1]}),
		plane({v[1], v[0], v[4]}),
		// top
		plane({v[3], v[2], v[6]}),
		plane({v[6], v[7], v[3]}),
	})
	return
}

box :: proc(w, h, d: f32) -> (c: Collider) {
	v := [][3]f32{
		// front (0, 1, 2, 3)
		{-w / 2, -h / 2, +d / 2},
		{+w / 2, -h / 2, +d / 2},
		{+w / 2, +h / 2, +d / 2},
		{-w / 2, +h / 2, +d / 2},
		// back (4, 5, 6, 7)
		{-w / 2, -h / 2, -d / 2},
		{+w / 2, -h / 2, -d / 2},
		{+w / 2, +h / 2, -d / 2},
		{-w / 2, +h / 2, -d / 2},
	}
	c = convex([]Plane{
		// front
		plane({v[0], v[1], v[2], v[3]}),
		// right
		plane({v[1], v[5], v[6], v[2]}),
		// back
		plane({v[7], v[6], v[5], v[4]}),
		// left
		plane({v[4], v[0], v[3], v[7]}),
		// bottom
		plane({v[4], v[5], v[1], v[0]}),
		// top
		plane({v[3], v[2], v[6], v[7]}),
	})
	return
}
