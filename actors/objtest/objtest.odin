package objtest

import "../../engine/scene"
import "../../engine/transform"
import "../../engine/collision"
import gs "../../engine/gamesystem"
import "../../engine/util"

import "core:fmt"
import "core:math"

ObjTest :: struct {
	trans: transform.Transform,
	col: collision.Collider,
	colliding: bool,
	//resources
	obj: gs.Mesh,
	tex: gs.Texture,
	mat: gs.Material,
}
objtest_init :: proc(a: ^scene.Actor) -> bool {
	o := cast(^ObjTest)(a.data)

	o.colliding = false

	o.obj, _ = gs.load_mesh("bunny.obj", #load("bunny.obj"))
	o.tex, _ = gs.load_texture("bunny.png", #load("bunny.png"))
	o.mat = gs.create_textured_material("bun", o.tex)
	o.trans = transform.origin()
	transform.translate(&o.trans, {0, 100, 0})
	transform.rotatey(&o.trans, math.to_radians_f32(45))
	transform.rotatez(&o.trans, math.to_radians_f32(180))
	transform.scale(&o.trans, {1000, 1000, 1000})

	o.col = util.collision_mesh(&o.obj)
	o.col.shape = collision.Shape.Bounding_Box
	scene.register_body(a, &o.trans, &o.col)

	return true
}
objtest_update :: proc(a: ^scene.Actor) -> bool {
	o := cast(^ObjTest)(a.data)
	transform.rotatey(&o.trans, 0.01)
	return true
}
objtest_draw :: proc(a: ^scene.Actor) -> bool {
	o := cast(^ObjTest)(a.data)
	gs.draw_mesh(&o.obj, &o.mat, transform.mat4(&o.trans))
	if o.colliding {
		util.draw_bounding_box(&o.col, &o.trans, {1.0, 1.0, 0.5, 1.0})
	} else {
		util.draw_bounding_box(&o.col, &o.trans, {1.0, 0.5, 1.0, 1.0})
	}
	return true
}
objtest_destroy :: proc(a: ^scene.Actor) -> bool {
	o := cast(^ObjTest)(a.data)
	collision.delete_collider(&o.col)
	return true
}
ObjTest_Spawner : scene.Spawner = {objtest_init, objtest_update, objtest_draw, objtest_destroy}
