package util

import "core:fmt"

hex2rgba :: proc(hex: u32) -> (rgba: [4]f32) {
	rgba.r = f32(hex & 0xff000000 >> 0o30)
	rgba.g = f32(hex & 0x00ff0000 >> 0o20)
	rgba.b = f32(hex & 0x0000ff00 >> 0o10)
	rgba.a = f32(hex & 0x000000ff >> 0o00)
	rgba /= f32(0xff)
	fmt.println(rgba)
	return
}

hex2rgb :: proc(hex: u32) -> (rgb: [3]f32) {
	rgb.r = f32(hex & 0xff0000 >> 0o20)
	rgb.g = f32(hex & 0x00ff00 >> 0o10)
	rgb.b = f32(hex & 0x0000ff >> 0o00)
	rgb /= f32(0xff)
	fmt.println(rgb)
	return
}
