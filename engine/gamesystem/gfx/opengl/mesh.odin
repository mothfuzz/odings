package opengl

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"

import "../common"
when common.Renderer != "gl" {
	//+ignore
}

//soa instance data
Instance :: struct {
	model: matrix[4,4]f32, //local to world
	uv_offset: [4]f32,
}

Mesh :: struct {
	size: int,
	vao: VertexArrayObject,
	//attribute buffers
	positions: Buffer,
	texcoords: Buffer,
	colors: Buffer,
	normals: Buffer,
	tangents: Buffer,
	//bone_ids: GLBuffer,
	//bone_weights: GLBuffer,
	//indices
	indices: Buffer,
	//instance buffers
	mvps: Buffer,
	modelviews: Buffer,
	uv_offsets: Buffer,
	//draw data
	batches: ^map[Material]#soa[dynamic]Instance,
	data: ^#soa[dynamic]common.Vertex,
}

meshes : map[string]Mesh

Mesh_Error :: enum {
	None,
	Failed_To_Open_File,
}

@(export)
gs_load_mesh_file :: proc(filename: string, data: []byte = nil) -> (mesh: Mesh, err: Mesh_Error) {
	if m, ok := meshes[filename]; ok {
		return m, nil
	}

	data := data
	if data == nil {
		when ODIN_OS == .JS {
			err = .Failed_To_Open_File
			return
		} else {
			if d, ok := os.read_entire_file(filename, context.temp_allocator); ok {
				data = d
			} else {
				err = .Failed_To_Open_File
				return
			}
		}
	}

	s := string(data)
	positions := make([dynamic][3]f32, 0, context.allocator)
	defer delete(positions)
	texcoords := make([dynamic][2]f32, 0, context.allocator)
	defer delete(texcoords)
	normals := make([dynamic][3]f32, 0, context.allocator)
	defer delete(normals)
	vertices := make_soa(#soa[dynamic]common.Vertex)
	defer delete_soa(vertices)
	for line in strings.split_lines_iterator(&s) {
		element := strings.split(line, " ")
		if element[0] == "v" {
			x := f32(strconv.atof(element[1]))
			y := f32(strconv.atof(element[2]))
			z := f32(strconv.atof(element[3]))
			append(&positions, [3]f32{x, y, z})
		}
		if element[0] == "vt" {
			u := f32(strconv.atof(element[1]))
			v := 1.0 - f32(strconv.atof(element[2]))
			append(&texcoords, [2]f32{u, v})
		}
		if element[0] == "vn" {
			x := f32(strconv.atof(element[1]))
			y := f32(strconv.atof(element[2]))
			z := f32(strconv.atof(element[3]))
			append(&normals, [3]f32{x, y, z})
		}
		if element[0] == "f" {
			//calculate face element
			v1s := strings.split(element[1], "/")
			v2s := strings.split(element[2], "/")
			v3s := strings.split(element[3], "/")
			v1 := [3]int{strconv.atoi(v1s[0])-1, strconv.atoi(v1s[1])-1, strconv.atoi(v1s[2])-1}
			v2 := [3]int{strconv.atoi(v2s[0])-1, strconv.atoi(v2s[1])-1, strconv.atoi(v2s[2])-1}
			v3 := [3]int{strconv.atoi(v3s[0])-1, strconv.atoi(v3s[1])-1, strconv.atoi(v3s[2])-1}

			//calculate tangents based on position & texcoords
			dv1 := positions[v2[0]] - positions[v1[0]]
			dv2 := positions[v3[0]] - positions[v1[0]]
			dvt1 := texcoords[v2[1]] - texcoords[v1[1]]
			dvt2 := texcoords[v3[1]] - texcoords[v1[1]]
			r := 1.0 / (dvt1.x * dvt2.y - dvt2.x * dvt1.y)
			tangent := (dv1 * dvt2.y - dv2 * dvt1.y) * r
			//bitangent := (dv2 * dvt1.x - dv1 * dvt2.x) * r

			//add to vertex structure
			append_soa(&vertices, common.Vertex{position=positions[v1[0]], texcoord=texcoords[v1[1]], normal=normals[v1[2]], color={1,1,1,1}, tangent=tangent})
			append_soa(&vertices, common.Vertex{position=positions[v2[0]], texcoord=texcoords[v2[1]], normal=normals[v2[2]], color={1,1,1,1}, tangent=tangent})
			append_soa(&vertices, common.Vertex{position=positions[v3[0]], texcoord=texcoords[v3[1]], normal=normals[v3[2]], color={1,1,1,1}, tangent=tangent})
		}
	}

	mesh, err = gs_load_mesh_vertices(filename, vertices[:])
	return
}

@(export)
gs_load_mesh_vertices :: proc(filename: string, data: #soa[]common.Vertex, indices: []u32 = nil) -> (mesh: Mesh, err: Mesh_Error)  {
	if m, ok := meshes[filename]; ok {
		return m, nil
	}
	mesh = Mesh{size=len(data)}
	mesh.batches = new_clone(make(map[Material]#soa[dynamic]Instance))
	fmt.println("mesh.batches:", mesh.batches)

	mesh.data = new(#soa[dynamic]common.Vertex)
	mesh.data^ = make_soa(#soa[dynamic]common.Vertex)
	for vertex in data {
		append_soa(mesh.data, vertex)
	}
	fmt.println("number of vertices on load:", len(mesh.data))

	when ODIN_OS == .JS {
		mesh.vao = gl.CreateVertexArray()
		mesh.positions = gl.CreateBuffer()
		mesh.texcoords = gl.CreateBuffer()
		mesh.colors = gl.CreateBuffer()
		mesh.normals = gl.CreateBuffer()
		mesh.tangents = gl.CreateBuffer()
		mesh.mvps = gl.CreateBuffer()
		mesh.modelviews = gl.CreateBuffer()
		mesh.uv_offsets = gl.CreateBuffer()
	} else {
		buffers: []u32 = {0, 0, 0, 0, 0, 0, 0, 0}
		gl.GenBuffers(8, raw_data(buffers))
		mesh.positions = buffers[0]
		mesh.texcoords = buffers[1]
		mesh.colors = buffers[2]
		mesh.normals = buffers[3]
		mesh.tangents = buffers[4]
		mesh.mvps = buffers[5]
		mesh.modelviews = buffers[6]
		mesh.uv_offsets = buffers[7]
		gl.GenVertexArrays(1, &mesh.vao)
	}

	gl.BindVertexArray(mesh.vao)

	//regular vertex attribs
	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.positions)
	gl.BufferData(gl.ARRAY_BUFFER, len(data) * size_of([3]f32), data.position, gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 0, 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.texcoords)
	gl.BufferData(gl.ARRAY_BUFFER, len(data) * size_of([2]f32), data.texcoord, gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(1, 2, gl.FLOAT, false, 0, 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.colors)
	gl.BufferData(gl.ARRAY_BUFFER, len(data) * size_of([4]f32), data.color, gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(2)
	gl.VertexAttribPointer(2, 4, gl.FLOAT, false, 0, 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.normals)
	gl.BufferData(gl.ARRAY_BUFFER, len(data) * size_of([3]f32), data.normal, gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(3)
	gl.VertexAttribPointer(3, 3, gl.FLOAT, false, 0, 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.tangents)
	gl.BufferData(gl.ARRAY_BUFFER, len(data) * size_of([3]f32), data.tangent, gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(4)
	gl.VertexAttribPointer(4, 3, gl.FLOAT, false, 0, 0)

	//indices (optional)
	if indices != nil {
		when ODIN_OS == .JS {
			mesh.indices = gl.CreateBuffer()
		} else {
			gl.GenBuffers(1, &mesh.indices)
		}
		gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.indices)
		gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices) * size_of(u32), raw_data(indices), gl.STATIC_DRAW)
		mesh.size = len(indices)
	}

	//per-instance data
	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.mvps)
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

	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.modelviews)
	for i in 0..=3 {
		when ODIN_OS == .JS {
			index := i32(11+i)
		} else {
			index := u32(11+i)
		}
		gl.EnableVertexAttribArray(index)
		gl.VertexAttribPointer(index, 4, gl.FLOAT, false, size_of(matrix[4,4]f32), (uintptr)(i*size_of([4]f32)))
		gl.VertexAttribDivisor(u32(index), 1)
	}

	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.uv_offsets)
	gl.EnableVertexAttribArray(15)
	gl.VertexAttribPointer(15, 4, gl.FLOAT, false, size_of([4]f32), uintptr(0))
	gl.VertexAttribDivisor(15, 1)

	//done
	meshes[filename] = mesh
	err = .None
	return
}

//auto-instancing
@(export)
gs_draw_mesh :: proc(mesh: ^Mesh, material: ^Material, model_transform: matrix[4,4]f32 = 1, texture_region: [4]f32 = {0, 0, 1, 1}) {
	material := material^
	if _, ok := mesh.batches[material]; !ok {
		fmt.println("no batch for u >:3")
		mesh.batches[material] = make_soa(#soa[dynamic]Instance)
	}
	append_soa(&mesh.batches[material], Instance{model_transform, texture_region})
}

//called by draw
draw_all_meshes :: proc(view: matrix[4,4]f32, projection: matrix[4,4]f32, clear_queue: bool) {
	//perhaps do frustum culling based on view matrix.
	for filename, mesh in meshes {
		gl.BindVertexArray(mesh.vao)
		//dammit bill
		when ODIN_OS == .JS {
			size := mesh.size
		} else {
			size := i32(mesh.size)
		}
		//fmt.println("rendering:",filename)
		//fmt.println("mesh currently has this many batches:", len(mesh.batches))
		for material, instances in mesh.batches {
			//assign all material variables
			gl.SamplerParameteri(Material_Sampler, gl.TEXTURE_MIN_FILTER, material.texture_filter == .Trilinear? i32(gl.LINEAR_MIPMAP_LINEAR) : i32(gl.NEAREST_MIPMAP_NEAREST))
			gl.SamplerParameteri(Material_Sampler, gl.TEXTURE_MAG_FILTER, material.texture_filter == .Trilinear? i32(gl.LINEAR) : i32(gl.NEAREST))
			gl.SamplerParameteri(Material_Sampler, gl.TEXTURE_WRAP_S, material.texture_wrap == .Clamp? i32(gl.CLAMP_TO_EDGE) : i32(gl.REPEAT))
			gl.SamplerParameteri(Material_Sampler, gl.TEXTURE_WRAP_T, material.texture_wrap == .Clamp? i32(gl.CLAMP_TO_EDGE) : i32(gl.REPEAT))
			gl.ActiveTexture(gl.TEXTURE0)
			gl.BindSampler(0, Material_Sampler)
			gl.BindTexture(gl.TEXTURE_2D, material.albedo)
			gl.Uniform1i(program_uniform_albedo, 0)
			gl.Uniform4f(program_uniform_tint, expand_values(material.tint))
			gl.ActiveTexture(gl.TEXTURE1)
			gl.BindSampler(1, Material_Sampler)
			gl.BindTexture(gl.TEXTURE_2D, material.normal)
			gl.Uniform1i(program_uniform_normal, 1)
			gl.ActiveTexture(gl.TEXTURE2)
			gl.BindSampler(2, Material_Sampler)
			gl.BindTexture(gl.TEXTURE_2D, material.roughness)
			gl.Uniform1i(program_uniform_roughness, 2)
			gl.Uniform4f(program_uniform_roughness_tint, expand_values(material.roughness_tint))
			gl.ActiveTexture(gl.TEXTURE3)
			gl.BindSampler(3, Material_Sampler)
			gl.BindTexture(gl.TEXTURE_2D, material.metallic)
			gl.Uniform1i(program_uniform_metallic, 3)
			gl.Uniform4f(program_uniform_metallic_tint, expand_values(material.metallic_tint))

			//load up the instance buffer
			mvps := make([]matrix[4,4]f32, len(instances))
			defer(delete(mvps))
			modelviews := make([]matrix[4,4]f32, len(instances))
			defer(delete(modelviews))
			for instance, i in &instances {
				mvps[i] = projection * view * instance.model
				modelviews[i] = view * instance.model
			}
			gl.BindBuffer(gl.ARRAY_BUFFER, mesh.mvps)
			gl.BufferData(gl.ARRAY_BUFFER, len(instances) * size_of(matrix[4,4]f32), &mvps[0][0], gl.DYNAMIC_DRAW)
			gl.BindBuffer(gl.ARRAY_BUFFER, mesh.modelviews)
			gl.BufferData(gl.ARRAY_BUFFER, len(instances) * size_of(matrix[4,4]f32), &modelviews[0][0], gl.DYNAMIC_DRAW)
			gl.BindBuffer(gl.ARRAY_BUFFER, mesh.uv_offsets)
			gl.BufferData(gl.ARRAY_BUFFER, len(instances) * size_of([4]f32), instances.uv_offset, gl.DYNAMIC_DRAW)
			gl.BindBuffer(gl.ARRAY_BUFFER, 0)

			//fmt.println("current batch texture:", texture)
			//fmt.println("number of instances:", len(instances))
			when ODIN_OS == .JS {
				isize := len(instances)
				offset := 0
			} else {
				isize := i32(len(instances))
				offset := rawptr(uintptr(0))
			}

			if mesh.indices != 0 {
				gl.DrawElementsInstanced(gl.TRIANGLES, size, gl.UNSIGNED_INT, offset, isize)
			} else {
				gl.DrawArraysInstanced(gl.TRIANGLES, 0, size, isize)
			}
			if clear_queue {
				resize_soa(&mesh.batches[material], 0)
			}
		}
	}
}
