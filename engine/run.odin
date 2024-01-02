package engine

import "core:fmt"
import "core:strconv"
import gs "gamesystem"
import "scene"

Current_Scene : ^scene.Scene
gamestate_proc :: proc(^scene.Scene)
init, tick, draw, quit : gamestate_proc

accumulator : f64
time : f64
frames : int
@(export)
step :: proc(dt: f64) {

	if !gs.running() {
		if quit != nil {
			quit(Current_Scene)
		}
		for f in mods_quits {
			f(Current_Scene)
		}
		return
	}

	context.allocator, context.temp_allocator = gs.get_memory()

	//accumulate work & execute update
	accumulator += dt
	for ; accumulator > 0; accumulator-=1.0/125.0 {
		if Current_Scene != nil {
			scene.update_all(Current_Scene)
			scene.update_spatial(Current_Scene)
		}
		if tick != nil {
			tick(Current_Scene)
		}
		for f in mods_ticks {
			f(Current_Scene)
		}
		gs.update_input()
	}

	//compute FPS
	time += dt
	frames += 1
	if time > 1.0 {
		time = 0.0
		buf: [4]byte
		title := strconv.itoa(buf[:], frames)
		if Current_Scene != nil {
			title = fmt.tprint(Current_Scene.name, ":", title, "fps")
		}
		gs.window_title(title)
		frames = 0
	}

	scene.draw_all(Current_Scene)
	if draw != nil {
		draw(Current_Scene)
	}
	for f in mods_draws {
		f(Current_Scene)
	}
	gs.draw()
}

run :: proc(i: gamestate_proc = nil, t: gamestate_proc = nil, d: gamestate_proc = nil, q: gamestate_proc = nil) {

	init = i
	tick = t
	draw = d
	quit = q

	//see ya later allocator
	context.allocator, context.temp_allocator = gs.get_memory()

	fmt.printf("Hi!!!!!")

	gs.init()

	fmt.println("こんにちわ!!!")

	//create dummy initial scene to kick off game code
	eve := new(scene.Scene)
	eve.name = "Eve"
	Current_Scene = eve

	if init != nil {
		init(Current_Scene)
	}

	if gs.lib_loaded {
		load_mods()
	}

	gs.run(step)
}
