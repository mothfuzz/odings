package opengl

import "core:strings"
import "core:fmt"

when ODIN_OS == .JS {
	program_struct_field :: proc(name, member: string) -> string {
		context.allocator = context.temp_allocator
		return strings.concatenate({name, ".", member})
	}
} else {
	program_struct_field :: proc(name, member: string) -> cstring {
		context.allocator = context.temp_allocator
		return strings.clone_to_cstring(strings.concatenate({name, ".", member}))
	}
}

load_program :: proc(vs_str, fs_str: string) -> (Program, bool) {
	when ODIN_OS == .JS {
		fs_precision := "precision highp float;"
		vs_str := fmt.tprint("#version 300 es", vs_str, sep="\n")
		fs_str := fmt.tprint("#version 300 es", fs_precision, fs_str, sep="\n")
		return gl.CreateProgramFromStrings({vs_str}, {fs_str})
	} else {
		vs_str := fmt.tprint("#version 410", vs_str, sep="\n")
		fs_str := fmt.tprint("#version 410", fs_str, sep="\n")
		return gl.load_shaders_source(vs_str, fs_str)
	}
}
