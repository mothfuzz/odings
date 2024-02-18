package opengl

import "../common"
when common.Renderer != "gl" {
	//+ignore
}

import "core:fmt"

directional_shadow_framebuffers: [dynamic]Framebuffer = {}
directional_shadow_texture: [2]Texture //color, depth

create_directional_shadow :: proc() {
	//create framebuffer
	append(&directional_shadow_framebuffers, 0)
	n := len(directional_shadow_framebuffers)
	i := n - 1
	fmt.println("attempting to create directional shadow map at index", i)
	//create framebuffer
	when ODIN_OS == .JS {
		directional_shadow_framebuffers[i] = gl.CreateFramebuffer()
	} else {
		gl.GenFramebuffers(1, &directional_shadow_framebuffers[i])
	}
	//create texture, allocate storage, also dammit bill
	when ODIN_OS == .JS {
		gl.BindTexture(gl.TEXTURE_2D_ARRAY, directional_shadow_texture[0])
		gl.TexImage3D(gl.TEXTURE_2D_ARRAY, 0, gl.RGBA,
					  common.Directional_Shadow_Resolution, common.Directional_Shadow_Resolution, i32(n),
					  0, gl.RGBA, gl.UNSIGNED_BYTE, 0, nil)
		gl.BindTexture(gl.TEXTURE_2D_ARRAY, directional_shadow_texture[1])
		gl.TexImage3D(gl.TEXTURE_2D_ARRAY, 0, gl.DEPTH_COMPONENT32F,
					  common.Directional_Shadow_Resolution, common.Directional_Shadow_Resolution, i32(n),
					  0, gl.DEPTH_COMPONENT, gl.FLOAT, 0, nil)
		gl.TexParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_MIN_FILTER, i32(gl.NEAREST));
		gl.TexParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_MAG_FILTER, i32(gl.NEAREST));
		gl.TexParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_COMPARE_MODE,  i32(gl.COMPARE_REF_TO_TEXTURE));
		gl.TexParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_COMPARE_FUNC, i32(gl.LEQUAL));
	} else {
		gl.BindTexture(gl.TEXTURE_2D_ARRAY, directional_shadow_texture[0])
		gl.TexImage3D(gl.TEXTURE_2D_ARRAY, 0, gl.RGBA,
					  common.Directional_Shadow_Resolution, common.Directional_Shadow_Resolution, i32(n),
					  0, gl.RGBA, gl.UNSIGNED_BYTE, nil)
		gl.BindTexture(gl.TEXTURE_2D_ARRAY, directional_shadow_texture[1])
		gl.TexImage3D(gl.TEXTURE_2D_ARRAY, 0, gl.DEPTH_COMPONENT32F,
					  common.Directional_Shadow_Resolution, common.Directional_Shadow_Resolution, i32(n),
					  0, gl.DEPTH_COMPONENT, gl.FLOAT, nil)
		gl.TexParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
		gl.TexParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
		gl.TexParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_COMPARE_MODE, gl.COMPARE_REF_TO_TEXTURE);
		gl.TexParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_COMPARE_FUNC, gl.LEQUAL);
	}
	//attach texture to framebuffer for rendering
	gl.BindFramebuffer(gl.FRAMEBUFFER, directional_shadow_framebuffers[i])
	gl.FramebufferTextureLayer(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, directional_shadow_texture[0], 0, i32(i))
	gl.FramebufferTextureLayer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, directional_shadow_texture[1], 0, i32(i))
	when ODIN_OS != .JS {
		if gl.CheckFramebufferStatus(gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE {
			fmt.println("now contains this many directional shadow maps:", n)
		} else {
			fmt.println("directional shadow map incomplete:", i)
		}
	}

	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
}

import "core:math/linalg/glsl"

draw_directional_shadows :: proc(shader_material: Material_Uniforms) {
	res := common.Directional_Shadow_Resolution
	size := 2048
	gl.Viewport(0, 0, res, res)
	//gl.UseProgram(shadow_program)
	projection: matrix[4,4]f32 = glsl.mat4Ortho3d(f32(-size), f32(size), f32(-size), f32(size), 0.1, 1024+4096)
	camera_position: [3]f32 = glsl.inverse(view)[3].xyz

	//set blend mode to multiply
	//it's fine to have depth test cancellation, if there's an opaque object before or after then the shadow will be opaque naturally
	//gl.BlendFunc(gl.DST_COLOR, gl.ZERO)
	gl.Enable(gl.DEPTH_TEST)
	gl.DepthMask(true)
	gl.DepthFunc(gl.LESS)
	//gl.CullFace(gl.FRONT)

	ldiff := len(directional_lights_shadowed) - len(directional_shadow_framebuffers); //or *2 or *3 depeding on num cascades
	for i in 0..<ldiff {
		create_directional_shadow()
	}

	for i in 0..<len(directional_lights_shadowed) {
		dl := directional_lights_shadowed[i]
		gl.BindFramebuffer(gl.FRAMEBUFFER, directional_shadow_framebuffers[i])

		gl.ClearColor(0.0, 0.0, 0.0, 0.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		eye := camera_position - f32(size)*([3]f32)(glsl.normalize(glsl.vec3(dl.posdir.xyz)))
		center := camera_position
		view: matrix[4,4]f32 = glsl.mat4LookAt(glsl.vec3(eye), glsl.vec3(center), {0, -1, 0})

		directional_lights_shadowed[i].viewproj = projection * view

		prepare_instances(view, projection)
		draw_all_meshes(shader_material) //<- need to modify this to use material params associated with current program object
		//maybe use a struct for them
	}
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

	//gl.CullFace(gl.BACK)
}

point_shadow_framebuffers: [dynamic]Framebuffer = {} //x6
point_shadow_texture: [2]Texture //color, depth

//create_point_shadow
//draw_point_shadow

spot_shadow_framebuffers: [dynamic]Framebuffer = {}
spot_shadow_texture : [2]Texture //color, depth

//create_spot_shadow
//draw_spot_shadow
