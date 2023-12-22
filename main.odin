package main

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:strconv"
import gs "engine/gamesystem"
import "engine/scene"

allocator : mem.Allocator
temp_allocator : mem.Allocator

main_scene: scene.Scene = {name="main"}
p : player.Player
m : minitri.MiniTri
f : fsm.FiniteStateMachine
o : objtest.ObjTest
tm : testmap.TestMap

running : bool = false

accumulator : f64
time : f64
frames : int
@(export)
step :: proc(dt: f64) {

	if !running {
		return
	}

	context.allocator, context.temp_allocator = gs.get_memory()

	//accumulate work & execute update
	accumulator += dt
	for ; accumulator > 0; accumulator-=1.0/125.0 {
		scene.update_all(&main_scene)
		scene.update_spatial(&main_scene)
		gs.update_input()
	}

	//compute FPS
	time += dt
	frames += 1
	if time > 1.0 {
		time = 0.0
		buf: [4]byte
		title := strconv.itoa(buf[:], frames)
		gs.window_title(title)
		frames = 0
	}

	scene.draw_all(&main_scene)
	gs.draw()
}

import "core:os"
load_mods :: proc() {
	when ODIN_OS!=.JS && !#config(ONE_EXE, false) {
		mods_dir : os.Handle
		dir: []os.File_Info
		err: os.Errno
		mods_dir, err = os.open("mods")
		if err != 0 {
			return
		}
		dir, err = os.read_dir(mods_dir, 0)
		if err != 0 {
			return
		}
		for file in dir {
			if file.is_dir {
				continue
			}
			lib, ok := dynlib.load_library(file.fullpath)
			if !ok {
				fmt.println("Failed to load mod:", file.fullpath)
				continue
			}
			fmt.println("Loaded mod:", file.name)
			do_thing := proc(string)(dynlib.symbol_address(lib, "do_thing"))
			do_thing("Mods")
			rc := (^[]string)(dynlib.symbol_address(lib, "on_scene_load"))
			for f in rc {
				fmt.println("attempting to call", f)
				load_func, ok := dynlib.symbol_address(lib, f)
				if(!ok) {
					continue
				}
				t := transform.origin()
				transform.translate(&t, {200, 0, 0})
				transform.scale(&t, {64, 64, 64})
				a := (proc(^scene.Scene)->scene.ActorId)(load_func)(&main_scene)
				scene.place(main_scene.actors[a], &t)

			}
		}
	}
}

//TODO: make a simple font rendering module.
//maybe do a bespoke sprite renderer first.
//draw some 'demo' screens, text, sprites, gradients, text etc.

import "engine/transform"
import "actors/player"
import "actors/minitri"
import "actors/fsm"
import "actors/objtest"
import "actors/testmap"

import "core:dynlib"
main :: proc() {

	fmt.println("Hi!!!!!")

	gs.init()

	fmt.println("Memory!!")

	//see ya later allocator
	context.allocator, context.temp_allocator = gs.get_memory()

	fmt.println("こんにちわ!!!")

	if gs.lib_loaded {
		load_mods()
	}

	//16x16
	//for i := 0; i < 1000; i+=1 {
	//guy, _ := renderer.load_texture("guy.png", #load("guy.png"))
	//fmt.println(guy)
	//}

	//4096x4096 (4k)
	//gs.load_texture("compressthis.png", #load("compressthis.png"))
	//fmt.println(renderer.textures["compressthis.png"])

	fras, f_err := gs.load_texture("frasier.png", #load("frasier.png"))
	if f_err != nil {
		fmt.eprintln("Error loading frasier: ", f_err)
	}
	gs.load_texture("frasier_lo.png", #load("frasier_lo.png"))

	//t := transform.origin()
	//transform.translate(&t, {-400, 0, 0})
	//a := scene.spawn_at(&main_scene, &p, player.Player_Spawner, &t)

	//m = new(minitri.MiniTri)
	//a2 := scene.spawn(&main_scene, m, minitri.MiniTri_Spawner)
	//fmt.println(actors.all_actors[a2].data)

	a3 := scene.spawn(&main_scene, &tm, testmap.TestMap_Spawner)

	//f = new(fsm.FiniteStateMachine)
	//a3 := actor.spawn(f, fsm.FSM_Spawner)

	running = true
	gs.run(step)

	//need a scene teardown function for these
	//kill(a)
	//kill(a2)
	//
	//
}
