package main

import glm "core:math/linalg/glsl"

import "vendor:glfw"

seconds_since_start :: proc() -> f32 {
	return cast(f32)glfw.GetTime()
}

input_is_key_down :: proc(key: Key) -> bool {
	state := glfw.GetKey(g_current_window.handle, cast(i32)key)
	return state == glfw.PRESS
}

input_is_mouse_button_down :: proc(mouse_button: MouseButton) -> bool {
	state := glfw.GetMouseButton(g_current_window.handle, cast(i32)mouse_button)
	return state == glfw.PRESS
}

input_get_mouse_position :: proc() -> glm.vec2 {
	x, y := glfw.GetCursorPos(g_current_window.handle)

	return glm.vec2 { cast(f32)x, cast(f32)y }
}
