package gfx

import     "core:fmt"
import glm "core:math/linalg/glsl"
import     "core:strconv"

import gl "vendor:OpenGL"

import "../lib/assimp"

Model :: struct {
	filepath: cstring,
	meshes:   [dynamic]Mesh,
	textures: [dynamic]Texture,
}

create_model :: proc( model_path: cstring ) -> ( model: Model, ok: bool ) {
	assimp_import_flags :=
		cast(u32)assimp.PostProcessFlags.Triangulate        |
		cast(u32)assimp.PostProcessFlags.FixInfacingNormals |
		cast(u32)assimp.PostProcessFlags.GenSmoothNormals   |
		cast(u32)assimp.PostProcessFlags.FlipUVs

	scene := assimp.ImportFile( model_path, assimp_import_flags )
	defer assimp.ReleaseImport( scene )

	if scene == nil {
		fmt.eprintln( "[Assimp Err]", assimp.GetErrorString() )
		ok = false
		return
	}

	for i: u32 = 0; i < scene.num_textures; i += 1 {
		tex := scene.textures[i]

		assert( tex.height == 0 )
		texture, texture_load_err := create_texture_from_raw_data( cast([^]u8)tex.data, cast(i32)tex.width, TextureFormat.RGBA )
		assert( texture_load_err == .None )

		append( &model.textures, texture )
	}

	meshes := make( [dynamic]Mesh )

	transform := assimp.Mat4 { }
	assimp.IdentityMatrix4( &transform )
	traverse_assimp_scene( scene, scene.root_node, &transform, &meshes )

	model.filepath = model_path
	model.meshes   = meshes
	ok             = true
	return
}

destroy_model :: proc( self: ^Model ) {
	for i := 0; i > len( self.meshes ); i += 1 {
		destroy_mesh( &self.meshes[i] )
	}
}

Mesh :: struct {
	vertex_array: VertexArray,
	material: Material,
}

create_mesh :: proc( material: Material, verts: ^[dynamic]f32, idxs: ^[dynamic]u32 ) -> Mesh {
	vbuff := create_vertex_buffer()
	append( &vbuff.vertex_layout, VertexElement { "in_position", ShaderDataType.Float3, 0 } )
	append( &vbuff.vertex_layout, VertexElement { "in_normal", ShaderDataType.Float3, 0 } )
	append( &vbuff.vertex_layout, VertexElement { "in_uv", ShaderDataType.Float2, 0 } )
	ibuff := create_index_buffer()

	vertex_buffer_set_data( &vbuff, &verts[0], len( verts ) * size_of( type_of( verts[0] ) ) )
	index_buffer_set_data( &ibuff, &idxs[0], len( idxs ) * size_of( type_of( idxs[0] ) ) )

	varr := create_vertex_array( vbuff, ibuff )

	return Mesh { varr, material }
}

destroy_mesh :: proc( self: ^Mesh ) {
	destroy_vertex_array( &self.vertex_array )
	destroy_shader( &self.material.shader )
}

traverse_assimp_scene :: proc(
	scene:            ^assimp.Scene,
	node:             ^assimp.Node,
	parent_transform: ^assimp.Mat4,
	meshes:           ^[dynamic]Mesh,
) {
	transform := parent_transform^
	assimp.MultiplyMatrix4( &transform, &node.transform )

	for i: u32 = 0; i < node.num_meshes; i += 1 {
		append( meshes, read_mesh_data( scene, scene.meshes[node.meshes[i]], &transform ) )
	}

	for i: u32 = 0; i < node.num_children; i += 1 {
		traverse_assimp_scene( scene, node.children[i], &transform, meshes )
	}
}

read_mesh_data :: proc(
	scene:     ^assimp.Scene,
	mesh:      ^assimp.Mesh,
	transform: ^assimp.Mat4,
) -> Mesh {
	verts := make( [dynamic]f32 )
	idxs := make( [dynamic]u32 )

	for i: u32 = 0; i < mesh.num_vertices; i += 1 {
		v := mesh.vertices[i]
		n := mesh.normals[i]
		assimp.TransformVecByMatrix4( &v, transform )

		rot:  assimp.Mat3
		assimp.Matrix3FromMatrix4( &rot, transform )
		assimp.TransformVecByMatrix3( &n, &rot )

		append( &verts, v.x )
		append( &verts, v.y )
		append( &verts, v.z )
		append( &verts, n.x )
		append( &verts, n.y )
		append( &verts, n.z )

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
			append( &idxs, face.indices[j] )
		}
	}

	mat := read_material_data( scene, scene.materials[mesh.material_index] )

	return create_mesh( mat, &verts, &idxs )
}

read_material_data :: proc( scene: ^assimp.Scene, assimp_material: ^assimp.Material ) -> Material {
	shininess: f32 = 1.0
	assimp.GetMaterialFloatArray(
		assimp_material,
		assimp.MATKEY_SHININESS_KEY,
		assimp.MATKEY_SHININESS_TY,
		assimp.MATKEY_SHININESS_IDX,
		&shininess,
		nil,
	)

	roughness: f32 = 1.0
	assimp.GetMaterialFloatArray(
		assimp_material,
		assimp.MATKEY_ROUGHNESS_FACTOR_KEY,
		assimp.MATKEY_ROUGHNESS_FACTOR_TY,
		assimp.MATKEY_ROUGHNESS_FACTOR_IDX,
		&roughness,
		nil,
	)

	color: assimp.Color4D
	assimp.GetMaterialColor(
		assimp_material,
		assimp.MATKEY_COLOR_BASE_KEY,
		assimp.MATKEY_COLOR_BASE_TY,
		assimp.MATKEY_COLOR_BASE_IDX,
		&color,
	)

	material := Material { }
	load_textures_from_material( &material.diffuse, scene, assimp_material, assimp.TextureType.Diffuse )

	material.ambient   = { }
	material.specular  = { }
	material.shininess = shininess

	shader, ok := create_shader( "shaders/opaque_lit.vert", "shaders/opaque_lit.frag" )
	assert( ok )

	material.shader = shader

	return material
}

load_textures_from_material :: proc( textures: ^[MAX_TEXTURES_PER_CHANNEL]int, scene: ^assimp.Scene, material: ^assimp.Material, type: assimp.TextureType ) {
	for i: u32 = 0; i < assimp.GetMaterialTextureCount( material, type ); i += 1 {
		assert( i < 3, "Can't allocate more than 3 texture per channel" )

		path: assimp.String
		assimp.GetMaterialTexture(
			material,
			type,
			i,
			&path,
		)

		if rune(path.data[0]) == '*' {
			idx, parse_ok := strconv.parse_i64_of_base( string( cast(cstring)&path.data[1] ), 10 )
			assert( parse_ok )

			textures[i] = cast(int)idx
		} else {
			assert( false )
		}
	}
}
