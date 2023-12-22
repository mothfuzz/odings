package common

//this is an input structure - not necessarily how it's laid out in the actual renderer.

Vertex :: struct {
	position: [3]f32,
	texcoord: [2]f32,
	color: [4]f32,
	normal: [3]f32,
	tangent: [3]f32,
}
