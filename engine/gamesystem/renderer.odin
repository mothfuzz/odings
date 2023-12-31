package gamesystem

import "gfx/common"
Vertex :: common.Vertex

import "gfx/opengl"
//TODO: move when Renderer=="opengl" to *inside* opengl code.
//that way we can skip this re-declaration. and just @(export) from within gl code.

when common.Renderer == "gl" {
	Texture :: opengl.Texture
	Sampler :: opengl.Sampler
	DirectionalLight :: opengl.DirectionalLight
	PointLight :: opengl.PointLight
	SpotLight :: opengl.SpotLight
	Material :: opengl.Material
	TextureWrap :: opengl.TextureWrap
	TextureFilter :: opengl.TextureFilter
	Mesh :: opengl.Mesh
	Mesh_Error :: opengl.Mesh_Error
	Texture_Error :: opengl.Texture_Error

	Blank_Texture : Texture = opengl.Blank_Texture
	Blank_Normal : Texture = opengl.Blank_Normal

	draw : type_of(opengl.gs_draw)

	set_projection : type_of(opengl.gs_set_projection)
	set_view : type_of(opengl.gs_set_view)
	transform_camera : type_of(opengl.gs_transform_camera)
	z2d : type_of(opengl.gs_z2d)

	load_mesh_file : type_of(opengl.gs_load_mesh_file)
	load_mesh_vertices : type_of(opengl.gs_load_mesh_vertices)
	load_mesh :: proc{load_mesh_file, load_mesh_vertices}
	draw_mesh : type_of(opengl.gs_draw_mesh)

	draw_lines : type_of(opengl.gs_draw_lines)
	draw_line_strip : type_of(opengl.gs_draw_line_strip)
	draw_line_loop : type_of(opengl.gs_draw_line_loop)

	load_texture : type_of(opengl.gs_load_texture)
	create_textured_material : type_of(opengl.gs_create_textured_material)
	create_shaded_material : type_of(opengl.gs_create_shaded_material)
	create_full_material : type_of(opengl.gs_create_full_material)
	create_material :: proc{create_textured_material, create_shaded_material, create_full_material}

	create_directional_light : type_of(opengl.gs_create_directional_light)
	draw_directional_light : type_of(opengl.gs_draw_directional_light)
	create_point_light : type_of(opengl.gs_create_point_light)
	draw_point_light : type_of(opengl.gs_draw_point_light)
	create_spot_light : type_of(opengl.gs_create_spot_light)
	draw_spot_light : type_of(opengl.gs_draw_spot_light)

	@(init)
	load_gfx :: proc() {
		draw = load_proc("gs_draw", opengl.gs_draw)

		set_projection = load_proc("gs_set_projection", opengl.gs_set_projection)
		set_view = load_proc("gs_set_view", opengl.gs_set_view)
		transform_camera = load_proc("gs_transform_camera", opengl.gs_transform_camera)
		z2d = load_proc("gs_z2d", opengl.gs_z2d)

		load_mesh_file = load_proc("gs_load_mesh_file", opengl.gs_load_mesh_file)
		load_mesh_vertices = load_proc("gs_load_mesh_vertices", opengl.gs_load_mesh_vertices)
		draw_mesh = load_proc("gs_draw_mesh", opengl.gs_draw_mesh)

		draw_lines = load_proc("gs_draw_lines", opengl.gs_draw_lines)
		draw_line_strip = load_proc("gs_draw_line_strip", opengl.gs_draw_line_strip)
		draw_line_loop = load_proc("gs_draw_line_loop", opengl.gs_draw_line_loop)

		load_texture = load_proc("gs_load_texture", opengl.gs_load_texture)
		create_textured_material = load_proc("gs_create_textured_material", opengl.gs_create_textured_material)
		create_shaded_material = load_proc("gs_create_shaded_material", opengl.gs_create_shaded_material)
		create_full_material = load_proc("gs_create_full_material", opengl.gs_create_full_material)

		create_directional_light = load_proc("gs_create_directional_light", opengl.gs_create_directional_light)
		draw_directional_light = load_proc("gs_draw_directional_light", opengl.gs_draw_directional_light)
		create_point_light = load_proc("gs_create_point_light", opengl.gs_create_point_light)
		draw_point_light = load_proc("gs_draw_point_light", opengl.gs_draw_point_light)
		create_spot_light = load_proc("gs_create_spot_light", opengl.gs_create_spot_light)
		draw_spot_light = load_proc("gs_draw_spot_light", opengl.gs_draw_spot_light)

	}
}
