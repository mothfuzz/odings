//+build js
package gamesystem

import "core:fmt"

import "vendor:wasm/js"
import gl "vendor:wasm/WebGL"
import "gfx/common"
import "gfx/opengl"

foreign import js_extra "js_extra"
@(default_calling_convention="contextless")
foreign js_extra {
	resize_canvas :: proc(width, height: int) ---
	set_window_title :: proc(title: string) ---
}

//main memory on web is half a gig, I can't imagine any web game being more than that.
main_memory_size :: 512*mem.Megabyte
//temp memory mainly used for texture loading,
//4096*4096*32bpp is 60something megabytes so just to be safe do 128. Lower if needed.
temp_memory_size :: 128*mem.Megabyte

arena_buf: []byte
arena : mem.Arena
scratch : mem.Scratch_Allocator

//see ya later allocator
alloc: mem.Allocator
temp_alloc: mem.Allocator

import "core:mem"
import "core:intrinsics"
init :: proc() {
	using js.Event_Kind
	js.add_window_event_listener(.Key_Down, nil, key_down_callback)
	js.add_window_event_listener(.Key_Up, nil, key_up_callback)

	_ = intrinsics.wasm_memory_grow(0, main_memory_size+temp_memory_size)

	//on wasm we're using an arena allocator so we don't have to allocate pages mid-program
	//(this invalidates pointers in existing pages -_-)
	arena_buf = make([]byte, main_memory_size, js.page_allocator())
	mem.arena_init(&arena, arena_buf)
	alloc = mem.arena_allocator(&arena)

	//scratch allocator itself doesn't allocate & reuses memory, so it'll use whatever pages it needs
	mem.scratch_allocator_init(&scratch, temp_memory_size, js.page_allocator())
	temp_alloc = mem.scratch_allocator(&scratch)

	context.allocator = alloc
	context.temp_allocator = temp_alloc
	when common.Renderer == "gl" {
		fmt.println("Initializing Web Context...")
		gl.SetCurrentContextById("canvas")
		resize_canvas(Screen_Width, Screen_Height)
		opengl.init()
		opengl.resize_viewport(i32(Screen_Width), i32(Screen_Height))
	}
}

run :: proc(step: proc(f64)) {
	//the step is actually handled in the runtime.js
	//so whatever
	//for {}
}

import "core:strings"
window_title :: proc(title: string) {
	set_window_title(title)
}

get_memory :: proc() -> (mem.Allocator, mem.Allocator) {
	return alloc, temp_alloc
}
