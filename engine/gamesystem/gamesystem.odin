package gamesystem

import "core:fmt"
import "core:mem"
import "core:dynlib"

//various components of the engine will use the 'load_proc' function to conditionally decide to load
//from either internal functions or dynamically from a shared library.

Load_Dynamic_Library :: ODIN_OS!=.JS && #config(ENABLE_MODS, false)
lib : dynlib.Library = nil
lib_loaded: bool = false
when Load_Dynamic_Library {
	@(init)
	load_lib :: proc() {
		if l, ok := dynlib.load_library("gamesystem"); ok {
			lib = l
			lib_loaded = true
			fmt.println("Loaded external gamesystem library.")
		} else {
			fmt.println("Loading internal gamesystem library.")
		}
	}
}
load_proc :: proc(name: string, real_proc: $t) -> t {
	if lib_loaded {
		return cast(t)(dynlib.symbol_address(lib, name))
	} else {
		return real_proc
	}
}
