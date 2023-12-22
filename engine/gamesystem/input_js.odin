//+build js
package gamesystem

import "core:fmt"
import "vendor:wasm/js"

key2enum :: proc(key: string) -> Key {
	switch key {
	case "a": return .A
	case "b": return .B
	case "c": return .C
	case "d": return .D
	case "e": return .E
	case "f": return .F
	case "g": return .G
	case "h": return .H
	case "i": return .I
	case "j": return .J
	case "k": return .K
	case "l": return .L
	case "m": return .M
	case "n": return .N
	case "o": return .O
	case "p": return .P
	case "q": return .Q
	case "r": return .R
	case "s": return .S
	case "t": return .T
	case "u": return .U
	case "v": return .V
	case "w": return .W
	case "x": return .X
	case "y": return .Y
	case "z": return .Z
	case "ArrowLeft": return .Left
	case "ArrowRight": return .Right
	case "ArrowUp": return .Up
	case "ArrowDown": return .Down
	case " ": return .Space
	}
	return nil
}

key_down_callback :: proc(e: js.Event) {
	//fmt.println(e.key.key)
	keys_current_frame[key2enum(e.key.key)] = true
}
key_up_callback :: proc(e: js.Event) {
	keys_current_frame[key2enum(e.key.key)] = false
}
