package opengl

import "core:fmt"
import "core:strings"

import "core:math"
import "core:math/linalg/glsl"

import "vendor:wasm/WebGL"
import "vendor:OpenGL"

import "../common"
when common.Renderer != "gl" {
	//+ignore
}

when ODIN_OS == .JS {
	gl :: WebGL
	VertexArrayObject  :: WebGL.VertexArrayObject
	Buffer       :: WebGL.Buffer
	Framebuffer  :: WebGL.Framebuffer
	Program      :: WebGL.Program
	Renderbuffer :: WebGL.Renderbuffer
	Shader       :: WebGL.Shader
	Texture      :: WebGL.Texture
	Sampler		 :: WebGL.Sampler
} else {
	gl :: OpenGL
	VertexArrayObject	:: u32
	Buffer       		:: u32
	Framebuffer  		:: u32
	Program      		:: u32
	Renderbuffer 		:: u32
	Shader       		:: u32
	Texture      		:: u32
	Sampler				:: u32
}

//camera
view : matrix[4,4]f32
projection : matrix[4,4]f32
z2d : f32

//shader params
program : Program
program_uniform_texture_correct : i32
program_uniform_screen_width : i32
program_uniform_screen_height : i32
program_uniform_fog_color : i32
program_uniform_num_lights : i32
//shader params - material
program_uniform_albedo : i32
program_uniform_tint : i32
program_uniform_normal : i32
program_uniform_roughness : i32
program_uniform_roughness_tint : i32
program_uniform_metallic : i32
program_uniform_metallic_tint : i32
//shader params - lights
num_directional_lights_uniform : i32
directional_light_direction_uniforms : [MAX_LIGHTS]i32 = {}
directional_light_color_uniforms : [MAX_LIGHTS]i32 = {}
directional_light_shadow_uniforms : [MAX_LIGHTS]i32 = {}
num_point_lights_uniform : i32
point_light_position_uniforms : [MAX_LIGHTS]i32 = {}
point_light_color_uniforms : [MAX_LIGHTS]i32 = {}
point_light_shadow_uniforms : [MAX_LIGHTS]i32 = {}

Blank_Texture : Texture
Blank_Normal : Texture

Material_Sampler : Sampler

clear_color : [4]f32 = {0.5, 0.2, 1.0, 1.0}

uniform_array :: proc(uniform: string, index: int) -> i32 {
	s := fmt.tprintf(uniform, index)
	when ODIN_OS == .JS {
		c := s
	} else {
		c := strings.clone_to_cstring(s, context.temp_allocator)
	}
	return gl.GetUniformLocation(program, c)
}

//called in plat.
init :: proc() {

	textures = make(map[string]Texture, 1)
	meshes = make(map[string]Mesh, 1)

	//load our shaders...
	vs_str: string = #load("ps1.vert")
	fs_str: string = #load("ps1.frag")
	when ODIN_OS == .JS {
		vs_str = fmt.tprint("#version 300 es", vs_str, sep="\n")
		fs_str = fmt.tprint("#version 300 es", fs_str, sep="\n")
		if p, ok := gl.CreateProgramFromStrings({vs_str}, {fs_str}); ok {
			program = p

		} else {
			fmt.eprintln("failed to load shaders")
		}
	} else {
		vs_str = fmt.tprint("#version 410", vs_str, sep="\n")
		fs_str = fmt.tprint("#version 410", fs_str, sep="\n")
		if p, ok := gl.load_shaders_source(vs_str, fs_str); ok {
			program = p
		} else {
			fmt.eprintln("failed to load shaders")
		}
	}
	gl.UseProgram(program)
	program_uniform_texture_correct = gl.GetUniformLocation(program, "texture_correct")
	gl.Uniform1i(program_uniform_texture_correct, 1)
	program_uniform_screen_width = gl.GetUniformLocation(program, "screen_width")
	program_uniform_screen_height = gl.GetUniformLocation(program, "screen_height")
	program_uniform_fog_color = gl.GetUniformLocation(program, "fog_color")
	gl.Uniform4f(program_uniform_fog_color, clear_color.r, clear_color.g, clear_color.b, clear_color.a)
	program_uniform_num_lights = gl.GetUniformLocation(program, "num_lights");
	//material params
	program_uniform_albedo = gl.GetUniformLocation(program, "albedo_texture")
	program_uniform_tint = gl.GetUniformLocation(program, "albedo_tint")
	program_uniform_normal = gl.GetUniformLocation(program, "normal_texture")
	program_uniform_roughness = gl.GetUniformLocation(program, "roughness_texture")
	program_uniform_roughness_tint = gl.GetUniformLocation(program, "roughness_tint")
	program_uniform_metallic = gl.GetUniformLocation(program, "metallic_texture")
	program_uniform_metallic_tint = gl.GetUniformLocation(program, "metallic_tint")
	//light params
	num_directional_lights_uniform = gl.GetUniformLocation(program, "num_directional_lights")
	num_point_lights_uniform = gl.GetUniformLocation(program, "num_point_lights")
	for i in 0..<MAX_LIGHTS {
		directional_light_direction_uniforms[i] = uniform_array("directional_lights[%d].direction", i)
		directional_light_color_uniforms[i] = uniform_array("directional_lights[%d].color", i)
		//directional_light_shadow_uniforms : [MAX_LIGHTS]int = {}

		point_light_position_uniforms[i] = uniform_array("point_lights[%d].position", i)
		point_light_color_uniforms[i] = uniform_array("point_lights[%d].color", i)
		//point_light_shadow_uniforms : [MAX_LIGHTS]int = {}
	}

	Blank_Texture, _ = gs_load_texture("blank.png", #load("blank.png"))
	Blank_Normal, _ = gs_load_texture("blank_normal.png", #load("blank_normal.png"))

	when ODIN_OS == .JS {
		Material_Sampler = gl.CreateSampler()
	} else {
		gl.GenSamplers(1, &Material_Sampler)
	}

	view = glsl.identity(matrix[4,4]f32)
	//view = glsl.mat4LookAt({0, 0, -3}, {0, 0, 0}, {0, -1, 0})
	//projection = glsl.mat4Perspective(math.PI / 3.0, 4.0 / 3.0, 0.1, 1000)
	gl.Enable(gl.CULL_FACE)
	gl.Enable(gl.DEPTH_TEST)
	//gl.Enable(gl.BLEND)
	//gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
}

//also called in plat
resize_viewport :: proc "contextless" (width, height: i32) {
	projection = glsl.mat4Perspective(math.PI / 3.0, f32(width) / f32(height), 0.1, 1024+4096)
	gl.Viewport(0, 0, width, height)
	gl.Uniform1f(program_uniform_screen_width, f32(width))
	gl.Uniform1f(program_uniform_screen_height, f32(height))

	z2d = math.sqrt(math.pow(f32(height), 2) - math.pow(f32(height)/2.0, 2))
}

@(export)
gs_set_projection :: proc(p: matrix[4,4]f32) {
	projection = p
}
@(export)
gs_set_view :: proc(v: matrix[4,4]f32) {
	view = v
}
@(export)
gs_transform_camera :: proc(t: matrix[4,4]f32) {
	view = inverse(t)
}
@(export)
gs_z2d :: proc() -> f32 {
	return z2d
}

@(export)
gs_draw :: proc() {

	gl.ClearColor(clear_color.r, clear_color.g, clear_color.b, clear_color.a)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	//loop through all lights and draw them depth-only to a texture if they have shadows enabled

	//draw main scene, fully lit
	gl.Uniform1i(num_directional_lights_uniform, num_directional_lights)
	for i in 0..<num_directional_lights {
		d := directional_lights[i].direction
		direction := (view * [4]f32{d.x, -d.y, d.z, 0.0}).xyz
		gl.Uniform3f(directional_light_direction_uniforms[i], expand_values(direction))
		gl.Uniform4f(directional_light_color_uniforms[i], expand_values(directional_lights[i].color))
		//shadow...
	}
	gl.Uniform1i(num_point_lights_uniform, num_point_lights)
	for i in 0..<num_point_lights {
		p := point_lights[i].position
		position := (view * [4]f32{p.x, p.y, p.z, 1.0}).xyz
		gl.Uniform3f(point_light_position_uniforms[i], expand_values(position))
		gl.Uniform4f(point_light_color_uniforms[i], expand_values(point_lights[i].color))
		//shadow...
	}
	draw_all_meshes(view, projection, true)
	num_point_lights = 0;
	num_directional_lights = 0;

	//draw lines over everything else, unlit
	gl.Uniform1i(num_point_lights_uniform, 0)
	gl.Uniform1i(num_directional_lights_uniform, 0)
	draw_all_lines()

	//check for errors
	for err := gl.GetError(); err != gl.NO_ERROR; err = gl.GetError() {
		fmt.eprintln(err)
	}
}
