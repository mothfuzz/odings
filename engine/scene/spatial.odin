package scene

import "core:fmt"
import "core:runtime"
import "../transform"
import "../collision"

Body :: struct {
	t: ^transform.Transform,
	c: ^collision.Collider,
	tprev: transform.Transform,
	//ty: typeid,
	layer: string,
	//layers: [dynamic]string,
	cells: [dynamic][3]i32,
}

cell_size :: 512

//update body's physical location inside the spatial hash.
update_body :: proc(scene: ^Scene, id: ActorId) {

	if _, ok := scene.bodies[id]; !ok {
		return
	}
	b := &scene.bodies[id]

	spatial := &scene.spatial_hash[b.layer]

	mini: [3]f32
	maxi: [3]f32
	if b.t != nil {
		mini = b.t.position
		maxi = b.t.position
	}
	if b.c != nil {
		extents := collision.transform_extents(b.c.extents, b.t)
		mini += extents.mini
		maxi += extents.maxi
		//:3
	}

	mini /= cell_size
	maxi /= cell_size

	min_cell: [3]i32 = {i32(mini.x), i32(mini.y), i32(mini.z)}
	max_cell: [3]i32 = {i32(maxi.x), i32(maxi.y), i32(maxi.z)}

	//fmt.println("actor:",id,"registered from cells",min_cell,"to cells",max_cell)

	clear(&b.cells)
	for x in min_cell.x..=max_cell.x {
		for y in min_cell.y..=max_cell.y {
			for z in min_cell.z..=max_cell.z {
				if _, ok := spatial[{x, y, z}]; !ok {
					spatial[{x, y, z}] = make(map[ActorId]struct{})
				}
				cell := &spatial[{x, y, z}]
				cell[id] = {}
				append(&b.cells, [3]i32{x, y, z})
			}
		}
	}
}

//associate an actor with a body.
register_body :: proc(a: ^Actor, t: ^transform.Transform, c: ^collision.Collider = nil) {
	if a.scene.bodies == nil {
		a.scene.bodies = make(map[ActorId]Body)
	}
	if a.scene.spatial_hash == nil {
		a.scene.spatial_hash = make(map[string]map[[3]i32]map[ActorId]struct{})
	}
	if _, ok := a.scene.spatial_hash[a.type_name]; !ok {
		a.scene.spatial_hash[a.type_name] = make(map[[3]i32]map[ActorId]struct{})
	}

	tp: transform.Transform
	if t == nil {
		tp = transform.origin()
	} else {
		tp = t^
	}

	b := Body{t, c, tp, a.type_name, make([dynamic][3]i32)}
	a.scene.bodies[a.id] = b
	update_body(a.scene, a.id)
}

deregister_body :: proc(a: ^Actor) {
	if b, ok := &a.scene.bodies[a.id]; ok {
		for cell in b.cells {
			delete_key(&a.scene.spatial_hash[b.layer][cell], a.id)
		}
		collision.delete_collider(b.c) //useful?
		delete_key(&a.scene.bodies, a.id)
	}
}

update_spatial :: proc(scene: ^Scene) {
	//if current_frame != previous_frame then recalculate cells, assuming collider is relative.
	for id in scene.bodies {
		b := &scene.bodies[id]
		if b.t != nil && b.t^ != b.tprev {
			for cell in b.cells {
				delete_key(&scene.spatial_hash[b.layer][cell], id)
			}
			update_body(scene, id)
			b.tprev = b.t^
		}
	}
}

place :: proc(a: ^Actor, t: ^transform.Transform) {
	if b, ok := &a.scene.bodies[a.id]; ok {
		if b.t != nil {
			b.t.position = t.position
			b.t.orientation = t.orientation
			//special case for scaling.
			b.t.scale *= t.scale
		}
	}
}

spawn_at :: proc(scene: ^Scene, data: ^$T, s: Spawner, t: ^transform.Transform) -> ActorId {
	a := spawn(scene, data, s)
	place(scene.actors[a], t)
	return a
}

nearby :: proc(scene: ^Scene, pos: [3]f32, $type: typeid, radius: f32) -> (r: map[ActorId]^type) {
	r = make(map[ActorId]^type, 0, context.temp_allocator)

	type_name := fmt.tprint(typeid_of(type))
	if _, ok := scene.spatial_hash[type_name]; !ok {
		return
	}
	spatial := &scene.spatial_hash[type_name]

	min_cell := (pos - radius)/cell_size
	max_cell := (pos + radius)/cell_size
	//fmt.println("exploring from", min_cell, "to", max_cell)

	for x in i32(min_cell.x) ..= i32(max_cell.x) {
		for y in i32(min_cell.y) ..= i32(max_cell.y) {
			for z in i32(min_cell.z) ..= i32(max_cell.z) {
				if cell, ok := spatial[{x, y, z}]; ok {
					for id in cell {
						if _, ok := r[id]; ok {
							continue
						}
						a := cast(^type)(scene.actors[id].data)
						r[id] = a
					}
				}
			}
		}
	}

	return
}

//actors do not transform their own colliders unless they're manually checking collisions themselves.
//this will transform colliders *only upon checking*.
//we don't want to do it *all* the time.
colliding :: proc(a: ^Actor, $type: typeid) -> (pass: map[ActorId]^type) {
	//don't check any collider twice.
	pass = make(map[ActorId]^type, 0, context.temp_allocator)
	fail := make(map[ActorId]struct{}, 0, context.temp_allocator)

	type_name := fmt.tprint(typeid_of(type))

	if _, ok := a.scene.spatial_hash[type_name]; !ok {
		return
	}
	spatial := &a.scene.spatial_hash[type_name]

	if _, ok := a.scene.bodies[a.id]; !ok {
		return
	}
	if a.scene.bodies[a.id].c == nil {
		return
	}
	ca := collision.transform_collider_copy(a.scene.bodies[a.id].c^, a.scene.bodies[a.id].t)

	min_cell := ca.extents.mini / cell_size
	max_cell := ca.extents.maxi / cell_size

	//fmt.println("exploring from", min_cell, "to", max_cell)

	for x in i32(min_cell.x) ..= i32(max_cell.x) {
		for y in i32(min_cell.y) ..= i32(max_cell.y) {
			for z in i32(min_cell.z) ..= i32(max_cell.z) {
				if cell, ok := spatial[{x, y, z}]; ok {
					for id in cell {
						if _, ok := pass[id]; ok {
							continue
						}
						if _, ok := fail[id]; ok {
							continue
						}
						if a.scene.bodies[id].c == nil {
							fail[id] = {}
							continue
						}
						b := cast(^type)(a.scene.actors[id].data)
						cb := collision.transform_collider_copy(a.scene.bodies[id].c^, a.scene.bodies[id].t)
						if collision.overlap(&ca, &cb) {
							pass[id] = b
						} else {
							fail[id] = {}
						}
						collision.delete_collider(&cb)
					}
				}
			}
		}
	}

	collision.delete_collider(&ca)

	return
}
