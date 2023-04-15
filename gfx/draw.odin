package gfx

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
	camera_calculate_pv_matrix( camera )

	norm_mat := glm.mat4( glm.transpose( glm.inverse( transform^ ) ) )

	for i := 0; i < len( model.meshes ); i += 1 {
		mesh     := &model.meshes[i]
		material := &mesh.material
		shader   := &material.shader

		shader_set_mat4( shader, "u_pv_matrix", &camera.pv_matrix )
		shader_set_mat4( shader, "u_transform_matrix", transform )
		shader_set_mat4( shader, "u_normal_matrix", &norm_mat )
		shader_set_vec3( shader, "u_camera_pos", &camera.position )

		bind_texture( &model.textures[material.diffuse[0]], 0 )

		shader_set_vec3( shader, "u_material.ambient", &material.ambient )
		shader_set_vec3( shader, "u_material.specular", &material.specular )
		shader_set_f32( shader, "u_material.shininess", material.shininess )

		bind( &mesh.vertex_array )
		bind( &mesh.vertex_array.index_buffer )
		gl.DrawElements( gl.TRIANGLES, cast(i32)mesh.vertex_array.index_buffer.idx_count, gl.UNSIGNED_INT, nil )
	}
}

BatchQuadVertex :: struct {
	position: glm.vec2,
	color:    glm.vec3,
}

MAX_BATCH_QUAD_COUNT :: 1000

BatchRendererData :: struct {
	did_begin:  bool,
	quad_verts: [MAX_BATCH_QUAD_COUNT * 4]BatchQuadVertex,
	push_idx:   uint,
}

batch_begin :: proc( batch_data: ^BatchRendererData ) {
	assert( !batch_data.did_begin )

	batch_data.did_begin = true
	batch_data.push_idx  = 0
}

batch_push_screenspace_quad :: proc( batch_data: ^BatchRendererData, pos: glm.vec2, size: glm.vec2, color: glm.vec3 ) {
	batch_data.quad_verts[batch_data.push_idx] = BatchQuadVertex { pos * 2 - 1, color }
	batch_data.push_idx += 1

	batch_data.quad_verts[batch_data.push_idx] = BatchQuadVertex { ((pos + glm.vec2 { size.x, 0.0 }) * 2 - 1), color }
	batch_data.push_idx += 1

	batch_data.quad_verts[batch_data.push_idx] = BatchQuadVertex { ((pos + size) * 2 - 1), color }
	batch_data.push_idx += 1

	batch_data.quad_verts[batch_data.push_idx] = BatchQuadVertex { ((pos + glm.vec2 { 0.0, size.y }) * 2 - 1), color }
	batch_data.push_idx += 1
}

batch_flush :: proc( batch_data: ^BatchRendererData ) {
	assert( batch_data.did_begin )
	batch_data.did_begin = false

	idxs := make( [dynamic]u32 )
	defer delete( idxs )

	for i: uint = 0; i < batch_data.push_idx; i += 4 {
		// CCW Order
		append( &idxs, u32( i + 0 ) )
		append( &idxs, u32( i + 1 ) )
		append( &idxs, u32( i + 2 ) )
		append( &idxs, u32( i + 2 ) )
		append( &idxs, u32( i + 3 ) )
		append( &idxs, u32( i + 0 ) )
	}

	vbuff := create_vertex_buffer()
	append( &vbuff.vertex_layout, VertexElement { "in_position", ShaderDataType.Float2, 0 } )
	append( &vbuff.vertex_layout, VertexElement { "in_color", ShaderDataType.Float3, 0 } )
	ibuff := create_index_buffer()

	vertex_buffer_set_data( &vbuff, &batch_data.quad_verts, cast(int)( batch_data.push_idx * size_of( BatchQuadVertex ) ) )
	index_buffer_set_data( &ibuff, &idxs[0], len( idxs ) * size_of( u32 ) )

	varr := create_vertex_array( vbuff, ibuff )
	defer destroy_vertex_array( &varr )

	shader, shader_ok := create_shader( "shaders/immediate.vert", "shaders/immediate.frag" )
	assert( shader_ok )

	bind( &shader )
	bind( &varr )
	bind( &varr.index_buffer )

	gl.Disable( gl.DEPTH_TEST )
	gl.DrawElements( gl.TRIANGLES, cast(i32)varr.index_buffer.idx_count, gl.UNSIGNED_INT, nil )
	gl.Enable( gl.DEPTH_TEST )
}

