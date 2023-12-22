package testmap

import "../../engine/scene"
import "../../engine/transform"
import gs "../../engine/gamesystem"

import "core:fmt"

Coob :: struct {
	trans: transform.Transform,
	//resources
	obj: gs.Mesh,
	tex: gs.Texture,
	norm: gs.Texture,
	rugh: gs.Texture,
	mat: gs.Material,
}
coob_init :: proc(a: ^scene.Actor) -> bool {
	c := cast(^Coob)(a.data)

	c.obj, _ = gs.load_mesh("coob.obj", #load("coob.obj"))
	c.tex, _ = gs.load_texture("wildbricks/albedo.png", #load("wildbricks/albedo.png"))
	c.norm, _ = gs.load_texture("wildbricks/normal.png", #load("wildbricks/normal.png"))
	c.rugh, _ = gs.load_texture("wildbricks/glossy.png", #load("wildbricks/glossy.png"))
	c.mat = gs.create_full_material("gold", albedo=c.tex, normal=c.norm, roughness=c.rugh)
	c.trans = transform.origin()
	transform.translate(&c.trans, {-300, -500, -300})
	transform.scale(&c.trans, {1000, 1000, 1000})

	fmt.println("coob:", a.id)

	return true
}
coob_update :: proc(a: ^scene.Actor) -> bool {
	c := cast(^Coob)(a.data)
	transform.rotatey(&c.trans, -0.005)
	return true
}
coob_draw :: proc(a: ^scene.Actor) -> bool {
	c := cast(^Coob)(a.data)
	gs.draw_mesh(&c.obj, &c.mat, transform.mat4(&c.trans))
	return true
}
Coob_Spawner : scene.Spawner = {coob_init, coob_update, coob_draw, nil}
