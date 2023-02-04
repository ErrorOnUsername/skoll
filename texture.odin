package main

import gl   "vendor:OpenGL"
import stbi "vendor:stb/image"

TextureLoadError :: enum {
	None,
	FileLoadErr,
	InvalidDataFormat,
}

Texture :: struct {
	id:              u32,
	path:            cstring,
	width:           u32,
	height:          u32,
	internal_format: u32,
	data_format:     u32,
}

create_texture :: proc(path: cstring) -> (tex: Texture, err: TextureLoadError) {
	real_width:  i32
	real_height: i32
	channels:    i32

	stbi.set_flip_vertically_on_load(1)
	data := stbi.load(path, &real_width, &real_height, &channels, 0)
	defer stbi.image_free(data)

	if data == nil {
		err = TextureLoadError.FileLoadErr
		return
	}

	internal_format: u32
	data_format:     u32

	if channels == 4 {
		internal_format = gl.RGBA8
		data_format     = gl.RGBA
	} else if channels == 3 {
		internal_format = gl.RGB8
		data_format     = gl.RGB
	} else {
		err = TextureLoadError.InvalidDataFormat
		return
	}

	id: u32;
	gl.GenTextures(1, &id)

	gl.BindTexture(gl.TEXTURE_2D, id)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

	gl.TexImage2D(gl.TEXTURE_2D, 0, cast(i32)internal_format, real_width, real_height, 0, data_format, gl.UNSIGNED_BYTE, data)

	gl.BindTexture(gl.TEXTURE_2D, 0)

	tex.id              = id
	tex.path            = path
	tex.width           = cast(u32)real_width
	tex.height          = cast(u32)real_height
	tex.internal_format = internal_format
	tex.data_format     = data_format

	err = TextureLoadError.None
	return
}

destroy_texture :: proc(self: ^Texture) {
	gl.DeleteTextures(1, &self.id)
}