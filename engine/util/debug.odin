package util

import "../transform"
import "../collision"
import gs "../gamesystem"

draw_bounding_box :: proc(col: ^collision.Collider, t: ^transform.Transform = nil, color: [4]f32 = {1, 1, 1, 1}) {
	col := collision.transform_collider(col^, t)
	defer collision.delete_collider(&col)

	mi := col.extents.mini
	mx := col.extents.maxi

	front: [4]gs.Vertex = {}
	front[0] = {position={mi.x, mi.y, mi.z}, color=color}
	front[1] = {position={mx.x, mi.y, mi.z}, color=color}
	front[2] = {position={mx.x, mx.y, mi.z}, color=color}
	front[3] = {position={mi.x, mx.y, mi.z}, color=color}
	gs.draw_line_loop(front[:])

	back: [4]gs.Vertex = {}
	back[0] = {position={mi.x, mi.y, mx.z}, color=color}
	back[1] = {position={mx.x, mi.y, mx.z}, color=color}
	back[2] = {position={mx.x, mx.y, mx.z}, color=color}
	back[3] = {position={mi.x, mx.y, mx.z}, color=color}
	gs.draw_line_loop(back[:])

	connect: [8]gs.Vertex = {}
	connect[0] = {position={mi.x, mi.y, mi.z}, color=color}
	connect[1] = {position={mi.x, mi.y, mx.z}, color=color}
	connect[2] = {position={mx.x, mi.y, mi.z}, color=color}
	connect[3] = {position={mx.x, mi.y, mx.z}, color=color}
	connect[4] = {position={mx.x, mx.y, mi.z}, color=color}
	connect[5] = {position={mx.x, mx.y, mx.z}, color=color}
	connect[6] = {position={mi.x, mx.y, mi.z}, color=color}
	connect[7] = {position={mi.x, mx.y, mx.z}, color=color}
	gs.draw_lines(connect[:])
}

draw_mesh :: proc(col: ^collision.Collider, color: [4]f32 = {1, 1, 1, 1}) {
	if col.planes == nil {
		return
	}
	for p in col.planes {
		lines: [3]gs.Vertex = {
			{position=p.points[0], color=color},
			{position=p.points[1], color=color},
			{position=p.points[2], color=color},
		}
		gs.draw_line_loop(lines[:])
	}
}
