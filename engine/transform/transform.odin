package transform

import "core:math/linalg/glsl"

Transform :: struct {
	position: [3]f32,
	orientation: quaternion128,
	scale: [3]f32,
}

mat4 :: proc(t: ^Transform) -> matrix[4, 4]f32 {
	if t == nil {
		return {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1};
	}
	m := glsl.mat4FromQuat(glsl.quat(t.orientation))
	m[0] *= t.scale.x
	m[1] *= t.scale.y
	m[2] *= t.scale.z
	m[3].xyz = t.position
	m[3].w = 1.0
	return (matrix[4,4]f32)(m)
}

translate :: proc(t: ^Transform, v: [3]f32) {
	t.position += v
}
rotate :: proc(t: ^Transform, v: [3]f32) {
	cy := f32(1)
	sy := f32(0)
	if v.z != 0 {
		cy = glsl.cos(v.z * 0.5)
		sy = glsl.sin(v.z * 0.5)
	}
	cp := f32(1)
	sp := f32(0)
	if v.y != 0 {
		cp = glsl.cos(v.y * 0.5)
		sp = glsl.sin(v.y * 0.5)
	}
	cr := f32(1)
	sr := f32(0)
	if v.x != 0 {
		cr = glsl.cos(v.x * 0.5)
		sr = glsl.sin(v.x * 0.5)
	}

	q: quaternion128
	q.w = cr * cp * cy + sr * sp * sy
	q.x = sr * cp * cy - cr * sp * sy
	q.y = cr * sp * cy + sr * cp * sy
	q.z = cr * cp * sy - sr * sp * cy

	t.orientation = q * t.orientation
}
//rotate around global axes
rotatex :: proc(t: ^Transform, angle: f32) {
	t.orientation = quaternion(w=glsl.cos(angle * 0.5), x=glsl.sin(angle * 0.5), y=f32(0), z=f32(0)) * t.orientation
}
rotatey :: proc(t: ^Transform, angle: f32) {
	t.orientation = quaternion(w=glsl.cos(angle * 0.5), x=f32(0), y=glsl.sin(angle * 0.5), z=f32(0)) * t.orientation
}
rotatez :: proc(t: ^Transform, angle: f32) {
	t.orientation = quaternion(w=glsl.cos(angle * 0.5), x=f32(0), y=f32(0), z=glsl.sin(angle * 0.5)) * t.orientation
}
rotate_axis :: proc(t: ^Transform, axis: [3]f32, angle: f32) {
	c, s := glsl.cos(angle / 2.0), glsl.sin(angle / 2.0)
	t.orientation = quaternion(w=c, x=s*axis.x, y=s*axis.y, z=s*axis.z) * t.orientation
}
scale :: proc(t: ^Transform, v: [3]f32) {
	t.scale *= v
}
origin :: proc() -> Transform {
	return {
		{0, 0, 0},
		quaternion(w=1, x=0, y=0, z=0),
		{1, 1, 1},
	}
}
