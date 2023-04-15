package gfx

import gl "vendor:OpenGL"

Framebuffer :: struct {
	id:                   u32,
	width:                u32,
	height:               u32,
	sample_count:         u32,
	attachments:          [dynamic]FramebufferTextureFormat,
	color_attachment_ids: [dynamic]u32,
	depth_attachment_id:  u32,
}

FramebufferTextureFormat :: enum( u32 ) {
	None = 0,
	RGBA8,
	RedInteger,
	Depth24Stencil8,
	Depth = Depth24Stencil8,
}

create_framebuffer :: proc(
	self:         ^Framebuffer,
	width:        u32,
	height:       u32,
	sample_count: u32,
	attachments:  [dynamic]FramebufferTextureFormat,
) {
	self.width        = width
	self.height       = height
	self.sample_count = sample_count
	self.attachments  = attachments

	invalidate_framebuffer( self )
}

invalidate_framebuffer :: proc( self: ^Framebuffer ) {
	if self.id != 0 {
		gl.DeleteFramebuffers( 1, &self.id )
		gl.DeleteTextures( cast(i32)len( self.color_attachment_ids ), &self.color_attachment_ids[0] )
		gl.DeleteTextures( 1, &self.depth_attachment_id )

		delete( self.color_attachment_ids )
		self.depth_attachment_id = 0
	}

	gl.GenFramebuffers( 1, &self.id )
	gl.BindFramebuffer( gl.FRAMEBUFFER, self.id )

	is_multisample := self.sample_count > 1

	if len( self.attachments ) > 0 {
		self.color_attachment_ids = make( [dynamic]u32, len(self.attachments) - 1 )
		gl.GenTextures( cast(i32)len( self.color_attachment_ids ), &self.color_attachment_ids[0] )

		framebuffer_configure_attachments( self )

		gl.BindTexture( attachment_texture_type( is_multisample ), 0 )
	}

	if len( self.color_attachment_ids ) > 1 {
		assert( len( self.color_attachment_ids ) <= 4 )
		buffers := [?]u32 {
			gl.COLOR_ATTACHMENT0,
			gl.COLOR_ATTACHMENT1,
			gl.COLOR_ATTACHMENT2,
			gl.COLOR_ATTACHMENT3,
		}

		gl.DrawBuffers( cast(i32)len( self.color_attachment_ids ), cast([^]u32)&buffers )
	} else {
		gl.DrawBuffer( gl.NONE )
	}

	assert( gl.CheckFramebufferStatus( gl.FRAMEBUFFER ) == gl.FRAMEBUFFER_COMPLETE, "Framebuffer is incomplete" )
	gl.BindFramebuffer( gl.FRAMEBUFFER, 0 )
}

framebuffer_resize :: proc( self: ^Framebuffer, width: u32, height: u32 ) {
	assert( width != 0 || height != 0 )

	self.width = width
	self.height = height

	invalidate_framebuffer( self )
}

is_color_attachment :: proc( fmt: FramebufferTextureFormat ) -> bool {
	#partial switch fmt {
		case .RGBA8:      fallthrough
		case .RedInteger: return true
	}

	return false
}

attachment_texture_type :: proc( is_multisample: bool ) -> u32 {
	if is_multisample do return gl.TEXTURE_2D_MULTISAMPLE
	else do return gl.TEXTURE_2D
}

configure_color_texture :: proc( id: u32, index: u32, width: u32, height: u32, sample_count: u32 ) {
	if sample_count > 1 {
		gl.TexImage2DMultisample( gl.TEXTURE_2D_MULTISAMPLE, cast(i32)sample_count, gl.RGBA8, cast(i32)width, cast(i32)height, false )
	} else {
		gl.TexImage2D( gl.TEXTURE_2D, 0, gl.RGBA8, cast(i32)width, cast(i32)height, 0, gl.RGBA, gl.UNSIGNED_BYTE, nil )

		gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR )
		gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR )
		gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE )
		gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE )
		gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE )
	}

	gl.FramebufferTexture2D( gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0 + index, attachment_texture_type( sample_count > 1 ), id, 0 )
}

configure_depth_texture :: proc( id: u32, width: u32, height: u32, sample_count: u32 ) {
	if sample_count > 1 {
		gl.TexImage2DMultisample( gl.TEXTURE_2D_MULTISAMPLE, cast(i32)sample_count, gl.DEPTH24_STENCIL8, cast(i32)width, cast(i32)height, false )
	} else {
		gl.TexStorage2D( gl.TEXTURE_2D, 1, gl.DEPTH24_STENCIL8, cast(i32)width, cast(i32)height )

		gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR )
		gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR )
		gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE )
		gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE )
		gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE )
	}

	gl.FramebufferTexture2D( gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, attachment_texture_type( sample_count > 1 ), id, 0 )
}

framebuffer_configure_attachments :: proc( self: ^Framebuffer ) {
	is_multisample := self.sample_count > 1

	color_idx: u32 = 0

	for attachment in self.attachments {
		assert( !is_color_attachment( attachment ) && self.depth_attachment_id != 0, "Cannot have multiple depth textures!" )

		if is_color_attachment( attachment ) {
			gl.BindTexture( attachment_texture_type( is_multisample ), self.color_attachment_ids[color_idx] )
			configure_color_texture( self.color_attachment_ids[color_idx], color_idx, self.width, self.height, self.sample_count )

			color_idx += 1
		} else {
			gl.GenTextures( 1, &self.depth_attachment_id )
			gl.BindTexture( attachment_texture_type( self.sample_count > 1 ), self.depth_attachment_id )

			configure_depth_texture( self.depth_attachment_id, self.width, self.height, self.sample_count )
		}
	}
}
