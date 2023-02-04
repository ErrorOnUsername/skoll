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
	camera:    ^Camera,
	transform: ^glm.mat4,
) {
	camera_calculate_pv_matrix(camera)

	norm_mat := glm.mat3(glm.transpose(glm.inverse(transform^)))

	for i := 0; i < len(model.meshes); i += 1 {
		mesh := &model.meshes[i]
		material := &mesh.material
		shader := &material.shader

		shader_set_mat4(shader, "u_pv_matrix", &camera.pv_matrix)
		shader_set_mat4(shader, "u_transform_matrix", transform)
		shader_set_mat3(shader, "u_normal_matrix", &norm_mat)
		shader_set_vec3(shader, "u_camera_pos", &camera.position)

		shader_set_vec3(shader, "u_material.ambient", &material.ambient)
		shader_set_vec3(shader, "u_material.diffuse", &material.diffuse)
		shader_set_vec3(shader, "u_material.specular", &material.specular)
		shader_set_f32(shader, "u_material.shininess", material.shininess)

		bind(&mesh.vertex_array)
		bind(&mesh.vertex_array.index_buffer)
		gl.DrawElements(gl.TRIANGLES, cast(i32)mesh.vertex_array.index_buffer.idx_count, gl.UNSIGNED_INT, nil)
	}
}

