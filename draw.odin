package main

import     "core:fmt"
import glm "core:math/linalg/glsl"

import gl "vendor:OpenGL"

bind :: proc {
	bind_vertex_array,
	bind_vertex_buffer,
	bind_index_buffer,
	bind_shader,
}

draw_model :: proc(
	model:     ^Model,
	shader:    ^Shader,
	camera:    ^Camera,
	transform: ^glm.mat4
) {
	camera_calculate_pv_matrix(camera)

	norm_mat := glm.mat3(glm.transpose(glm.inverse(transform^)))

	shader_set_mat4(shader, "u_pv_matrix", &camera.pv_matrix)
	shader_set_mat4(shader, "u_transform_matrix", transform)
	shader_set_mat3(shader, "u_normal_matrix", &norm_mat)
	shader_set_vec3(shader, "u_camera_pos", &camera.position)

	for i := 0; i < len(model.meshes); i += 1 {
		bind(&model.meshes[i].vertex_array)
		bind(&model.meshes[i].vertex_array.index_buffer)
		gl.DrawElements(gl.TRIANGLES, cast(i32)model.meshes[i].vertex_array.index_buffer.idx_count, gl.UNSIGNED_INT, nil)
	}
}

