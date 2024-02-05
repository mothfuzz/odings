package opengl

import "core:fmt"

import "../common"
when common.Renderer != "gl" {
	//+ignore
}

Line :: struct {
	mode: int,
	vertices: #soa[dynamic]common.Vertex,
	model_transform: matrix[4,4]f32,
}

lines_vao : VertexArrayObject
lines_positions : Buffer
lines_colors : Buffer
lines_mvps : Buffer
lines : [dynamic]Line

lines_init : bool = false
init_lines :: proc() {

	lines = make([dynamic]Line, 0)

	when ODIN_OS == .JS {
		lines_vao = gl.CreateVertexArray()
		lines_positions = gl.CreateBuffer()
		lines_colors = gl.CreateBuffer()
		lines_mvps = gl.CreateBuffer()
	} else {
		buffers: []u32 = {0, 0, 0}
		gl.GenBuffers(3, raw_data(buffers))
		lines_positions = buffers[0]
		lines_colors = buffers[1]
		lines_mvps = buffers[2]
		gl.GenVertexArrays(1, &lines_vao)
	}

	gl.BindVertexArray(lines_vao)

	//regular vertex attribs
	gl.BindBuffer(gl.ARRAY_BUFFER, lines_positions)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 0, 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, lines_colors)
	gl.EnableVertexAttribArray(2)
	gl.VertexAttribPointer(2, 4, gl.FLOAT, false, 0, 0)

	//per-instance data
	gl.BindBuffer(gl.ARRAY_BUFFER, lines_mvps)
	for i in 0..=3 {
		when ODIN_OS == .JS {
			index := i32(7+i)
		} else {
			index := u32(7+i)
		}
		gl.EnableVertexAttribArray(index)
		gl.VertexAttribPointer(index, 4, gl.FLOAT, false, size_of(matrix[4,4]f32), (uintptr)(i*size_of([4]f32)))
		gl.VertexAttribDivisor(u32(index), 1)
	}

	lines_init = true
}

//use existing infrastructure
lines_instance :: proc(mode: int, l: []common.Vertex, model_transform: matrix[4,4]f32 = 1) {
	vertices := make_soa(#soa[dynamic]common.Vertex)
	for vertex in l {
		append_soa(&vertices, vertex)
	}
	append(&lines, Line{mode, vertices, model_transform})
}

@(export)
gs_draw_lines :: proc(l: []common.Vertex, model_transform: matrix[4,4]f32 = 1) {
	lines_instance(0, l, model_transform)
}
@(export)
gs_draw_line_strip :: proc(l: []common.Vertex, model_transform: matrix[4,4]f32 = 1) {
	lines_instance(1, l, model_transform)
}
@(export)
gs_draw_line_loop :: proc(l: []common.Vertex, model_transform: matrix[4,4]f32 = 1) {
	lines_instance(2, l, model_transform)
}

//called by draw
draw_all_lines :: proc(view: matrix[4,4]f32, projection: matrix[4,4]f32) {
	if !lines_init {
		init_lines()
	}
	gl.BindVertexArray(lines_vao)

	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, Blank_Texture)
	gl.Uniform1i(program_uniform_material.albedo, 0)

	for line in &lines {
		gl.BindBuffer(gl.ARRAY_BUFFER, lines_positions)
		gl.BufferData(gl.ARRAY_BUFFER, len(line.vertices) * size_of([3]f32), line.vertices.position, gl.DYNAMIC_DRAW)
		gl.BindBuffer(gl.ARRAY_BUFFER, lines_colors)
		gl.BufferData(gl.ARRAY_BUFFER, len(line.vertices) * size_of([4]f32), line.vertices.color, gl.DYNAMIC_DRAW)
		gl.BindBuffer(gl.ARRAY_BUFFER, lines_mvps)
		mvp := projection * view * line.model_transform
		gl.BufferData(gl.ARRAY_BUFFER, size_of(matrix[4,4]f32), &mvp, gl.DYNAMIC_DRAW)
		//dammit bill
		when ODIN_OS == .JS {
			size := len(line.vertices)
		} else {
			size := i32(len(line.vertices))
		}
		switch line.mode {
		case 0:
			gl.DrawArraysInstanced(gl.LINES, 0, size, 1)
		case 1:
			gl.DrawArraysInstanced(gl.LINE_STRIP, 0, size, 1)
		case 2:
			gl.DrawArraysInstanced(gl.LINE_LOOP, 0, size, 1)
		}
		delete_soa(line.vertices)
	}
	clear(&lines)
}
