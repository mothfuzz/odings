//+build !js
package gamesystem

import "vendor:glfw"
import gl "vendor:OpenGL"
import "gfx/opengl"
import "gfx/common"
import "core:mem"
import "core:fmt"
import "core:strings"


window : glfw.WindowHandle

framebuffer_size_callback :: proc "c" (win: glfw.WindowHandle, width, height: i32) {
	when common.Renderer == "gl" {
		opengl.resize_viewport(width, height)
	}
}

@(export)
gs_init :: proc() {
	fmt.println("Initializing Windows...")
	glfw.Init()
	window = glfw.CreateWindow(i32(Screen_Width), i32(Screen_Height), "uwu", nil, nil)
	glfw.SetKeyCallback(window, key_callback)
	glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)
	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1)

	gl.load_up_to(4, 1, glfw.gl_set_proc_address)
	fmt.println(gl.GetString(gl.VERSION))

	i: i32
	gl.GetIntegerv(gl.MAX_VERTEX_ATTRIBS, &i)
	fmt.println("MAX_VERTEX_ATTRIBS:", i)
	gl.GetIntegerv(gl.MAX_VARYING_VECTORS, &i)
	fmt.println("MAX_VARYING_VECTORS:", i)
	gl.GetIntegerv(gl.MAX_VERTEX_UNIFORM_VECTORS, &i)
	fmt.println("MAX_VERTEX_UNIFORM_VECTORS:", i)
	gl.GetIntegerv(gl.MAX_FRAGMENT_UNIFORM_VECTORS, &i)
	fmt.println("MAX_FRAGMENT_UNIFORM_VECTORS:", i)

	when common.Renderer == "gl" {
		opengl.init()
		opengl.resize_viewport(i32(Screen_Width), i32(Screen_Height))
	}
}

@(export)
gs_run :: proc(step: proc(f64)) {
	Running = true
	prev_time: f64 = 0.0
	//kick off main loop
	for !glfw.WindowShouldClose(window) {
		if !Running {
			fmt.println("no longer running...")
			//make sure this is before step so that game code can run shutdown procedures
			glfw.SetWindowShouldClose(window, true)
		}

		glfw.PollEvents()

		time := glfw.GetTime()
		step((time - prev_time))
		prev_time = time

		glfw.SwapBuffers(window)
	}

	//kill
	glfw.DestroyWindow(window)
	glfw.Terminate()
}

Running : bool = false
@(export)
gs_running :: proc() -> bool {
	return Running
}

@(export)
gs_quit :: proc() {
	Running = false
}

@(export)
gs_window_title :: proc(title: string) {
	ctitle := strings.clone_to_cstring(title, context.temp_allocator)
	glfw.SetWindowTitle(window, ctitle)
}

@(export)
gs_get_memory :: proc() -> (mem.Allocator, mem.Allocator) {
	return context.allocator, context.temp_allocator
}

//dynlib code
init : type_of(gs_init)
run : type_of(gs_run)
quit : type_of(gs_quit)
window_title : type_of(gs_window_title)
get_memory : type_of(gs_get_memory)
running : type_of(gs_running)
@(init)
load_plat :: proc() {
	init = load_proc("gs_init", gs_init)
	run = load_proc("gs_run", gs_run)
	quit = load_proc("gs_quit", gs_quit)
	window_title = load_proc("gs_window_title", gs_window_title)
	get_memory = load_proc("gs_get_memory", gs_get_memory)
	running = load_proc("gs_running", gs_running)
}
