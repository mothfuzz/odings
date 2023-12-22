package gamesystem

quad: #soa[4]Vertex = {
	position={
		{-0.5, -0.5, 0},
		{+0.5, -0.5, 0},
		{+0.5, +0.5, 0},
		{-0.5, +0.5, 0},
	},
	texcoord={
		{0, 0},
		{1, 0},
		{1, 1},
		{0, 1},
	},
	color={
		{1.0, 0.5, 0.5, 1},
		{0.5, 1.0, 0.5, 1},
		{0.5, 0.5, 1.0, 1},
		{1.0, 1.0, 1.0, 1},
	},
}

load_quad :: proc() -> (m: Mesh, err: Mesh_Error)  {
	m, err = load_mesh("quad", quad[:], []u32{0, 1, 2, 0, 2, 3})
	return
}
