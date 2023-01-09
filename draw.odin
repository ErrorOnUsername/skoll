package main

import     "core:fmt"
import     "core:path/filepath"
import glm "core:math/linalg/glsl"

import gl "vendor:OpenGL"
import    "lib/assimp"

Shader :: struct {
	id:   u32,
	name: string,
}

create_shader :: proc(vert_filepath: string, frag_filepath: string) -> (shader: Shader, ok: bool) {
	id, load_ok := gl.load_shaders(vert_filepath, frag_filepath)
	if !load_ok {
		gl_msg, comp_ty := gl.get_last_error_message()
		fmt.eprintf("[%s]\n%s\n", comp_ty, gl_msg)
		ok = false
		return
	}

	shader.id = id
	shader.name = filepath.short_stem(vert_filepath)
	ok = true
	return
}

destroy_shader :: proc(self: ^Shader) {
	gl.DeleteProgram(self.id)
}

bind_shader :: proc(self: ^Shader) {
	gl.UseProgram(self.id)
}

shader_set_mat4 :: proc(self: ^Shader, name: cstring, val: ^glm.mat4) -> bool {
	bind(self)

	loc := gl.GetUniformLocation(self.id, name)
	if loc < 0 {
		fmt.eprintln("Could not find uniform:", name, "in shader:", self.name)
		return false
	}

	gl.UniformMatrix4fv(loc, 1, false, cast([^]f32)val)
	return true
}

shader_set_mat3 :: proc(self: ^Shader, name: cstring, val: ^glm.mat3) -> bool {
	bind(self)

	loc := gl.GetUniformLocation(self.id, name)
	if loc < 0 {
		fmt.eprintln("Could not find uniform:", name, "in shader:", self.name)
		return false
	}

	gl.UniformMatrix3fv(loc, 1, false, cast([^]f32)val)
	return true
}

shader_set_vec3 :: proc(self: ^Shader, name: cstring, val: ^glm.vec3) -> bool {
	bind(self)

	loc := gl.GetUniformLocation(self.id, name)
	if loc < 0 {
		fmt.eprintln("Could not find uniform:", name, "in shader:", self.name)
		return false
	}

	gl.Uniform3f(loc, val.x, val.y, val.z)
	return true
}

bind :: proc {
	bind_vertex_array,
	bind_vertex_buffer,
	bind_index_buffer,
	bind_shader,
}

Camera :: struct {
	pv_matrix: glm.mat4,

	position:    glm.vec3,
	orientation: glm.quat,

	yaw:   f32,
	pitch: f32,
	roll:  f32,

	fov_y:  f32,
	z_near: f32,
	z_far:  f32,
}

create_camera :: proc(position: glm.vec3, fov_y: f32) -> Camera {
	self := Camera {
		pv_matrix   = glm.identity(glm.mat4),
		position    = position,
		orientation = glm.quat { },
		yaw         = 0.0,
		pitch       = 0.0,
		roll        = 0.0,
		fov_y       = fov_y,
		z_near      = 0.1,
		z_far       = 1000.0,
	}

	camera_calculate_pv_matrix(&self)

	return self
}

camera_calculate_pv_matrix :: proc(self: ^Camera) {
	aspect := cast(f32)g_current_window.width / cast(f32)g_current_window.height
	proj   := glm.mat4Perspective(glm.radians(self.fov_y), aspect, self.z_near, self.z_far)

	euler := glm.radians(glm.vec3 { -self.pitch, self.yaw, self.roll })
	ha_s  := glm.sin(euler * 0.5)
	ha_c  := glm.cos(euler * 0.5)

	self.orientation.w = (ha_c.x * ha_c.y * ha_c.z) + (ha_s.x * ha_s.y * ha_s.z)
	self.orientation.x = (ha_s.x * ha_c.y * ha_c.z) - (ha_c.x * ha_s.y * ha_s.z)
	self.orientation.y = (ha_c.x * ha_s.y * ha_c.z) + (ha_s.x * ha_c.y * ha_s.z)
	self.orientation.z = (ha_c.x * ha_c.y * ha_s.z) - (ha_s.x * ha_s.y * ha_c.z)

	transform := glm.mat4Translate(self.position)
	view      := transform * glm.mat4FromQuat(self.orientation)

	self.pv_matrix = proj * view
}

MeshErr :: enum(u8) {
	None,
	ImportFail,
	ShaderFailed,
}

Mesh :: struct {
	model_filepath: cstring,
	vertex_array:   VertexArray,
	shader:         Shader,
}


create_mesh :: proc(model_path: cstring, vert_path: string, frag_path: string) -> (Mesh, MeshErr) {
	verts := make([dynamic]f32)
	idxs  := make([dynamic]u32)
	defer delete(verts)
	defer delete(idxs)

	{
		assimp_import_flags := cast(u32)assimp.PostProcessFlags.Triangulate | cast(u32)assimp.PostProcessFlags.GenSmoothNormals | cast(u32)assimp.PostProcessFlags.FlipUVs
		scene := assimp.ImportFile(model_path, assimp_import_flags)
		defer assimp.ReleaseImport(scene)

		if scene == nil {
			fmt.eprintln("[Assimp Err]", assimp.GetErrorString())
			return Mesh { }, MeshErr.ImportFail
		}

		transform := assimp.Mat4 { }
		assimp.IdentityMatrix4(&transform)
		traverse_assimp_scene(scene, scene.root_node, &transform, &verts, &idxs)
	}

	vbuff := create_vertex_buffer()
	append(&vbuff.vertex_layout, VertexElement { "in_position", ShaderDataType.Float3, 0 })
	append(&vbuff.vertex_layout, VertexElement { "in_normal", ShaderDataType.Float3, 0 })
	append(&vbuff.vertex_layout, VertexElement { "in_uv", ShaderDataType.Float2, 0 })
	ibuff := create_index_buffer()

	vertex_buffer_set_data(&vbuff, &verts[0], len(verts) * size_of(type_of(verts[0])))
	index_buffer_set_data(&ibuff, &idxs[0], len(idxs) * size_of(type_of(idxs[0])))

	varr := create_vertex_array(vbuff, ibuff)

	shader, ok := create_shader(vert_path, frag_path)
	if !ok {
		fmt.println("Couldn't create shaders")
		return Mesh { }, MeshErr.ShaderFailed
	}

	return Mesh { model_path, varr, shader }, MeshErr.None
}

destroy_mesh :: proc(self: ^Mesh) {
	destroy_vertex_array(&self.vertex_array)
	destroy_shader(&self.shader)
}

draw_mesh :: proc(mesh: ^Mesh, camera: ^Camera, transform: ^glm.mat4) {
	camera_calculate_pv_matrix(camera)

	norm_mat := glm.mat3(glm.transpose(glm.inverse(transform^)))

	shader_set_mat4(&mesh.shader, "u_pv_matrix", &camera.pv_matrix)
	shader_set_mat4(&mesh.shader, "u_transform_matrix", transform)
	shader_set_mat3(&mesh.shader, "u_normal_matrix", &norm_mat)
	shader_set_vec3(&mesh.shader, "u_camera_pos", &camera.position)

	bind(&mesh.vertex_array)
	bind(&mesh.vertex_array.vertex_buffer)
	bind(&mesh.vertex_array.index_buffer)

	gl.DrawElements(gl.TRIANGLES, cast(i32)mesh.vertex_array.index_buffer.idx_count, gl.UNSIGNED_INT, nil)
}

traverse_assimp_scene :: proc(
	scene:            ^assimp.Scene,
	node:             ^assimp.Node,
	parent_transform: ^assimp.Mat4,
	verts:            ^[dynamic]f32,
	idxs:             ^[dynamic]u32,
) {
	transform := parent_transform^
	assimp.MultiplyMatrix4(&transform, &node.transform)

	for i: u32 = 0; i < node.num_meshes; i += 1 {
		read_mesh_data(scene.meshes[node.meshes[i]], &transform, verts, idxs)
	}

	for i: u32 = 0; i < node.num_children; i += 1 {
		traverse_assimp_scene(scene, node.children[i], &transform, verts, idxs)
	}
}

read_mesh_data :: proc(
	mesh:      ^assimp.Mesh,
	transform: ^assimp.Mat4,
	verts:     ^[dynamic]f32,
	idxs:      ^[dynamic]u32,
) {
	last_vert_count: u32 = cast(u32)len(verts) / 6
	for i: u32 = 0; i < mesh.num_vertices; i += 1 {
		v := mesh.vertices[i]
		n := mesh.normals[i]
		// This will most definite mess up with multi-mesh models.
		// TODO: Fix this
		uv := mesh.texture_coords[0][i]
		assimp.TransformVecByMatrix4(&v, transform)
		assimp.TransformVecByMatrix4(&n, transform)

		append(verts, v.x)
		append(verts, v.y)
		append(verts, v.z)
		append(verts, n.x)
		append(verts, n.y)
		append(verts, n.z)
		append(verts, uv.x)
		append(verts, uv.y)
	}

	for i: u32 = 0; i < mesh.num_faces; i += 1 {
		face := mesh.faces[i]
		for j: u32 = 0; j < face.num_indices; j += 1 {
			append(idxs, last_vert_count + face.indices[j])
		}
	}
}
