package main

import "core:fmt"

import gl   "vendor:OpenGL"
import stbi "vendor:stb/image"

import "lib/assimp"

TextureLoadError :: enum {
	None,
	FileLoadErr,
	InvalidDataFormat,
}

TextureFormat :: enum {
	RGB,
	RGBA,
}

Texture :: struct {
	id:     u32,
	path:   cstring,
	width:  u32,
	height: u32,
	format: TextureFormat,
}

create_texture_from_path :: proc(path: cstring) -> (tex: Texture, err: TextureLoadError) {
	width:    i32
	height:   i32
	channels: i32

	stbi.set_flip_vertically_on_load(1)
	data := stbi.load(path, &width, &height, &channels, 0)
	defer stbi.image_free(data)

	if data == nil {
		err = TextureLoadError.FileLoadErr
		return
	}

	texture_format : TextureFormat
	internal_format: u32 
	data_format: u32 
	if channels == 4 {
		texture_format  = TextureFormat.RGBA
		internal_format = gl.RGBA8
		data_format     = gl.RGBA
	} else if channels == 3 {
		texture_format  = TextureFormat.RGB
		internal_format = gl.RGB8
		data_format     = gl.RGB
	} else {
		err = TextureLoadError.InvalidDataFormat
		return
	}

	id: u32;
	gl.GenTextures(1, &id)

	gl.BindTexture(gl.TEXTURE_2D, id)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	gl.TexImage2D(gl.TEXTURE_2D, 0, cast(i32)internal_format, width, height, 0, data_format, gl.UNSIGNED_BYTE, data)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	gl.BindTexture(gl.TEXTURE_2D, 0)

	tex.id     = id
	tex.path   = path
	tex.width  = cast(u32)width
	tex.height = cast(u32)height
	tex.format = texture_format

	err = TextureLoadError.None

	return
}

create_texture_from_raw_data :: proc(data_ptr: [^]byte, size: i32, texture_format: TextureFormat) -> (tex: Texture, err: TextureLoadError) {
	width:    i32
	height:   i32
	channels: i32

	switch texture_format {
		case .RGBA:
			channels = 4
		case .RGB:
			channels = 3
	}

	data := stbi.load_from_memory(data_ptr, size, &width, &height, &channels, channels)
	defer stbi.image_free(data)
	assert(data != nil)

	internal_format: u32
	data_format:     u32

	switch texture_format {
		case .RGB:
			internal_format = gl.RGB8
			data_format     = gl.RGB
		case .RGBA:
			internal_format = gl.RGBA8
			data_format     = gl.RGBA
	}

	id: u32;
	gl.GenTextures(1, &id)

	gl.BindTexture(gl.TEXTURE_2D, id)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	gl.TexImage2D(gl.TEXTURE_2D, 0, cast(i32)internal_format, width, height, 0, data_format, gl.UNSIGNED_BYTE, data)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	gl.BindTexture(gl.TEXTURE_2D, 0)

	tex.id     = id
	tex.path   = "*baked-in*"
	tex.width  = cast(u32)width
	tex.height = cast(u32)height
	tex.format = texture_format

	err = TextureLoadError.None
	return
}

destroy_texture :: proc(self: ^Texture) {
	gl.DeleteTextures(1, &self.id)
}

bind_texture :: proc(self: ^Texture, slot: u32) {
	gl.ActiveTexture(gl.TEXTURE0 + slot)
	gl.BindTexture(gl.TEXTURE_2D, self.id)
}