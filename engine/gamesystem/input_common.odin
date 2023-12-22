package gamesystem

Key :: enum {
	Nil,
	A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,
	Zero,One,Two,Three,Four,Five,Six,Seven,Eight,Nine,
	Left,Right,Up,Down,
	Left_Shift, Right_Shift,
	Left_Ctrl,Left_Alt,Left_Super,Right_Ctrl,Right_Alt,Right_Super,
	Escape,Return,Space,
}

keys_current_frame: [Key]bool
keys_previous_frame: [Key]bool

@(export)
gs_key_down :: proc(k: Key) -> bool {
	return keys_current_frame[k]
}

@(export)
gs_key_pressed :: proc(k: Key) -> bool {
	return keys_current_frame[k] && !keys_previous_frame[k]
}

@(export)
gs_key_up :: proc(k: Key) -> bool {
	return !keys_current_frame[k] && keys_previous_frame[k]
}

@(export)
gs_update_input :: proc() {
	keys_previous_frame = keys_current_frame
}

key_down : type_of(gs_key_down)
key_pressed : type_of(gs_key_pressed)
key_up : type_of(gs_key_up)
update_input : type_of(gs_update_input)
@(init)
load_input :: proc() {
	key_down = load_proc("gs_key_down", gs_key_down)
	key_pressed = load_proc("gs_key_pressed", gs_key_pressed)
	key_up = load_proc("gs_key_up", gs_key_up)
	update_input = load_proc("gs_update_input", gs_update_input)
}
