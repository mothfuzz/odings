package opengl

import "core:image"
import _ "core:image/png"
import _ "core:image/tga"

import "../common"
when common.Renderer != "gl" {
	//+ignore
}

textures : map[string]Texture

Texture_Error :: image.Error

//TODO: support procedurally loaded textures
//if data is not provided, attempts to load from disk
//load_texture_data :: proc(resource_name: string, width: u32, height: u32, channels: int, data: []byte) {}
//load_texture_file :: proc(resource_name: string, data: []byte = nil) {} //try to read file with image.load

@(export)
gs_load_texture :: proc(filename: string, data: []byte = nil) -> (texture: Texture, err: Texture_Error) {
	if t, ok := textures[filename]; ok {
		return t, nil
	}
	img : ^image.Image
	if data != nil {
		img = image.load(data, {}, context.temp_allocator) or_return
	} else {
		when ODIN_OS == .JS {
			//wasm has no filesystem so *literally* unable to read
			err = image.General_Image_Error.Unable_To_Read_File;
			return
		} else {
			img = image.load(filename, {}, context.temp_allocator) or_return
		}
	}
	when ODIN_OS == .JS {
		format: gl.Enum
	} else {
		format: i32
	}
	if img.channels == 3 {
		format = gl.RGB
	} else {
		format = gl.RGBA
	}
	id : Texture
	when ODIN_OS == .JS {
		id = gl.CreateTexture()
		gl.BindTexture(gl.TEXTURE_2D, id)
		gl.TexImage2D(gl.TEXTURE_2D, 0, format, i32(img.width), i32(img.height), 0, format, gl.UNSIGNED_BYTE, len(img.pixels.buf), raw_data(img.pixels.buf))
	} else {
		gl.GenTextures(1, &id)
		gl.BindTexture(gl.TEXTURE_2D, id)
		gl.TexImage2D(gl.TEXTURE_2D, 0, format, i32(img.width), i32(img.height), 0, u32(format), gl.UNSIGNED_BYTE, raw_data(img.pixels.buf))
	}
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, i32(gl.LINEAR_MIPMAP_LINEAR));
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, i32(gl.LINEAR));
	gl.GenerateMipmap(gl.TEXTURE_2D)

	texture = id
	textures[filename] = texture
	err = nil
	return
}
//add cubemaps and such...
