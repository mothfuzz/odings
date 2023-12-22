package fsm

import "core:fmt"
import "../../engine/scene"

FiniteStateMachine :: struct {}

//OH THE POWER OF DYNAMIC VTABLE

fsm_update_0 :: proc(a: ^scene.Actor) -> bool {
	fmt.println("Zero!!")
	a.update = fsm_update_1
	return true
}
fsm_update_1 :: proc(a: ^scene.Actor) -> bool {
	fmt.println("One!!")
	a.update = fsm_update_2
	return true
}
fsm_update_2 :: proc(a: ^scene.Actor) -> bool {
	fmt.println("Two!!")
	a.update = fsm_update_0
	return true
}

FSM_Spawner : scene.Spawner = {nil, fsm_update_0, nil, nil}
