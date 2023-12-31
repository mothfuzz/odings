package opengl

import "core:math"

import "../common"
when common.Renderer != "gl" {
	//+ignore
}


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
directional_lights : [dynamic]DirectionalLight = {}
//directional_lights_shadow_array : Texture
@(export)
gs_draw_directional_light :: proc(d: ^DirectionalLight) {
	if num_directional_lights < common.Max_Directional_Lights {
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
point_lights : [dynamic]PointLight = {}
//point_lights_shadow_array : Texture
@(export)
gs_draw_point_light :: proc(p: ^PointLight) {
	if num_point_lights < common.Max_Point_Lights {
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
spot_lights : [dynamic]SpotLight = {}
//spot_lights_shadow_array : Texture
@(export)
gs_draw_spot_light :: proc(s: ^SpotLight) {
	if num_spot_lights < common.Max_Spot_Lights {
		spot_lights[num_spot_lights] = s^
		num_spot_lights += 1
		if s.shadows {
			num_spot_shadows += 1
		}
	}
}

//shader params - lights
//directional
num_directional_lights_uniform : i32
directional_light_direction_uniforms : [dynamic]i32 = {}
directional_light_color_uniforms : [dynamic]i32 = {}
directional_light_shadow_uniforms : [dynamic]i32 = {}
//point
num_point_lights_uniform : i32
point_light_position_uniforms : [dynamic]i32 = {}
point_light_color_uniforms : [dynamic]i32 = {}
point_light_shadow_uniforms : [dynamic]i32 = {}
//spot
num_spot_lights_uniform: i32
spot_light_position_uniforms : [dynamic]i32 = {}
spot_light_direction_uniforms : [dynamic]i32 = {}
spot_light_color_uniforms : [dynamic]i32 = {}
spot_light_shadow_uniforms : [dynamic]i32 = {}

init_program_lights :: proc() {
	directional_lights = make([dynamic]DirectionalLight, common.Max_Directional_Lights)
	point_lights = make([dynamic]PointLight, common.Max_Point_Lights)
	spot_lights = make([dynamic]SpotLight, common.Max_Spot_Lights)

	//light uniforms for our main shader
	num_directional_lights_uniform = gl.GetUniformLocation(program, "num_directional_lights")
	num_point_lights_uniform = gl.GetUniformLocation(program, "num_point_lights")
	num_spot_lights_uniform = gl.GetUniformLocation(program, "num_spot_lights")
	directional_light_direction_uniforms = make([dynamic]i32, common.Max_Directional_Lights)
	directional_light_color_uniforms = make([dynamic]i32, common.Max_Directional_Lights)
	directional_light_shadow_uniforms = make([dynamic]i32, common.Max_Directional_Lights)
	for i in 0..< int(common.Max_Directional_Lights) {
		directional_light_direction_uniforms[i] = uniform_array("directional_lights[%d].direction", i)
		directional_light_color_uniforms[i] = uniform_array("directional_lights[%d].color", i)
		directional_light_shadow_uniforms[i] = uniform_array("directional_lights[%d].shadows", i)
	}
	point_light_position_uniforms = make([dynamic]i32, common.Max_Point_Lights)
	point_light_color_uniforms = make([dynamic]i32, common.Max_Point_Lights)
	point_light_shadow_uniforms = make([dynamic]i32, common.Max_Point_Lights)
	for i in 0..< int(common.Max_Point_Lights) {
		point_light_position_uniforms[i] = uniform_array("point_lights[%d].position", i)
		point_light_color_uniforms[i] = uniform_array("point_lights[%d].color", i)
		point_light_shadow_uniforms[i] = uniform_array("point_lights[%d].shadows", i)
	}
	spot_light_position_uniforms = make([dynamic]i32, common.Max_Spot_Lights)
	spot_light_direction_uniforms = make([dynamic]i32, common.Max_Spot_Lights)
	spot_light_color_uniforms = make([dynamic]i32, common.Max_Spot_Lights)
	spot_light_shadow_uniforms = make([dynamic]i32, common.Max_Spot_Lights)
	for i in 0..< int(common.Max_Spot_Lights) {
		spot_light_position_uniforms[i] = uniform_array("spot_lights[%d].position", i)
		spot_light_direction_uniforms[i] = uniform_array("spot_lights[%d].direction", i)
		spot_light_color_uniforms[i] = uniform_array("spot_lights[%d].color", i)
		spot_light_shadow_uniforms[i] = uniform_array("spot_lights[%d].shadows", i)
	}
}

apply_lights :: proc() {
	gl.Uniform1i(num_directional_lights_uniform, num_directional_lights)
	for i in 0..<num_directional_lights {
		d := directional_lights[i].direction
		direction := (view * [4]f32{d.x, -d.y, d.z, 0.0}).xyz
		gl.Uniform3f(directional_light_direction_uniforms[i], expand_values(direction))
		gl.Uniform4f(directional_light_color_uniforms[i], expand_values(directional_lights[i].color), directional_lights[i].strength)
		gl.Uniform1i(directional_light_shadow_uniforms[i], i32(directional_lights[i].shadows))
	}
	gl.Uniform1i(num_point_lights_uniform, num_point_lights)
	for i in 0..<num_point_lights {
		p := point_lights[i].position
		position := (view * [4]f32{p.x, p.y, p.z, 1.0}).xyz
		gl.Uniform3f(point_light_position_uniforms[i], expand_values(position))
		gl.Uniform4f(point_light_color_uniforms[i], expand_values(point_lights[i].color), point_lights[i].radius)
		gl.Uniform1i(point_light_shadow_uniforms[i], i32(point_lights[i].shadows))
	}
	gl.Uniform1i(num_spot_lights_uniform, num_spot_lights)
	for i in 0..<num_spot_lights {
		p := spot_lights[i].position
		position := (view * [4]f32{p.x, p.y, p.z, 1.0}).xyz
		gl.Uniform3f(spot_light_position_uniforms[i], expand_values(position))
		d := spot_lights[i].direction
		direction := (view * [4]f32{d.x, d.y, d.z, 0.0}).xyz
		gl.Uniform3f(spot_light_direction_uniforms[i], expand_values(direction))
		gl.Uniform4f(spot_light_color_uniforms[i], expand_values(spot_lights[i].color), math.cos(math.to_radians(spot_lights[i].angle)))
		gl.Uniform1i(spot_light_shadow_uniforms[i], i32(spot_lights[i].shadows))
	}
}

reset_lights :: proc() {
	num_point_lights = 0;
	num_directional_lights = 0;
	num_spot_lights = 0;
	gl.Uniform1i(num_point_lights_uniform, 0)
	gl.Uniform1i(num_directional_lights_uniform, 0)
	gl.Uniform1i(num_spot_lights_uniform, 0)
}

//load up position-only program to render shadow buffers
//create... a LOT of framebuffers
//set up all texture attachments (all depth-only)...
