package main

import     "core:fmt"
import glm "core:math/linalg/glsl"

WINDOW_WIDTH  :: 1280
WINDOW_HEIGHT :: 1024
WINDOW_TITLE  :: "game"

main :: proc() {
	window, window_err := create_window(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	defer destroy_window(&window)
	g_current_window = &window
	if window_err != WindowErr.None {
		fmt.println("Window creation failed with:", window_err)
		return
	}

	model, model_ok := create_model("./assets/torus.glb")
	defer destroy_model(&model)
	if !model_ok {
		fmt.eprintln("Couldn't create model!")
		return
	}

	shader, shader_ok := create_shader("./shaders/test.v", "./shaders/test.f")
	defer destroy_shader(&shader)
	if !shader_ok {
		fmt.eprintln("Coudn't create shader!")
		return
	}

	fov: f32 = 90.0
	cam := create_camera(glm.vec3 { 0, 0, 0 }, fov)

	pos := glm.vec3 { 0.0, 0.0, -4.0 }
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
		draw_model(&model, &shader, &cam, &transform)

		yaw += 0.01

		window_update(&window)
	}
}
