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
