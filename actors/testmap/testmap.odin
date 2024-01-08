package testmap

import "../../engine/scene"
import "../../engine/transform"
import "../../engine/collision"
import gs "../../engine/gamesystem"
import "../../engine/util"

import "core:fmt"
import "core:math"

level: ^TestMap

TestMap :: struct {
	trans: transform.Transform,
	col: collision.Collider,
	//resources
	obj: gs.Mesh,
	tex: gs.Texture,
	norm: gs.Texture,
	mat: gs.Material,
	//lights
	d: gs.DirectionalLight,
	spot: gs.SpotLight,
	//actors
	player: Player,
	player_id: scene.ActorId,
	coob: Coob,
	coob_id: scene.ActorId,
}
testmap_init :: proc(a: ^scene.Actor) -> bool {
	t := cast(^TestMap)(a.data)

	t.obj, _ = gs.load_mesh("testmap.obj", #load("testmap.obj"))
	t.tex, _ = gs.load_texture("texture.png", #load("texture.png"))
	t.mat = gs.create_textured_material("testmap", t.tex)
	t.trans = transform.origin()
	transform.translate(&t.trans, {0, 0, 0})
	transform.scale(&t.trans, {1000, 1000, 1000})
	transform.rotatez(&t.trans, math.to_radians_f32(180))

	t.d = gs.create_directional_light({0.5, 1, 0.5}, {1.0, 1.0, 1.0}, 0.5)
	t.spot = gs.create_spot_light({0, -800, 0}, {0, 1, 0}, {0.6, 0.6, 0.6}, 45)

	mesh := util.collision_mesh(&t.obj)
	t.col = collision.transform_collider_copy(mesh, &t.trans) //register transformed collider & never update it.
	collision.delete_collider(&mesh)
	scene.register_body(a, nil, &t.col, true)

	player_spawn := transform.origin()
	transform.translate(&player_spawn, {0, -380, 0})
	t.player_id = scene.spawn_at(a.scene, &t.player, Player_Spawner, &player_spawn)
	fmt.println("new player id:",t.player_id)

	t.coob_id = scene.spawn(a.scene, &t.coob, Coob_Spawner)

	level = t

	return true
}
testmap_draw :: proc(a: ^scene.Actor) -> bool {
	t := cast(^TestMap)(a.data)
	gs.draw_mesh(&t.obj, &t.mat, transform.mat4(&t.trans))
	gs.draw_directional_light(&t.d)
	gs.draw_spot_light(&t.spot)
	//gs.draw_light({direction={0.5, -1, 0}, type=.Directional, shadows=true})
	//util.draw_mesh(&t.col)
	return true
}
TestMap_Spawner : scene.Spawner = {testmap_init, nil, testmap_draw, nil}
