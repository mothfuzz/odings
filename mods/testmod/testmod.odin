package testmod

import "core:fmt"
import "../../engine/scene"
import "../../actors/minitri"
import "../../actors/fsm"
import gs "../../engine/gamesystem"

m: ^minitri.MiniTri
f: ^fsm.FiniteStateMachine

//not sure if I like or dislike the idea of calling functions via string here
@(export)
on_scene_load: []string = {"spawn_mini"}
//on_scene_destroy
//on_event

@(export)
do_thing :: proc(name: string) {
	gs.load_library()
	fmt.println("Hewwo,",name,"!")
}

@(export)
spawn_mini :: proc(s: ^scene.Scene) -> scene.ActorId {
	gs.load_library()
	m = new(minitri.MiniTri)
	return scene.spawn(s, m, minitri.MiniTri_Spawner)
}

@(export)
spawn_fsm :: proc(s: ^scene.Scene) -> scene.ActorId {
	gs.load_library()
	f = new(fsm.FiniteStateMachine)
	return scene.spawn(s, f, fsm.FSM_Spawner)
}
