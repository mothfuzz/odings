package minitri

import "../../engine/scene"
import "../../engine/transform"
import "../../engine/collision"
import gs "../../engine/gamesystem"
import "../../engine/util"

import "core:math"
import "core:fmt"

MiniTri :: struct {
	trans: transform.Transform,
	col: collision.Collider,
	//resources
	tri: gs.Mesh,
	colliding: bool,
}
minitri_init :: proc(a: ^scene.Actor) -> bool {
	m := cast(^MiniTri)(a.data)

	fac := math.sin(math.to_radians(f32(60.0)))
	dist := 2.0/3.0 * fac
	tri: #soa[3]gs.Vertex = {
		position={
			{+0, -2*dist, 0},
			{+1, dist, 0},
			{-1, dist, 0},
		},
		texcoord={
			{0, 0}, {0, 0}, {0, 0},
		},
		color={
			util.hex2rgba(0xff88aaff),
			util.hex2rgba(0x776655ff),
			util.hex2rgba(0xffeebbff),
		},
	}

	//m.col = collision.bounding_box(1, 1, 1)
	m.col = collision.mesh({collision.plane(expand_values(tri.position))})
	fmt.println("minitri collision:", m.col)
	scene.register_body(a, &m.trans, &m.col)

	fmt.println("loading minitrimesh...")
	m.tri, _ = gs.load_mesh("tri", tri[:])
	m.trans = transform.origin()
	//transform.scale(&m.trans, {0.2, 0.2, 0.2})
	transform.scale(&m.trans, {40, 40, 40})

	fmt.println("No problem here")

	return true
}
minitri_update :: proc(a: ^scene.Actor) -> bool {
	m := cast(^MiniTri)(a.data)
	transform.rotatey(&m.trans, 0.01)
	//transform.rotatex(&m.trans, 0.005)
	return true
}
minitri_draw :: proc(a: ^scene.Actor) -> bool {
	m := cast(^MiniTri)(a.data)
	//gs.draw_mesh(&m.tri, nil, transform.mat4(&m.trans))
	if m.colliding {
		util.draw_bounding_box(&m.col, &m.trans, {1.0, 1.0, 0.5, 1.0})
	} else {
		util.draw_bounding_box(&m.col, &m.trans, {1.0, 0.5, 1.0, 1.0})
	}
	return true
}
minitri_destroy :: proc(a: ^scene.Actor) -> bool {
	m := cast(^MiniTri)(a.data)
	collision.delete_collider(&m.col)
	return true
}
MiniTri_Spawner : scene.Spawner = {minitri_init, minitri_update, minitri_draw, minitri_destroy}
