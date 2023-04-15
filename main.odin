package main

import     "core:fmt"
import glm "core:math/linalg/glsl"
import     "core:os"

import stbtt "vendor:stb/truetype"

WINDOW_WIDTH  :: 1280
WINDOW_HEIGHT :: 720
WINDOW_TITLE  :: "Sköll"

// Normal, Bold, Italics
MAX_FONT_KINDS :: 3

FontKind :: enum(uint) {
	Normal  = 0,
	Bold    = 1,
	Italics = 2,
}

UIRendererData :: struct {
	batch_renderer_data: BatchRendererData,
	font_atlases:        [MAX_FONT_KINDS]Texture,
}

ATLAS_WIDTH  :: 512
ATLAS_HEIGHT :: 512

ui_set_normal_font :: proc(data: ^UIRendererData, path: string) {
	data, read_ok := os.read_entire_file_from_filename(path)
	assert(read_ok)
}

ui_draw_text :: proc(data: ^UIRendererData, msg: string) {
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

	model, model_ok := create_model("./assets/turret.glb")
	defer destroy_model(&model)
	if !model_ok {
		fmt.eprintln("Couldn't create model!")
		return
	}

	initialize_default_gizmo_data()
	defer destroy_default_gizmo_data()


	fov: f32 = 90.0
	cam := create_camera(glm.vec3 { 0, 0, 0 }, fov, CameraMode.Arcball)

	pos := glm.vec3 { 0.0, -1.0, -3.0 }
	yaw: f32 = 0.0
	scale: f32 = 0.0254; // conversion from imperial to metric

	last_time := seconds_since_start()

	for !window_should_close(&window) {
		window_clear()

		current_time := seconds_since_start()

		delta_time := current_time - last_time
		last_time = current_time

		// yay :) i can still math
		translate := glm.mat4Translate(pos)
		shift     := glm.sin(2 * yaw)
		max       := glm.radians_f32(45.0)
		rotate    := glm.mat4Rotate(glm.normalize(glm.vec3 { -1, 0, -1 }), max * shift)
		spin      := glm.mat4Rotate(glm.normalize(glm.vec3 { 0, 1, 0 }), yaw)
		scale     := glm.mat4Scale(glm.vec3 { scale, scale, scale })
		transform := translate * spin * scale

		draw_model(&model, &cam, &transform)

		batch_data: BatchRendererData

		//batch_begin(&batch_data)

		//batch_push_screenspace_quad(&batch_data, glm.vec2 { 0.1, 0.7 }, glm.vec2 { 0.2, 0.2 }, { 0.9, 0.7, 0.9 })
		//batch_push_screenspace_quad(&batch_data, glm.vec2 { 0.6, 0.7 }, glm.vec2 { 0.3, 0.2 }, { 0.7, 0.9, 0.9 })
		draw_transform_gizmo(&cam, pos)

		//batch_flush(&batch_data)

		camera_update(&cam, delta_time)
		yaw += 0.005

		window_update(&window)
	}
}
