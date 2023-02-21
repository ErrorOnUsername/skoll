package main

import     "core:fmt"
import glm "core:math/linalg/glsl"

WINDOW_WIDTH  :: 1280
WINDOW_HEIGHT :: 720
WINDOW_TITLE  :: "Sköll"

main :: proc() {
	window, window_err := create_window(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	defer destroy_window(&window)

	g_current_window = &window
	window_init_event_callbacks(&window)
	if window_err != WindowErr.None {
		fmt.println("Window creation failed with:", window_err)
		return
	}

	model, model_ok := create_model("./assets/icosphere.glb")
	defer destroy_model(&model)
	if !model_ok {
		fmt.eprintln("Couldn't create model!")
		return
	}

	initialize_default_gizmo_data()
	defer destroy_default_gizmo_data()


	fov: f32 = 90.0
	cam := create_camera(glm.vec3 { 0, 0, 0 }, fov)

	pos := glm.vec3 { -0.5, -0.5, -3.0 }
	yaw: f32 = 0.0

	for !window_should_close(&window) {
		window_clear()

		// yay :) i can still math
		translate := glm.mat4Translate(pos)
		shift     := glm.sin(2 * yaw)
		max       := glm.radians_f32(45.0)
		rotate    := glm.mat4Rotate(glm.normalize(glm.vec3 { -1, 0, -1 }), max * shift)
		spin      := glm.mat4Rotate(glm.normalize(glm.vec3 { 0, 1, 0 }), yaw)
		scale     := glm.mat4Scale(glm.vec3 { 1.0, 1.0, 1.0 })
		transform := translate * spin * scale

		draw_model(&model, &cam, &transform)

		batch_data: BatchRendererData

		batch_begin(&batch_data)

		batch_push_screenspace_quad(&batch_data, glm.vec2 { 0.1, 0.7 }, glm.vec2 { 0.2, 0.2 }, { 0.9, 0.7, 0.9 })
		batch_push_screenspace_quad(&batch_data, glm.vec2 { 0.6, 0.7 }, glm.vec2 { 0.3, 0.2 }, { 0.7, 0.9, 0.9 })

		batch_flush(&batch_data)

		yaw += 0.005

		window_update(&window)
	}
}
