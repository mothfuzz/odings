package scene

Init_Proc :: proc(^Actor) -> bool
Update_Proc :: proc(^Actor) -> bool
Draw_Proc :: proc(^Actor) -> bool
Destroy_Proc :: proc(^Actor) -> bool

Spawner :: struct {
	init: Init_Proc,
	update: Update_Proc,
	draw: Draw_Proc,
	destroy: Destroy_Proc,
}

Actor_Id :: u64
Actor :: struct {
	id: Actor_Id,
	scene: ^Scene,
	data: rawptr,
	type_name: string,
	update: Update_Proc,
	draw: Draw_Proc,
	destroy: Destroy_Proc,
}

import "core:fmt"
import "core:runtime"

spawn :: proc(scene: ^Scene, data: ^$T, s: Spawner) -> Actor_Id {
	type_info := type_info_of(T)
	named_type: runtime.Type_Info_Named
	t_ok: bool
	if named_type, t_ok = type_info.variant.(runtime.Type_Info_Named); !t_ok {
		fmt.eprintln("Cannot spawn, Actor must be named type:", typeid_of(T))
		return 0
	}
	type_name := fmt.aprint(named_type.pkg, named_type.name, sep=".")
	fmt.println("type_name:", type_name)

	if scene.actors == nil {
		scene.actors = make(map[Actor_Id]^Actor)
	}
	scene.base_id += 1
	new_actor := new_clone(Actor{scene.base_id, scene, data, type_name, s.update, s.draw, s.destroy})
	if s.init != nil {
		s.init(new_actor)
	}
	scene.actors[new_actor.id] = new_actor
	return new_actor.id
}
//engine enforced constraints: ID is for when it's others. Actor^ is for when it's self.
//so, e.g. you can kill another entity via ID
//but you can't reach in and call 'update_spatial' or w/e on an ID.
kill :: proc(scene: ^Scene, id: Actor_Id) {
	actor := scene.actors[id]
	if actor.destroy != nil {
		actor->destroy()
	}
	deregister_body(actor)
	delete_key(&scene.actors, id)
	free(actor)
}
