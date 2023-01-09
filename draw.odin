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

draw_mesh :: proc(mesh: ^Mesh, camera: ^Camera, transform: ^glm.mat4) {
	camera_calculate_pv_matrix(camera)

	norm_mat := glm.mat3(glm.transpose(glm.inverse(transform^)))

	shader_set_mat4(&mesh.shader, "u_pv_matrix", &camera.pv_matrix)
	shader_set_mat4(&mesh.shader, "u_transform_matrix", transform)
	shader_set_mat3(&mesh.shader, "u_normal_matrix", &norm_mat)
	shader_set_vec3(&mesh.shader, "u_camera_pos", &camera.position)

	bind(&mesh.vertex_array)
	bind(&mesh.vertex_array.index_buffer)

	gl.DrawElements(gl.TRIANGLES, cast(i32)mesh.vertex_array.index_buffer.idx_count, gl.UNSIGNED_INT, nil)
}

