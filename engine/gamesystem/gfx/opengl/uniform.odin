package opengl

import "core:fmt"
import "core:strings"

uniform_array :: proc(uniform: string, index: int) -> i32 {
	s := fmt.tprintf(uniform, index)
	when ODIN_OS == .JS {
		c := s
	} else {
		c := strings.clone_to_cstring(s, context.temp_allocator)
	}
	return gl.GetUniformLocation(program, c)
}
