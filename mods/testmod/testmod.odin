package testmod

import "core:fmt"
import "../../engine/scene"
import "../../actors/minitri"
import "../../actors/fsm"
import gs "../../engine/gamesystem"

m: minitri.MiniTri
mid: scene.ActorId
f: fsm.FiniteStateMachine

@(export)
init :: proc(s: ^scene.Scene) {
	mid = scene.spawn(s, &m, minitri.MiniTri_Spawner)
}

@(export)
tick :: proc(s: ^scene.Scene) {
	//fmt.println("MODS HELP")
}

@(export)
draw :: proc(s: ^scene.Scene) {
	//this is just here for demonstration
}

@(export)
quit :: proc(s: ^scene.Scene) {
	//this too
}
