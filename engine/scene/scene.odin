package scene

Scene :: struct {
	name: string,
	//actors table
	base_id: ActorId,
	actors: map[ActorId]^Actor,
	//spatial data
	bodies: map[ActorId]Body,
	spatial_hash: map[string]map[[3]i32]map[ActorId]struct{}, //layers contain cells contain actors.
}

import "core:fmt"
update_all :: proc(scene: ^Scene) {
	for id, actor in scene.actors {
		//fmt.println(id)
		//fmt.println(actor.id)
		//fmt.println(actor.data)
		if actor.update != nil {
			actor->update()
		}
	}
}

draw_all :: proc(scene: ^Scene) {
	for id, actor in scene.actors {
		if actor.draw != nil {
			actor->draw()
		}
	}
}
