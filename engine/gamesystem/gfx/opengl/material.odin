package opengl

import "../common"
when common.Renderer != "gl" {
	//+ignore
}

TextureWrap :: enum {
	Clamp,
	Repeat,
}
TextureFilter :: enum {
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
	texture_wrap: TextureWrap,
	texture_filter: TextureFilter,
}

materials: map[string]Material

MaterialInput :: union {
	Texture,
	[3]f32,
	[4]f32,
	f32,
}

@(export)
gs_create_textured_material :: proc(resource_name: string, texture: Texture = Blank_Texture, texture_wrap: TextureWrap = .Repeat, texture_filter: TextureFilter = .Nearest) -> Material {
	return gs_create_full_material(resource_name, texture, texture_wrap=texture_wrap, texture_filter=texture_filter)
}

@(export)
gs_create_shaded_material :: proc(resource_name: string,
								  color: MaterialInput = nil,
								  normal: Texture = Blank_Normal,
								  roughness: MaterialInput = nil,
								  metallic: MaterialInput = nil,
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
								texture_wrap: TextureWrap = .Repeat,
								texture_filter: TextureFilter = .Trilinear,
							   ) -> (m: Material) {
								   m = {albedo, tint, normal, roughness, roughness_tint, metallic, metallic_tint, texture_wrap, texture_filter}
	materials[resource_name] = m
	return m
}

//shader params - material
program_uniform_albedo : i32
program_uniform_tint : i32
program_uniform_normal : i32
program_uniform_roughness : i32
program_uniform_roughness_tint : i32
program_uniform_metallic : i32
program_uniform_metallic_tint : i32

@(private)
init_program_materials :: proc() {
	//material uniforms for main shader
	program_uniform_albedo = gl.GetUniformLocation(program, "albedo_texture")
	program_uniform_tint = gl.GetUniformLocation(program, "albedo_tint")
	program_uniform_normal = gl.GetUniformLocation(program, "normal_texture")
	program_uniform_roughness = gl.GetUniformLocation(program, "roughness_texture")
	program_uniform_roughness_tint = gl.GetUniformLocation(program, "roughness_tint")
	program_uniform_metallic = gl.GetUniformLocation(program, "metallic_texture")
	program_uniform_metallic_tint = gl.GetUniformLocation(program, "metallic_tint")
}

@(private)
apply_material :: proc(material: Material) {
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
}
