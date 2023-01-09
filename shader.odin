package main

import     "core:fmt"
import     "core:path/filepath"
import glm "core:math/linalg/glsl"

import gl "vendor:OpenGL"

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
