package opengl

import "core:fmt"

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
program_uniform_depth_prepass : i32
program_uniform_trans_pass : i32
program_uniform_texture_correct : i32
program_uniform_screen_width : i32
program_uniform_screen_height : i32
program_uniform_fog_color : i32

Blank_Texture : Texture
Blank_Normal : Texture

Material_Sampler : Sampler

clear_color : [4]f32 = {0.5, 0.2, 1.0, 1.0}


load_program :: proc(vs_str, fs_str: string) -> (Program, bool) {
	when ODIN_OS == .JS {
		vs_str := fmt.tprint("#version 300 es", vs_str, sep="\n")
		fs_str := fmt.tprint("#version 300 es", fs_str, sep="\n")
		return gl.CreateProgramFromStrings({vs_str}, {fs_str})
	} else {
		vs_str := fmt.tprint("#version 410", vs_str, sep="\n")
		fs_str := fmt.tprint("#version 410", fs_str, sep="\n")
		return gl.load_shaders_source(vs_str, fs_str)
	}
}

//called in plat.
init :: proc() {

	textures = make(map[string]Texture, 1)
	meshes = make(map[string]Mesh, 1)

	//quality scaling based on capabilities
	max_frag_vectors: i32
	when ODIN_OS==.JS {
		max_frag_vectors = gl.GetParameter(gl.MAX_FRAGMENT_UNIFORM_VECTORS)
	} else {
		gl.GetIntegerv(gl.MAX_FRAGMENT_UNIFORM_VECTORS, &max_frag_vectors)
	}
	fmt.println("MAX_FRAGMENT_UNIFORM_VECTORS:", max_frag_vectors)
	remaining_frag_vectors := max_frag_vectors
	remaining_frag_vectors -= 7 //material params
	remaining_frag_vectors -= 1 //texture_correct
	remaining_frag_vectors -= 1 //depth_prepass
	remaining_frag_vectors -= 1 //trans_pass
	remaining_frag_vectors -= 1 //fog_color
	remaining_frag_vectors -= 3 * common.Max_Directional_Lights
	fmt.println("available uniform vectors:", remaining_frag_vectors)
	requested_light_vectors: i32 = common.Max_Point_Lights * 3 + common.Max_Spot_Lights * 4
	fmt.println("required uniform vectors for lighting:", requested_light_vectors)
	if requested_light_vectors > remaining_frag_vectors {
		overage: f32 = f32(remaining_frag_vectors)/f32(requested_light_vectors)
		common.Max_Point_Lights = i32(f32(common.Max_Point_Lights) * overage)
		common.Max_Spot_Lights = i32(f32(common.Max_Spot_Lights) * overage)
		fmt.println("max directional lights:", common.Max_Directional_Lights)
		fmt.println("adjusted max point lights:", common.Max_Point_Lights)
		fmt.println("adjusted max spot lights:", common.Max_Spot_Lights)
	} else {
		fmt.println("max directional lights:", common.Max_Directional_Lights)
		fmt.println("max point lights:", common.Max_Point_Lights)
		fmt.println("max spot lights:", common.Max_Spot_Lights)
	}

	//load our shaders...
	vs_str: string = #load("ps1.vert")
	fs_str: string = #load("ps1.frag")
	dl := fmt.tprintf("#define MAX_DIRECTIONAL_LIGHTS %d", common.Max_Directional_Lights)
	pl := fmt.tprintf("#define MAX_POINT_LIGHTS %d", common.Max_Point_Lights)
	sl := fmt.tprintf("#define MAX_SPOT_LIGHTS %d", common.Max_Spot_Lights)
	fs_str = fmt.tprint(dl, pl, sl, fs_str, sep="\n")
	if p, ok := load_program(vs_str, fs_str); ok {
		program = p
	} else {
		fmt.eprintln("failed to load main shaders")
	}
	gl.UseProgram(program)
	program_uniform_depth_prepass = gl.GetUniformLocation(program, "depth_prepass")
	program_uniform_trans_pass = gl.GetUniformLocation(program, "trans_pass")
	program_uniform_texture_correct = gl.GetUniformLocation(program, "texture_correct")
	gl.Uniform1i(program_uniform_texture_correct, 1)
	program_uniform_screen_width = gl.GetUniformLocation(program, "screen_width")
	program_uniform_screen_height = gl.GetUniformLocation(program, "screen_height")
	program_uniform_fog_color = gl.GetUniformLocation(program, "fog_color")
	gl.Uniform4f(program_uniform_fog_color, clear_color.r, clear_color.g, clear_color.b, clear_color.a)

	init_program_materials()
	init_program_lights()

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
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
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

	//loop through all lights and draw them depth-only to a texture if they have shadows enabled
	//draw meshes, draw sprites, untextured

	//depth pre-pass
	gl.DepthMask(true)
	gl.DepthFunc(gl.LESS)
	//gl.ColorMask(false, false, false, false)
	gl.Clear(gl.DEPTH_BUFFER_BIT | gl.COLOR_BUFFER_BIT)
	gl.Uniform1i(program_uniform_depth_prepass, 1)
	draw_all_meshes(view, projection)

	//draw main scene, fully lit
	gl.ClearColor(clear_color.r, clear_color.g, clear_color.b, clear_color.a)
	gl.DepthMask(false)
	gl.DepthFunc(gl.LEQUAL)
	//gl.ColorMask(true, true, true, true)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	gl.Uniform1i(program_uniform_depth_prepass, 0)
	apply_lights()

	//draw opaque pixels, then transparent pixels on top
	gl.Uniform1i(program_uniform_trans_pass, 0)
	draw_all_meshes(view, projection)
	gl.Uniform1i(program_uniform_trans_pass, 1)
	draw_all_meshes(view, projection)

	reset_meshes()

	//draw lines over everything else, unlit
	reset_lights()
	gl.Uniform1i(program_uniform_trans_pass, 0)
	draw_all_lines(view, projection)

	//draw UI layer, unlit, orthographic perspective.

	//check for errors
	for err := gl.GetError(); err != gl.NO_ERROR; err = gl.GetError() {
		fmt.eprintln(err)
	}
}
