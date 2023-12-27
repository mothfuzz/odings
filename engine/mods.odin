package engine

import "core:dynlib"
import "core:os"
import "core:fmt"

mods_inits: [dynamic]gamestate_proc
mods_ticks: [dynamic]gamestate_proc
mods_draws: [dynamic]gamestate_proc
mods_quits: [dynamic]gamestate_proc

load_mods :: proc() {
	when ODIN_OS!=.JS && #config(ENABLE_MODS, false) {

		mods_inits = make([dynamic]gamestate_proc)
		mods_ticks = make([dynamic]gamestate_proc)
		mods_draws = make([dynamic]gamestate_proc)
		mods_quits = make([dynamic]gamestate_proc)

		mods_dir : os.Handle
		dir: []os.File_Info
		err: os.Errno
		mods_dir, err = os.open("mods")
		if err != 0 {
			return
		}
		dir, err = os.read_dir(mods_dir, 0)
		if err != 0 {
			return
		}
		for file in dir {
			if file.is_dir {
				continue
			}
			lib, ok := dynlib.load_library(file.fullpath)
			if !ok {
				fmt.println("Failed to load mod:", file.fullpath)
				continue
			}
			fmt.println("Loaded mod:", file.name)
			if f, ok := dynlib.symbol_address(lib, "init"); ok {
				fmt.println("found init function")
				f := cast(gamestate_proc)(f)
				f(Current_Scene)
				append(&mods_inits, f)
			}
			if f, ok := dynlib.symbol_address(lib, "tick"); ok {
				fmt.println("found tick function")
				f := cast(gamestate_proc)(f)
				append(&mods_ticks, f)
			}
			if f, ok := dynlib.symbol_address(lib, "draw"); ok {
				fmt.println("found draw function")
				f := cast(gamestate_proc)(f)
				append(&mods_draws, f)
			}
			if f, ok := dynlib.symbol_address(lib, "quit"); ok {
				fmt.println("found quit function")
				f := cast(gamestate_proc)(f)
				append(&mods_quits, f)
			}
		}
	}
}
