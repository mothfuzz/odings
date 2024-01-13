package util

import gs "../gamesystem"
import "../collision"

import "core:fmt"

collision_mesh :: proc(mesh: ^gs.Mesh) -> (c: collision.Collider) {
	planes := make([dynamic]collision.Plane)
	defer delete(planes)
	for i := 0; i < len(mesh.data); i += 3 {
		a := mesh.data[i+0].position
		b := mesh.data[i+1].position
		c := mesh.data[i+2].position
		append(&planes, collision.plane({a, b, c}))
	}
	fmt.println("created collision mesh:", len(planes))
	fmt.println(planes[0])
	c = collision.mesh(planes[:])
	return
}
