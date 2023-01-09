package main

import     "core:fmt"
import glm "core:math/linalg/glsl"

import gl "vendor:OpenGL"
import    "lib/assimp"

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
