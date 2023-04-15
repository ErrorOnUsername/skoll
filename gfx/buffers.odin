package gfx

import "core:fmt"

import gl "vendor:OpenGL"

//
// Vertex Array
//

VertexArray :: struct {
	id:            u32,
	vertex_buffer: VertexBuffer,
	index_buffer:  IndexBuffer,
}

create_vertex_array :: proc( vbuff: VertexBuffer, ibuff: IndexBuffer ) -> VertexArray {
	id: u32 = 0
	gl.GenVertexArrays( 1, &id )

	assert( len( vbuff.vertex_layout ) > 0 && ibuff.idx_count > 0, "Set up your vertex and index buffers first" )

	gl.BindVertexArray( id )
	gl.BindBuffer( gl.ARRAY_BUFFER, vbuff.id )

	elem_idx: u32 = 0
	stride: i32   = 0

	for i := 0; i < len( vbuff.vertex_layout ); i += 1 {
		vbuff.vertex_layout[i].offset = cast(u32)stride
		stride += cast(i32)shader_type_size_in_bytes( vbuff.vertex_layout[i].data_type )
	}

	for el in vbuff.vertex_layout {
		switch el.data_type {
			case .Bool: fallthrough
			case .Int:  fallthrough
			case .Int2: fallthrough
			case .Int3: fallthrough
			case .Int4:
				gl.EnableVertexAttribArray( elem_idx )
				gl.VertexAttribIPointer(
					elem_idx,
					shader_type_component_count( el.data_type ),
					shader_type_as_gl_type( el.data_type ),
					stride,
					cast(uintptr)( cast(u64)el.offset ),
				)
				elem_idx += 1

			case .Float:  fallthrough
			case .Float2: fallthrough
			case .Float3: fallthrough
			case .Float4:
				gl.EnableVertexAttribArray( elem_idx )
				gl.VertexAttribPointer(
					elem_idx,
					shader_type_component_count( el.data_type ),
					shader_type_as_gl_type( el.data_type ),
					false,
					stride,
					cast(uintptr)( cast(u64)el.offset ),
				)
				elem_idx += 1

			case .Mat3: fallthrough
			case .Mat4:
				count := shader_type_component_count( el.data_type )
				for i: i32 = 0; i < count; i += 1 {
					gl.EnableVertexAttribArray( elem_idx )
					gl.VertexAttribPointer(
						elem_idx,
						count,
						shader_type_as_gl_type( el.data_type ),
						false,
						stride,
						cast(uintptr)( cast(u64)( el.offset + cast(u32)( size_of(f32) * count * i ) ) ),
					)
					gl.VertexAttribDivisor( elem_idx, 1 )
					elem_idx += 1
				}
		}
	}

	return VertexArray {
		id,
		vbuff,
		ibuff,
	}
}

destroy_vertex_array :: proc( self: ^VertexArray ) {
	gl.DeleteVertexArrays( 1, &self.id )
	destroy_vertex_buffer( &self.vertex_buffer )
	destroy_index_buffer( &self.index_buffer )
}

bind_vertex_array :: proc( self: ^VertexArray ) {
	gl.BindVertexArray( self.id )
}

//
// Vertex && Index buffer
//

ShaderDataType :: enum( u8 ) {
	Bool,
	Int,
	Int2,
	Int3,
	Int4,
	Float,
	Float2,
	Float3,
	Float4,
	Mat3,
	Mat4,
}

shader_type_size_in_bytes :: proc( ty: ShaderDataType ) -> u32 {
	switch ty {
		case .Bool:   return 1
		case .Int:    return 4
		case .Int2:   return 4 * 2
		case .Int3:   return 4 * 3
		case .Int4:   return 4 * 4
		case .Float:  return 4
		case .Float2: return 4 * 2
		case .Float3: return 4 * 3
		case .Float4: return 4 * 4
		case .Mat3:   return 4 * 3 * 3
		case .Mat4:   return 4 * 4 * 4
		case:         return 0
	}
}

shader_type_component_count :: proc( ty: ShaderDataType ) -> i32 {
	switch ty {
		case .Bool:   return 1
		case .Int:    return 1
		case .Int2:   return 2
		case .Int3:   return 3
		case .Int4:   return 4
		case .Float:  return 1
		case .Float2: return 2
		case .Float3: return 3
		case .Float4: return 4
		case .Mat3:   return 3 // 3 vec3s
		case .Mat4:   return 4 // 4 vec4s
		case:         return 0
	}
}

shader_type_as_gl_type :: proc( ty: ShaderDataType ) -> u32 {
	switch ty {
		case .Bool:   return gl.BOOL
		case .Int:    return gl.INT
		case .Int2:   return gl.INT
		case .Int3:   return gl.INT
		case .Int4:   return gl.INT
		case .Float:  return gl.FLOAT
		case .Float2: return gl.FLOAT
		case .Float3: return gl.FLOAT
		case .Float4: return gl.FLOAT
		case .Mat3:   return gl.FLOAT
		case .Mat4:   return gl.FLOAT
		case:         return 0
	}
}

VertexElement :: struct {
	uniform_name: cstring,
	data_type:    ShaderDataType,
	offset:       u32,
}

VertexBuffer :: struct {
	id:            u32,
	vertex_layout: [dynamic]VertexElement,
}

create_vertex_buffer :: proc() -> VertexBuffer {
	id: u32 = 0
	gl.GenBuffers( 1, &id )

	return VertexBuffer {
		id,
		make( [dynamic]VertexElement ),
	}
}

destroy_vertex_buffer :: proc( self: ^VertexBuffer ) {
	gl.DeleteBuffers( 1, &self.id )
	delete( self.vertex_layout )
}

bind_vertex_buffer :: proc( self: ^VertexBuffer ) {
	gl.BindBuffer( gl.ARRAY_BUFFER, self.id )
}

vertex_buffer_layout_size :: proc( self: ^VertexBuffer ) -> u32 {
	size: u32 = 0
	for el in self.vertex_layout {
		size += shader_type_size_in_bytes( el.data_type )
	}

	return size
}

vertex_buffer_set_data :: proc( self: ^VertexBuffer, vertices: rawptr, size_in_bytes: int ) {
	layout_size := vertex_buffer_layout_size( self )
	assert( cast(u32)size_in_bytes % layout_size == 0 )

	gl.BindBuffer( gl.ARRAY_BUFFER, self.id )
	gl.BufferData( gl.ARRAY_BUFFER, size_in_bytes, vertices, gl.STATIC_DRAW )
}

IndexBuffer :: struct {
	id:        u32,
	idx_count: u32,
}

create_index_buffer :: proc() -> IndexBuffer {
	id: u32 = 0
	gl.GenBuffers( 1, &id )

	return IndexBuffer {
		id        = id,
		idx_count = 0,
	}
}

destroy_index_buffer :: proc( self: ^IndexBuffer ) {
	gl.DeleteBuffers( 1, &self.id )
}

bind_index_buffer :: proc( self: ^IndexBuffer ) {
	gl.BindBuffer( gl.ELEMENT_ARRAY_BUFFER, self.id )
}

index_buffer_set_data :: proc( self: ^IndexBuffer, indices: rawptr, size_in_bytes: int ) {
	assert( size_in_bytes % size_of(u32) == 0 )

	self.idx_count = cast(u32)size_in_bytes / size_of(u32)

	gl.BindBuffer( gl.ELEMENT_ARRAY_BUFFER, self.id )
	gl.BufferData( gl.ELEMENT_ARRAY_BUFFER, size_in_bytes, indices, gl.STATIC_DRAW )
}
