package collision
import "../transform"

capsule_extents :: proc(c: ^Capsule) -> (e: Extents) {
	a, b, r := c.a, c.b, c.radius
	e.mini.x = min(a.x-r, b.x-r, a.x+r, b.x+r)
	e.mini.y = min(a.y-r, b.y-r, a.y+r, b.y+r)
	e.mini.z = min(a.z-r, b.z-r, a.z+r, b.z+r)
	e.maxi.x = max(a.x-r, b.x-r, a.x+r, b.x+r)
	e.maxi.y = max(a.y-r, b.y-r, a.y+r, b.y+r)
	e.maxi.z = max(a.z-r, b.z-r, a.z+r, b.z+r)
	return
}

transform_capsule :: proc(c: ^Capsule, t: ^transform.Transform) -> (cc: Capsule) {
	m4 := transform.mat4(t)
	cc.a = (m4 * mat4point(c.a)).xyz
	cc.b = (m4 * mat4point(c.b)).xyz
	cc.radius = c.radius
	return
}
