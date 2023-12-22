package scene

init_func :: proc(^Actor) -> bool
update_func :: proc(^Actor) -> bool
draw_func :: proc(^Actor) -> bool
destroy_func :: proc(^Actor) -> bool

Spawner :: struct {
	init: init_func,
	update: update_func,
	draw: draw_func,
	destroy: destroy_func,
}

ActorId :: u64
Actor :: struct {
	id: ActorId,
	scene: ^Scene,
	data: rawptr,
	type_name: string,
	update: update_func,
	draw: draw_func,
	destroy: destroy_func,
}

import "core:fmt"

spawn :: proc(scene: ^Scene, data: ^$T, s: Spawner) -> ActorId {
	if scene.actors == nil {
		scene.actors = make(map[ActorId]^Actor)
	}
	scene.base_id += 1
	type_name := fmt.aprint(typeid_of(T))
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
kill :: proc(scene: ^Scene, id: ActorId) {
	actor := scene.actors[id]
	if actor.destroy != nil {
		actor->destroy()
	}
	deregister_body(actor)
	delete_key(&scene.actors, id)
	free(actor)
}
