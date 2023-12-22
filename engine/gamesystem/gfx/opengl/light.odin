package opengl

import "../common"
when common.Renderer != "gl" {
	//+ignore
}


MAX_LIGHTS :: 128

DirectionalLight :: struct {
	direction: [3]f32,
	color: [4]f32,
	//see if there's some way to access a layer of a texture array via this texture id
	//otherwise we'll have to do it separately from the struct itself
	//and thus consider not even having the create_*_light functions
	//shadow_map: Texture,
}

@(export)
gs_create_directional_light :: proc(direction: [3]f32, color: [3]f32, strength: f32) -> (d: DirectionalLight) {
	d.direction = direction
	d.color.rgb = color
	d.color.a = strength
	//gl.GenTextures(1, &d.shadow_map)
	return
}

//bump counter
num_directional_lights : i32 = 0
directional_lights : [MAX_LIGHTS]DirectionalLight = {}
@(export)
gs_draw_directional_light :: proc(d: ^DirectionalLight) {
	if num_directional_lights < MAX_LIGHTS {
		directional_lights[num_directional_lights] = d^
		num_directional_lights += 1
	}
}

PointLight :: struct {
	position: [3]f32,
	color: [4]f32,
	//shadow_map: Texture,
}

@(export)
gs_create_point_light :: proc(position: [3]f32, color: [3]f32, radius: f32) -> (p: PointLight) {
	p.position = position
	p.color.rgb = color
	p.color.a = radius
	//gl.GenTextures(1, &p.shadow_map)
	return
}

//bump counter
num_point_lights : i32 = 0
point_lights : [MAX_LIGHTS]PointLight = {}
@(export)
gs_draw_point_light :: proc(p: ^PointLight) {
	if num_point_lights < MAX_LIGHTS {
		point_lights[num_point_lights] = p^
		num_point_lights += 1
	}
}
