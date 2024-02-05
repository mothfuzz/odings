package opengl

import "../common"
when common.Renderer != "gl" {
	//+ignore
}

Texture_Wrap :: enum {
	Clamp,
	Repeat,
}
Texture_Filter :: enum {
	Nearest,
	Trilinear,
}

Material :: struct {
	albedo: Texture,
	tint: [4]f32,
	normal: Texture,
	roughness: Texture,
	roughness_tint: [4]f32,
	metallic: Texture,
	metallic_tint: [4]f32,
	texture_wrap: Texture_Wrap,
	texture_filter: Texture_Filter,
}

materials: map[string]Material

Material_Input :: union {
	Texture,
	[3]f32,
	[4]f32,
	f32,
}

@(export)
gs_create_textured_material :: proc(resource_name: string, texture: Texture = Blank_Texture, texture_wrap: Texture_Wrap = .Repeat, texture_filter: Texture_Filter = .Nearest) -> Material {
	return gs_create_full_material(resource_name, texture, texture_wrap=texture_wrap, texture_filter=texture_filter)
}

@(export)
gs_create_shaded_material :: proc(resource_name: string,
								  color: Material_Input = nil,
								  normal: Texture = Blank_Normal,
								  roughness: Material_Input = nil,
								  metallic: Material_Input = nil,
								 ) -> Material {
	return {}
}

@(export)
gs_create_full_material :: proc(resource_name: string,
								albedo: Texture = Blank_Texture,
								tint: [4]f32 = {1, 1, 1, 1},
								normal: Texture = Blank_Normal,
								roughness: Texture = Blank_Texture,
								roughness_tint: [4]f32 = {1, 1, 1, 1},
								metallic: Texture = Blank_Texture,
								metallic_tint: [4]f32 = {1, 1, 1, 1},
								texture_wrap: Texture_Wrap = .Repeat,
								texture_filter: Texture_Filter = .Trilinear,
							   ) -> (m: Material) {
								   m = {albedo, tint, normal, roughness, roughness_tint, metallic, metallic_tint, texture_wrap, texture_filter}
	materials[resource_name] = m
	return m
}

Material_Uniforms :: struct {
	albedo : i32,
	tint : i32,
	normal : i32,
	roughness : i32,
	roughness_tint : i32,
	metallic : i32,
	metallic_tint : i32,
}

get_material_uniforms :: proc(program: Program, struct_name: string) -> (m: Material_Uniforms) {
	m.albedo = gl.GetUniformLocation(program, program_struct_field(struct_name, "albedo_texture"))
	m.tint = gl.GetUniformLocation(program, program_struct_field(struct_name, "albedo_tint"))
	m.normal = gl.GetUniformLocation(program, program_struct_field(struct_name, "normal_texture"))
	m.roughness = gl.GetUniformLocation(program, program_struct_field(struct_name, "roughness_texture"))
	m.roughness_tint = gl.GetUniformLocation(program, program_struct_field(struct_name, "roughness_tint"))
	m.metallic = gl.GetUniformLocation(program, program_struct_field(struct_name, "metallic_texture"))
	m.metallic_tint = gl.GetUniformLocation(program, program_struct_field(struct_name, "metallic_tint"))
	return
}

@(private)
apply_material :: proc(material: Material, uniforms: Material_Uniforms) {
	gl.SamplerParameteri(Material_Sampler, gl.TEXTURE_MIN_FILTER, material.texture_filter == .Trilinear? i32(gl.LINEAR_MIPMAP_LINEAR) : i32(gl.NEAREST_MIPMAP_NEAREST))
	gl.SamplerParameteri(Material_Sampler, gl.TEXTURE_MAG_FILTER, material.texture_filter == .Trilinear? i32(gl.LINEAR) : i32(gl.NEAREST))
	gl.SamplerParameteri(Material_Sampler, gl.TEXTURE_WRAP_S, material.texture_wrap == .Clamp? i32(gl.CLAMP_TO_EDGE) : i32(gl.REPEAT))
	gl.SamplerParameteri(Material_Sampler, gl.TEXTURE_WRAP_T, material.texture_wrap == .Clamp? i32(gl.CLAMP_TO_EDGE) : i32(gl.REPEAT))
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindSampler(0, Material_Sampler)
	gl.BindTexture(gl.TEXTURE_2D, material.albedo)
	gl.Uniform1i(uniforms.albedo, 0)
	gl.Uniform4f(uniforms.tint, expand_values(material.tint))
	gl.ActiveTexture(gl.TEXTURE1)
	gl.BindSampler(1, Material_Sampler)
	gl.BindTexture(gl.TEXTURE_2D, material.normal)
	gl.Uniform1i(uniforms.normal, 1)
	gl.ActiveTexture(gl.TEXTURE2)
	gl.BindSampler(2, Material_Sampler)
	gl.BindTexture(gl.TEXTURE_2D, material.roughness)
	gl.Uniform1i(uniforms.roughness, 2)
	gl.Uniform4f(uniforms.roughness_tint, expand_values(material.roughness_tint))
	gl.ActiveTexture(gl.TEXTURE3)
	gl.BindSampler(3, Material_Sampler)
	gl.BindTexture(gl.TEXTURE_2D, material.metallic)
	gl.Uniform1i(uniforms.metallic, 3)
	gl.Uniform4f(uniforms.metallic_tint, expand_values(material.metallic_tint))
}
