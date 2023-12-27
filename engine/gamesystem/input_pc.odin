//+build !js
package gamesystem

import "vendor:glfw"

key2enum :: proc "contextless" (key: i32) -> Key {
	switch key {
	case glfw.KEY_A: return .A
	case glfw.KEY_B: return .B
	case glfw.KEY_C: return .C
	case glfw.KEY_D: return .D
	case glfw.KEY_E: return .E
	case glfw.KEY_F: return .F
	case glfw.KEY_G: return .G
	case glfw.KEY_H: return .H
	case glfw.KEY_I: return .I
	case glfw.KEY_J: return .J
	case glfw.KEY_K: return .K
	case glfw.KEY_L: return .L
	case glfw.KEY_M: return .M
	case glfw.KEY_N: return .N
	case glfw.KEY_O: return .O
	case glfw.KEY_P: return .P
	case glfw.KEY_Q: return .Q
	case glfw.KEY_R: return .R
	case glfw.KEY_S: return .S
	case glfw.KEY_T: return .T
	case glfw.KEY_U: return .U
	case glfw.KEY_V: return .V
	case glfw.KEY_W: return .W
	case glfw.KEY_X: return .X
	case glfw.KEY_Y: return .Y
	case glfw.KEY_Z: return .Z
	case glfw.KEY_LEFT: return .Left
	case glfw.KEY_RIGHT: return .Right
	case glfw.KEY_UP: return .Up
	case glfw.KEY_DOWN: return .Down
	case glfw.KEY_SPACE: return .Space
	case glfw.KEY_ESCAPE: return .Escape
	}
	return nil
}

key_callback :: proc "c" (window: glfw.WindowHandle, key,  scancode, action, mods: i32) {
	/*if key == glfw.KEY_ESCAPE && action == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}*/
	keys_current_frame[key2enum(key)] = (action == glfw.PRESS || action == glfw.REPEAT)
}
