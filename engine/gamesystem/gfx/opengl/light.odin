package opengl

import "core:math"

import "../common"
when common.Renderer != "gl" {
	//+ignore
}

//Up top: Actual data that gets sent to the uniform buffers.
max_combined_lights :: 498
max_spot_lights :: 248
combined_lights_buffer: Buffer
spot_lights_buffer: Buffer
when ODIN_OS == .JS {
	combined_lights_index: i32 //binding 0
	spot_lights_index: i32 //binding 1
} else {
	combined_lights_index: u32 //binding 0
	spot_lights_index: u32 //binding 1
}

Shader_Combined_Light :: struct #align(16) {
	posdir: [4]f32,
	color: [4]f32,
}
Shader_Combined_Light_Shadowed :: struct #align(16) {
	posdir: [4]f32,
	color: [4]f32,
	viewproj: matrix[4,4]f32,
}
directional_lights : [dynamic]Shader_Combined_Light = {}
directional_lights_shadowed : [dynamic]Shader_Combined_Light_Shadowed = {}
point_lights : [dynamic]Shader_Combined_Light = {}
point_lights_shadowed : [dynamic]Shader_Combined_Light = {}

combined_light_available :: proc() -> bool {
	//bc every non-shadowed directional light takes up 1/3 the space
	//and we have 166 combined lights total
	return len(directional_lights) +
		3 * len(directional_lights_shadowed) +
		len(point_lights) +
		len(point_lights_shadowed) < max_combined_lights
}

Shader_Spot_Light :: struct #align(16) {
	position: [4]f32,
	direction: [4]f32,
	color: [4]f32,
	padding: [4]f32,
}
Shader_Spot_Light_Shadowed :: struct #align(16) {
	position: [4]f32,
	direction: [4]f32,
	color: [4]f32,
	padding: [4]f32,
	viewproj: matrix[4,4]f32,
}
spot_lights : [dynamic]Shader_Spot_Light = {}
spot_lights_shadowed : [dynamic]Shader_Spot_Light_Shadowed = {}

spot_light_available :: proc() -> bool {
	//every non-shadowed spotlight takes up 1/2 the space
	return len(spot_lights) +
		2 * len(spot_lights_shadowed) < max_spot_lights
}

//Then, actual user-facing stuff

Directional_Light :: struct {
	direction: [3]f32,
	color: [3]f32,
	strength: f32,
	shadows: bool,
}

@(export)
gs_create_directional_light :: proc(direction: [3]f32, color: [3]f32, strength: f32, shadows: bool = false) -> (d: Directional_Light) {
	d.direction = direction
	d.color = color
	d.strength = strength
	d.shadows = shadows
	if shadows {
		create_directional_shadow()
	}
	return
}

@(export)
gs_draw_directional_light :: proc(d: ^Directional_Light) {
	if combined_light_available() {
		posdir : [4]f32 = {d.direction.x, d.direction.y, d.direction.z, 0.0}
		color : [4]f32 = {d.color.r, d.color.g, d.color.b, d.strength}
		if d.shadows {
			//avoid calculating viewproj until shadow rendering time
			append(&directional_lights_shadowed, Shader_Combined_Light_Shadowed{posdir, color, 1})
		} else {
			append(&directional_lights, Shader_Combined_Light{posdir, color})
		}
	}
}

Point_Light :: struct {
	position: [3]f32,
	color: [3]f32,
	radius: f32,
	shadows: bool,
}

@(export)
gs_create_point_light :: proc(position: [3]f32, color: [3]f32, radius: f32, shadows: bool = false) -> (p: Point_Light) {
	p.position = position
	p.color = color
	p.radius = radius
	p.shadows = shadows
	return
}

@(export)
gs_draw_point_light :: proc(p: ^Point_Light) {
	if combined_light_available() {
		posdir : [4]f32 = {p.position.x, p.position.y, p.position.z, 1.0}
		color : [4]f32 = {p.color.r, p.color.g, p.color.b, p.radius}
		if p.shadows {
			append(&point_lights_shadowed, Shader_Combined_Light{posdir, color})
		} else {
			append(&point_lights, Shader_Combined_Light{posdir, color})
		}
	}
}

Spot_Light :: struct {
	position: [3]f32,
	direction: [3]f32,
	color: [3]f32,
	angle: f32,
	shadows: bool,
}

@(export)
gs_create_spot_light :: proc(position: [3]f32, direction: [3]f32, color: [3]f32, angle: f32, shadows: bool = false) -> (s: Spot_Light) {
	s.position = position
	s.direction = direction
	s.color = color
	s.angle = angle
	s.shadows = shadows
	return
}

@(export)
gs_draw_spot_light :: proc(s: ^Spot_Light) {
	if spot_light_available() {
		position : [4]f32 = {s.position.x, s.position.y, s.position.z, 1.0}
		direction : [4]f32 = {s.direction.x, s.direction.y, s.direction.z, 0.0}
		color : [4]f32 = {s.color.r, s.color.g, s.color.b, math.cos(math.to_radians(s.angle))}
		if s.shadows {
			append(&spot_lights_shadowed, Shader_Spot_Light_Shadowed{position, direction, color, {}, 1})
		} else {
			append(&spot_lights, Shader_Spot_Light{position, direction, color, {}})
		}
	}
}

//shadow samplers
directional_shadow_texture_uniform : i32
point_shadow_texture_uniform : i32
spot_shadow_texture_uniform : i32

import "core:fmt"

init_program_lights :: proc() {
	directional_lights = make([dynamic]Shader_Combined_Light)
	directional_lights_shadowed = make([dynamic]Shader_Combined_Light_Shadowed)
	point_lights = make([dynamic]Shader_Combined_Light)
	point_lights_shadowed = make([dynamic]Shader_Combined_Light)
	spot_lights = make([dynamic]Shader_Spot_Light)
	spot_lights_shadowed = make([dynamic]Shader_Spot_Light_Shadowed)

	directional_shadow_framebuffers = make([dynamic]Framebuffer)
	spot_shadow_framebuffers = make([dynamic]Framebuffer)
	point_shadow_framebuffers = make([dynamic]Framebuffer)

	when ODIN_OS == .JS {
		directional_shadow_texture = {gl.CreateTexture(), gl.CreateTexture()}
		point_shadow_texture = {gl.CreateTexture(), gl.CreateTexture()}
		spot_shadow_texture = {gl.CreateTexture(), gl.CreateTexture()}
	} else {
		gl.GenTextures(2, &directional_shadow_texture[0])
		gl.GenTextures(2, &spot_shadow_texture[0])
		gl.GenTextures(2, &point_shadow_texture[0])
	}

	//light uniforms for our main shader
	when ODIN_OS == .JS {
		combined_lights_buffer = gl.CreateBuffer()
		spot_lights_buffer = gl.CreateBuffer()
	} else {
		gl.GenBuffers(1, &combined_lights_buffer)
		gl.GenBuffers(1, &spot_lights_buffer)
	}

	combined_lights_index = gl.GetUniformBlockIndex(program, "CombinedLights")
	gl.UniformBlockBinding(program, combined_lights_index, 0)
	gl.BindBuffer(gl.UNIFORM_BUFFER, combined_lights_buffer)
	gl.BindBufferBase(gl.UNIFORM_BUFFER, 0, combined_lights_buffer)

	spot_lights_index = gl.GetUniformBlockIndex(program, "SpotLights")
	gl.UniformBlockBinding(program, spot_lights_index, 1)
	gl.BindBuffer(gl.UNIFORM_BUFFER, spot_lights_buffer)
	gl.BindBufferBase(gl.UNIFORM_BUFFER, 1, spot_lights_buffer)

	//shadow uniforms
	directional_shadow_texture_uniform = gl.GetUniformLocation(program, "directional_light_shadows")
	fmt.println("directional_shadow_texture_uniform:", directional_shadow_texture_uniform)
	when ODIN_OS != .JS {
		point_shadow_texture_uniform = gl.GetUniformLocation(program, "point_light_shadows")
	}
	spot_shadow_texture_uniform = gl.GetUniformLocation(program, "spot_light_shadows")
}

apply_lights :: proc() {
	for i in 0..<len(directional_lights) {
		directional_lights[i].posdir.y = -directional_lights[i].posdir.y
		directional_lights[i].posdir = view * directional_lights[i].posdir
	}
	for i in 0..<len(directional_lights_shadowed) {
		directional_lights_shadowed[i].posdir.y = -directional_lights_shadowed[i].posdir.y
		directional_lights_shadowed[i].posdir = view * directional_lights_shadowed[i].posdir
	}
	for i in 0..<len(point_lights) {
		point_lights[i].posdir = view * point_lights[i].posdir
	}
	for i in 0..<len(point_lights_shadowed) {
		point_lights_shadowed[i].posdir = view * point_lights_shadowed[i].posdir
	}
	for i in 0..<len(spot_lights) {
		//spot_lights[i].direction.y = -spot_lights[i].direction.y
		spot_lights[i].position = view * spot_lights[i].position
		spot_lights[i].direction = view * spot_lights[i].direction
	}
	for i in 0..<len(spot_lights_shadowed) {
		//spot_lights_shadowed[i].direction.y = -spot_lights_shadowed[i].direction.y
		spot_lights_shadowed[i].position = view * spot_lights_shadowed[i].position
		spot_lights_shadowed[i].direction = view * spot_lights_shadowed[i].direction
	}

	gl.BindBuffer(gl.UNIFORM_BUFFER, combined_lights_buffer)
	dls_size := len(directional_lights_shadowed) * size_of(Shader_Combined_Light_Shadowed)
	dl_size := len(directional_lights) * size_of(Shader_Combined_Light)
	pls_size := len(point_lights_shadowed) * size_of(Shader_Combined_Light)
	pl_size := len(point_lights) * size_of(Shader_Combined_Light)
	lengths_size := size_of([4]i32)

	gl.BufferData(gl.UNIFORM_BUFFER, lengths_size + dls_size + dl_size + pls_size + pl_size, nil, gl.DYNAMIC_DRAW)
	offset := 0
	sizes := [4]i32{i32(len(directional_lights_shadowed)), i32(len(directional_lights)), i32(len(point_lights_shadowed)), i32(len(point_lights))}
	gl.BufferSubData(gl.UNIFORM_BUFFER, ot(offset), lengths_size, &sizes[0])
	offset += lengths_size
	gl.BufferSubData(gl.UNIFORM_BUFFER, ot(offset), dls_size, raw_data(directional_lights_shadowed))
	offset += dls_size
	gl.BufferSubData(gl.UNIFORM_BUFFER, ot(offset), dl_size, raw_data(directional_lights))
	offset += dl_size
	gl.BufferSubData(gl.UNIFORM_BUFFER, ot(offset), pls_size, raw_data(point_lights_shadowed))
	offset += pls_size
	gl.BufferSubData(gl.UNIFORM_BUFFER, ot(offset), pl_size, raw_data(point_lights))

	gl.BindBuffer(gl.UNIFORM_BUFFER, spot_lights_buffer)
	sls_size := len(spot_lights_shadowed) * size_of(Shader_Spot_Light_Shadowed)
	sl_size := len(spot_lights) * size_of(Shader_Spot_Light)

	gl.BufferData(gl.UNIFORM_BUFFER, lengths_size + sls_size + sl_size, nil, gl.DYNAMIC_DRAW)
	offset = 0
	ssizes := [4]i32{i32(len(spot_lights_shadowed)), i32(len(spot_lights)), 0, 0}
	gl.BufferSubData(gl.UNIFORM_BUFFER, ot(offset), lengths_size, &ssizes[0])
	offset += lengths_size
	gl.BufferSubData(gl.UNIFORM_BUFFER, ot(offset), sls_size, raw_data(spot_lights_shadowed))
	offset += sls_size
	gl.BufferSubData(gl.UNIFORM_BUFFER, ot(offset), sl_size, raw_data(spot_lights))

	gl.ActiveTexture(gl.TEXTURE4)
	gl.BindTexture(gl.TEXTURE_2D_ARRAY, directional_shadow_texture[1])
	gl.Uniform1i(directional_shadow_texture_uniform, 4)
	//gl.ActiveTexture(gl.TEXTURE5)
	//gl.ActiveTexture(gl.TEXTURE6)
}

//again I say, dammit bill.
when ODIN_OS == .JS {
	ot :: proc(a: int) -> uintptr {
		return uintptr(a)
	}
} else {
	ot :: proc(a: int) -> int {
		return a
	}
}

reset_lights :: proc() {
	clear(&directional_lights)
	clear(&directional_lights_shadowed)
	clear(&point_lights)
	clear(&point_lights_shadowed)
	clear(&spot_lights)
	clear(&spot_lights_shadowed)
}
