package gfx

import     "core:fmt"
import glm "core:math/linalg/glsl"

import "../core"

CameraMode :: enum {
	FreeCam,
	Arcball,
}

Camera :: struct {
	mode: CameraMode,

	view_matrix: glm.mat4,
	pv_matrix:   glm.mat4,

	position:    glm.vec3,
	look_at:     glm.vec3,
	orientation: glm.quat,

	yaw:   f32,
	pitch: f32,
	roll:  f32,

	fov_y:  f32,
	z_near: f32,
	z_far:  f32,
}

create_camera :: proc( position: glm.vec3, fov_y: f32, mode: CameraMode ) -> Camera {
	self := Camera {
		mode        = mode,
		view_matrix = glm.identity( glm.mat4 ),
		pv_matrix   = glm.identity( glm.mat4 ),
		position    = position,
		orientation = glm.quat { },
		yaw         = 0.0,
		pitch       = 0.0,
		roll        = 0.0,
		fov_y       = fov_y,
		z_near      = 0.1,
		z_far       = 1000.0,
	}

	camera_calculate_pv_matrix( &self )

	return self
}

camera_calculate_pv_matrix :: proc( self: ^Camera ) {
	aspect := cast(f32)core.g_current_window.width / cast(f32)core.g_current_window.height
	proj   := glm.mat4Perspective( glm.radians( self.fov_y ), aspect, self.z_near, self.z_far )

	euler := glm.radians( glm.vec3 { -self.pitch, self.yaw, self.roll } )
	ha_s  := glm.sin( euler * 0.5 )
	ha_c  := glm.cos( euler * 0.5 )

	self.orientation.w = ( ha_c.x * ha_c.y * ha_c.z ) + ( ha_s.x * ha_s.y * ha_s.z )
	self.orientation.x = ( ha_s.x * ha_c.y * ha_c.z ) - ( ha_c.x * ha_s.y * ha_s.z )
	self.orientation.y = ( ha_c.x * ha_s.y * ha_c.z ) + ( ha_s.x * ha_c.y * ha_s.z )
	self.orientation.z = ( ha_c.x * ha_c.y * ha_s.z ) - ( ha_s.x * ha_s.y * ha_c.z )

	transform        := glm.mat4Translate( self.position )
	self.view_matrix  = transform * glm.mat4FromQuat( self.orientation )

	self.pv_matrix = proj * self.view_matrix
}

camera_update :: proc( self: ^Camera, dt: f32 ) {
	switch self.mode {
		case .FreeCam:
			camera_update_freecam( self, dt )
		case .Arcball:
			camera_update_arcball( self, dt )
	}
}

camera_update_freecam :: proc( self: ^Camera, dt: f32 ) {
	assert( false )
}

camera_update_arcball :: proc( self: ^Camera, dt: f32 ) {
	if core.input_is_mouse_button_down( core.MouseButton.ButtonRight ) {
		fmt.println( "right is down" );
	}
}
