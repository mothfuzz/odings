package opengl

import "../common"
when common.Renderer != "gl" {
	//+ignore
}


MAX_LIGHTS :: 128

DirectionalLight :: struct {
	direction: [3]f32,
	color: [3]f32,
	strength: f32,
	shadows: bool,
}

@(export)
gs_create_directional_light :: proc(direction: [3]f32, color: [3]f32, strength: f32, shadows: bool = false) -> (d: DirectionalLight) {
	d.direction = direction
	d.color = color
	d.strength = strength
	d.shadows = shadows
	return
}

//bump counter
num_directional_lights : i32 = 0
num_directional_shadows : i32 = 0
directional_lights : [MAX_LIGHTS]DirectionalLight = {}
//directional_lights_shadow_array : Texture
@(export)
gs_draw_directional_light :: proc(d: ^DirectionalLight) {
	if num_directional_lights < MAX_LIGHTS {
		directional_lights[num_directional_lights] = d^
		num_directional_lights += 1
		if d.shadows {
			num_directional_shadows += 1
		}
	}
}

PointLight :: struct {
	position: [3]f32,
	color: [3]f32,
	radius: f32,
	shadows: bool,
}

@(export)
gs_create_point_light :: proc(position: [3]f32, color: [3]f32, radius: f32, shadows: bool = false) -> (p: PointLight) {
	p.position = position
	p.color = color
	p.radius = radius
	p.shadows = shadows
	return
}

//bump counter
num_point_lights : i32 = 0
num_point_shadows : i32 = 0
point_lights : [MAX_LIGHTS]PointLight = {}
//point_lights_shadow_array : Texture
@(export)
gs_draw_point_light :: proc(p: ^PointLight) {
	if num_point_lights < MAX_LIGHTS {
		point_lights[num_point_lights] = p^
		num_point_lights += 1
		if p.shadows {
			num_point_shadows += 1
		}
	}
}

SpotLight :: struct {
	position: [3]f32,
	direction: [3]f32,
	color: [3]f32,
	angle: f32,
	shadows: bool,
}

@(export)
gs_create_spot_light :: proc(position: [3]f32, direction: [3]f32, color: [3]f32, angle: f32, shadows: bool = false) -> (s: SpotLight) {
	s.position = position
	s.direction = direction
	s.color = color
	s.angle = angle
	s.shadows = shadows
	return
}

//bump counter
num_spot_lights : i32 = 0
num_spot_shadows : i32 = 0
spot_lights : [MAX_LIGHTS]SpotLight = {}
//spot_lights_shadow_array : Texture
@(export)
gs_draw_spot_light :: proc(s: ^SpotLight) {
	if num_spot_lights < MAX_LIGHTS {
		spot_lights[num_spot_lights] = s^
		num_spot_lights += 1
		if s.shadows {
			num_spot_shadows += 1
		}
	}
}

//load up position-only program to render shadow buffers
//create... a LOT of framebuffers
//set up all texture attachments (all depth-only)...
