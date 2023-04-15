package core

import "core:fmt"
import "core:os"

import    "vendor:glfw"
import gl "vendor:OpenGL"

import "../core"


GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 1

g_current_window: ^Window = nil

Window :: struct {
	handle: glfw.WindowHandle,
	width:  i32,
	height: i32,
	title:  cstring,
}

WindowErr :: enum( u8 ) {
	None,
	GLFWInitFailed,
	WindowCreationFailed,
}

create_window :: proc( width: i32, height: i32, title: cstring ) -> ( Window, WindowErr ) {
	did_init := bool( glfw.Init() )
	if !did_init {
		msg, code := glfw.GetError()
		fmt.eprintln( "glfw_err:" )
		fmt.eprintf( "[%d] %s", code, msg );
		return Window { }, WindowErr.GLFWInitFailed
	}

	when os.OS == .Darwin {
		glfw.WindowHint( glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION )
		glfw.WindowHint( glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION )
		glfw.WindowHint( glfw.OPENGL_FORWARD_COMPAT, 1 )
		glfw.WindowHint( glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE )
	}

	h_wind := glfw.CreateWindow( width, height, title, nil, nil )
	if h_wind == nil {
		msg, code := glfw.GetError()
		fmt.eprintln( "glfw_err:" )
		fmt.eprintf( "[%d] %s", code, msg );
		glfw.Terminate()
		return Window { }, WindowErr.WindowCreationFailed
	}

	glfw.MakeContextCurrent( h_wind )
	gl.load_up_to( GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address )

	fmt.println( "OpenGL Info:" )
	fmt.println( "  Vendor:", gl.GetString( gl.VENDOR ) )
	fmt.println( "  Renderer:", gl.GetString( gl.RENDERER ) )
	fmt.println( "  Version:", gl.GetString( gl.VERSION ) )

	gl.Enable( gl.BLEND )
	gl.BlendFunc( gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA )
	gl.Enable( gl.DEPTH_TEST )

	wind := Window {
		h_wind,
		width,
		height,
		title,
	}

	return wind, WindowErr.None
}

destroy_window :: proc( window: ^Window ) {
	glfw.Terminate()
	glfw.DestroyWindow( window.handle )
}

window_init_event_callbacks :: proc( self: ^Window ) {
	glfw.SetWindowSizeCallback( self.handle, cast(glfw.WindowSizeProc)window_size_cb )
	glfw.SetKeyCallback( self.handle, cast(glfw.KeyProc)window_key_cb )
}

window_clear :: proc() {
	gl.ClearColor( 0.18, 0.18, 0.18, 1.0 )
	gl.Clear( gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT )
}

window_update :: proc( self: ^Window ) {
	glfw.SwapBuffers( self.handle )
	glfw.PollEvents()
}

window_should_close :: proc( self: ^Window ) -> b32 {
	return glfw.WindowShouldClose( self.handle )
}


//
// Event Callbacks
//

WindowResizeEvent :: struct {
	width:  int,
	height: int,
}

KeyboardEvent :: struct {
	pressed:  bool,
	repeated: bool,
	key:      Key,
}

EventData :: union {
	WindowResizeEvent,
	KeyboardEvent,
}

Event :: struct {
	handled: bool,
	data:    EventData,
}

window_on_event :: proc( e: ^Event ) {
	//fmt.printf( "event: %s\n", e^ );
}

window_size_cb :: proc( handle: glfw.WindowHandle, width: int, height: int ) {
	data: EventData = WindowResizeEvent {
		width,
		height,
	}
	e := Event { false, data }
	window_on_event( &e )
}

window_key_cb :: proc( handle: glfw.WindowHandle, key: int, scancode: int, action: int, mods: int ) {
	kb_e := KeyboardEvent { }
	kb_e.key = Key( key )

	switch action {
		case glfw.PRESS:
			kb_e.pressed  = true
			kb_e.repeated = false
		case glfw.RELEASE:
			kb_e.pressed  = false
			kb_e.repeated = false
		case glfw.REPEAT:
			kb_e.pressed  = true
			kb_e.repeated = true
	}

	e := Event { false, kb_e }
	window_on_event( &e )
}
