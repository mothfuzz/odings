package player

import "../../engine/scene"
import "../../engine/transform"
import "../../engine/collision"
import gs "../../engine/gamesystem"
import "../../engine/util"

import "core:fmt"

import "../minitri"
import "../objtest"

Player :: struct {
	frame: i32,
	v: [3]f32,
	trans: transform.Transform,
	col: collision.Collider,
	//resources
	tri: gs.Mesh,
	fras: gs.Material,
}
player_init :: proc(a: ^scene.Actor) -> bool {
	p := cast(^Player)(a.data)
	p.tri, _ = gs.load_quad()
	fmt.println("loading player image...")
	tex, _ := gs.load_texture("guy.png", #load("guy.png"))
	p.fras = gs.create_textured_material("fras", tex)
	p.trans = transform.origin()
	p.col = collision.bounding_box(1, 1, 1)
	p.frame = 0
	p.v = {0, 0, 0}

	transform.scale(&p.trans, {32, 32, 32})
	scene.register_body(a, &p.trans, &p.col)
	fmt.println("player initialized!")
	return true
}
player_update :: proc(a: ^scene.Actor) -> bool {
	p := cast(^Player)(a.data)

	if gs.key_down(gs.Key.W) {
		p.v.y -= 1
	}
	if gs.key_down(gs.Key.S) {
		p.v.y += 1
	}
	if gs.key_down(gs.Key.A) {
		p.v.x -= 1
	}
	if gs.key_down(gs.Key.D) {
		p.v.x += 1
	}
	for id, m in scene.nearby(a.scene, p.trans.position, minitri.MiniTri, 0) {
		m.colliding = false
	}
	for id, m in scene.colliding(a, minitri.MiniTri) {
		m.colliding = true
	}
	for id, o in scene.nearby(a.scene, p.trans.position, objtest.ObjTest, 0) {
		o.colliding = false
	}
	for id, o in scene.colliding(a, objtest.ObjTest) {
		o.colliding = true
	}
	if gs.key_pressed(gs.Key.K) {
		for id, m in scene.nearby(a.scene, p.trans.position, minitri.MiniTri, 0) {
			scene.kill(a.scene, id)
		}
	}
	if gs.key_pressed(gs.Key.E) {
		for id, m in scene.nearby(a.scene, p.trans.position, minitri.MiniTri, 0) {
			fmt.println("nearby:", m)
			m.trans.scale += 64
		}
	}
	//this one's harder but we alreeady did it in Go and can copy the code :3c (and optimize it)
	//p.v = move_against_terrain(p.trans, p.v, 0.4) //transform, velocity, collider sphere radius
	p.v *= 0.75
	transform.translate(&p.trans, p.v)
	p.frame += 1
	p.frame = p.frame % 500
	return true
}
player_draw :: proc(a: ^scene.Actor) -> bool {
	p := cast(^Player)(a.data)
	gs.draw_mesh(&p.tri, &p.fras, transform.mat4(&p.trans), texture_region = {f32(p.frame)/500.0, 0, 1.0, 1.0}) //try using kwargs here :3
	//renderer.draw_lines({{position={0, 0, 0}}, {position={0, 1, 0}}}, transform.mat4(&p.trans))
	//util.draw_sprite(&p.trans, &p.sprite, animations["idle"][i32(f32(frame)/500.0)])
	util.draw_bounding_box(&p.col, &p.trans, {1.0, 0.5, 1.0, 1.0})
	return true
}
Player_Spawner : scene.Spawner = {player_init, player_update, player_draw, nil}
