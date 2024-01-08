package testmap

import "../../engine/scene"
import "../../engine/transform"
import "../../engine/collision"
import "../../engine/util"
import gs "../../engine/gamesystem"

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:math/linalg/glsl"

Player :: struct {
	trans: transform.Transform,
	col: collision.Collider,
	camera_pos: [3]f32,
	camera_rot : f32,
	camera_init : bool,
	vspeed : f32,
	hspeed : f32,
	velocity: [3]f32,
	//resources
	obj: gs.Mesh,
	tex: gs.Texture,
	mat: gs.Material,
	//lights
	ps: [dynamic]gs.PointLight,
}
player_init :: proc(a: ^scene.Actor) -> bool {
	p := cast(^Player)(a.data)

	p.obj, _ = gs.load_mesh("ball.obj", #load("ball.obj"))
	p.tex, _ = gs.load_texture("gold.png", #load("gold.png"))
	p.mat = gs.create_textured_material("gold", p.tex)
	p.trans = transform.origin()
	transform.scale(&p.trans, {48, 48, 48})

	p.col = collision.bounding_sphere(0.5)
	scene.register_body(a, &p.trans, &p.col)

	p.ps = make([dynamic]gs.PointLight)

	return true
}
player_update :: proc(a: ^scene.Actor) -> bool {
	p := cast(^Player)(a.data)

	if !p.camera_init {
		p.camera_pos.y = p.trans.position.y - 256
		fmt.println(p.trans)
		fmt.println(p.camera_pos.y)
		p.camera_init = true
	}

	dx := math.sin(p.camera_rot)
	dz := math.cos(p.camera_rot)

	if gs.key_down(gs.Key.Left) {
		p.camera_rot += 0.015
	}
	if gs.key_down(gs.Key.Right) {
		p.camera_rot -= 0.015
	}
	if gs.key_down(gs.Key.Up) {
		p.camera_pos.y -= 3
	}
	if gs.key_down(gs.Key.Down) {
		p.camera_pos.y += 3
	}

	accel: f32 = 0.5
	if gs.key_down(gs.Key.W) {
		p.vspeed -= accel
	}
	if gs.key_down(gs.Key.S) {
		p.vspeed += accel
	}
	if gs.key_down(gs.Key.A) {
		p.hspeed += accel
	}
	if gs.key_down(gs.Key.D) {
		p.hspeed -= accel
	}
	if gs.key_pressed(gs.Key.Space) {
		p.velocity.y -= 25
	}

	p.velocity.y += 0.65
	p.velocity.y *= 0.95

	p.vspeed *= 0.95
	p.hspeed *= 0.95
	term: f32 = 10.0
	p.vspeed = clamp(p.vspeed, -term, +term)
	p.hspeed = clamp(p.hspeed, -term, +term)

	p.velocity.x = dx*p.vspeed + dz*p.hspeed
	p.velocity.z = dz*p.vspeed - dx*p.hspeed
	//p.velocity.y += 0.01

	p.velocity = scene.move_against_terrain(a, p.velocity) //avoids all colliders registered as 'solid' and with mesh collision type
	//p.velocity = collision.move_against_terrain(p.trans.position, 24.0, p.velocity, level.col.planes)
	//fmt.println(collision.transform_extents(p.col.extents, &p.trans))

	transform.translate(&p.trans, p.velocity)
	transform.rotatez(&p.trans, p.velocity.x/100.0)
	transform.rotatex(&p.trans, -p.velocity.z/100.0)
	//transform.rotate(&p.trans, {-p.velocity.z/100.0, 0, p.velocity.x/100.0})

	p.camera_pos.x = p.trans.position.x + dx*gs.z2d()
	p.camera_pos.z = p.trans.position.z + dz*gs.z2d()
	p.camera_pos.y += p.velocity.y

	gs.set_view(glsl.mat4LookAt((glsl.vec3)(p.camera_pos), (glsl.vec3)(p.trans.position), {0, -1, 0}))

	if gs.key_pressed(gs.Key.L) {
		color: [3]f32 = {}
		color.r = rand.float32()
		color.g = rand.float32()
		color.b = rand.float32()
		color = ([3]f32)(glsl.normalize(glsl.vec3(color)))
		l := gs.create_point_light({0, 0, 0}, color, 500.0)
		l.position = p.trans.position
		l.position.y = p.trans.position.y - l.radius / 2.0
		append(&p.ps, l)
	}
	return true
}
player_draw :: proc(a: ^scene.Actor) -> bool {
	p := cast(^Player)(a.data)
	gs.draw_mesh(&p.obj, &p.mat, transform.mat4(&p.trans))
	util.draw_bounding_box(&p.col, &p.trans, {1.0, 0.0, 1.0, 1.0})
	for l in &p.ps {
		gs.draw_point_light(&l)
	}

	/*if hit, ok := collision.raycast(p.trans.position, {0, 1, 0}, level.col.planes); ok {
		gs.draw_lines({{position=p.trans.position, color={0, 1, 0, 1}},
					   {position=hit.point, color={1, 0, 0, 1}}})
	}*/
	for hit in scene.raycast(a.scene, p.trans.position, {0, 1, 0}) {
		fmt.println(hit.id)
		gs.draw_lines({{position=p.trans.position, color={0, 1, 0, 1}},
					   {position=hit.point, color={1, 0, 0, 1}}})
	}

	return true
}
Player_Spawner : scene.Spawner = {player_init, player_update, player_draw, nil}
