package main

import     "core:fmt"
import glm "core:math/linalg/glsl"

import gl   "vendor:OpenGL"
import stbi "vendor:stb/image"

WINDOW_WIDTH  :: 1280
WINDOW_HEIGHT :: 720
WINDOW_TITLE  :: "Sköll"

TextureLoadError :: enum {
	None,
	FileLoadErr,
	InvalidDataFormat,
}

Texture :: struct {
	id: u32,
	path: cstring,
	width: u32,
	height: u32,
	internal_format: u32,
	data_format: u32,
}

create_texture :: proc(path: cstring) -> (tex: Texture, err: TextureLoadError) {
	real_width: i32
	real_height: i32
	channels: i32

	stbi.set_flip_vertically_on_load(1)
	data := stbi.load(path, &real_width, &real_height, &channels, 0)
	defer stbi.image_free(data)

	if data == nil {
		err = TextureLoadError.FileLoadErr
		return
	}

	internal_format: u32
	data_format: u32

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

main :: proc() {
	window, window_err := create_window(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	defer destroy_window(&window)

	g_current_window = &window
	window_init_event_callbacks(&window)
	if window_err != WindowErr.None {
		fmt.println("Window creation failed with:", window_err)
		return
	}

	model, model_ok := create_model("./assets/icosphere_textured.glb")
	defer destroy_model(&model)
	if !model_ok {
		fmt.eprintln("Couldn't create model!")
		return
	}

	fov: f32 = 90.0
	cam := create_camera(glm.vec3 { 0, 0, 0 }, fov)

	pos := glm.vec3 { 0.0, 0.0, -2.0 }
	yaw: f32 = 0.0

	for !window_should_close(&window) {
		window_clear()

		// yay :) i can still math
		translate := glm.mat4Translate(pos)
		shift := glm.sin(2 * yaw)
		max := glm.radians_f32(45.0)
		rotate := glm.mat4Rotate(glm.normalize(glm.vec3 { -1, 0, -1 }), max * shift)
		spin := glm.mat4Rotate(glm.normalize(glm.vec3 { 0, 1, 0 }), yaw)
		scale := glm.mat4Scale(glm.vec3 { 1.0, 1.0, 1.0 })
		transform := translate * rotate * spin * scale

		draw_model(&model, &cam, &transform)

		yaw += 0.01

		window_update(&window)
	}
}
