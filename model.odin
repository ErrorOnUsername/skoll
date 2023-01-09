package main

import     "core:fmt"
import glm "core:math/linalg/glsl"

import gl "vendor:OpenGL"
import    "lib/assimp"

Model :: struct {
	filepath: cstring,
	meshes:   [dynamic]Mesh,
}

create_model :: proc(model_path: cstring) -> (model: Model, ok: bool) {
	assimp_import_flags :=
		cast(u32)assimp.PostProcessFlags.Triangulate      |
		cast(u32)assimp.PostProcessFlags.GenSmoothNormals |
		cast(u32)assimp.PostProcessFlags.FlipUVs

	scene := assimp.ImportFile(model_path, assimp_import_flags)
	defer assimp.ReleaseImport(scene)

	if scene == nil {
		fmt.eprintln("[Assimp Err]", assimp.GetErrorString())
		ok = false
		return
	}

	meshes := make([dynamic]Mesh)

	transform := assimp.Mat4 { }
	assimp.IdentityMatrix4(&transform)
	traverse_assimp_scene(scene, scene.root_node, &transform, &meshes)

	model.filepath = model_path
	model.meshes   = meshes
	ok             = true
	return
}

destroy_model :: proc(self: ^Model) {
	for i := 0; i > len(self.meshes); i += 1 {
		destroy_mesh(&self.meshes[i])
	}
}
Mesh :: struct {
	vertex_array: VertexArray,
}

create_mesh :: proc(verts: ^[dynamic]f32, idxs: ^[dynamic]u32) -> Mesh {
	vbuff := create_vertex_buffer()
	append(&vbuff.vertex_layout, VertexElement { "in_position", ShaderDataType.Float3, 0 })
	append(&vbuff.vertex_layout, VertexElement { "in_normal", ShaderDataType.Float3, 0 })
	append(&vbuff.vertex_layout, VertexElement { "in_uv", ShaderDataType.Float2, 0 })
	ibuff := create_index_buffer()

	vertex_buffer_set_data(&vbuff, &verts[0], len(verts) * size_of(type_of(verts[0])))
	index_buffer_set_data(&ibuff, &idxs[0], len(idxs) * size_of(type_of(idxs[0])))

	varr := create_vertex_array(vbuff, ibuff)

	return Mesh { varr }
}

destroy_mesh :: proc(self: ^Mesh) {
	destroy_vertex_array(&self.vertex_array)
}

traverse_assimp_scene :: proc(
	scene:            ^assimp.Scene,
	node:             ^assimp.Node,
	parent_transform: ^assimp.Mat4,
	meshes:           ^[dynamic]Mesh,
) {
	transform := parent_transform^
	assimp.MultiplyMatrix4(&transform, &node.transform)

	for i: u32 = 0; i < node.num_meshes; i += 1 {
		append(meshes, read_mesh_data(scene.meshes[node.meshes[i]], &transform))
	}

	for i: u32 = 0; i < node.num_children; i += 1 {
		traverse_assimp_scene(scene, node.children[i], &transform, meshes)
	}
}

read_mesh_data :: proc(
	mesh:      ^assimp.Mesh,
	transform: ^assimp.Mat4,
) -> Mesh {
	verts := make([dynamic]f32)
	idxs := make([dynamic]u32)

	for i: u32 = 0; i < mesh.num_vertices; i += 1 {
		v := mesh.vertices[i]
		n := mesh.normals[i]
		assimp.TransformVecByMatrix4(&v, transform)
		assimp.TransformVecByMatrix4(&n, transform)

		append(&verts, v.x)
		append(&verts, v.y)
		append(&verts, v.z)
		append(&verts, n.x)
		append(&verts, n.y)
		append(&verts, n.z)

		if mesh.texture_coords[0] != nil {
			uv := mesh.texture_coords[0][i]
			append(&verts, uv.x)
			append(&verts, uv.y)
		} else {
			append(&verts, 0.0)
			append(&verts, 0.0)
		}
	}

	for i: u32 = 0; i < mesh.num_faces; i += 1 {
		face := mesh.faces[i]
		for j: u32 = 0; j < face.num_indices; j += 1 {
			append(&idxs, face.indices[j])
		}
	}

	return create_mesh(&verts, &idxs)
}
