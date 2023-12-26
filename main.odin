package main

import "core:fmt"

import "engine"
import "engine/scene"
import gs "engine/gamesystem"

import "actors/testmap"

tm: testmap.TestMap
tid: scene.ActorId

//TODO: make a simple font rendering module.
//maybe do a bespoke sprite renderer first.
//draw some 'demo' screens, text, sprites, gradients, text etc.
init :: proc(s: ^scene.Scene) {
	s.name = "TestMap"
	tid = scene.spawn(s, &tm, testmap.TestMap_Spawner)

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

	//
}

tick :: proc(s: ^scene.Scene) {
	//nothing special here
}

draw :: proc(s: ^scene.Scene) {
	//or here
}

exit :: proc(s: ^scene.Scene) {
	scene.kill(s, tid)
}

main :: proc() {
	engine.run(init, tick, draw, exit)
}
