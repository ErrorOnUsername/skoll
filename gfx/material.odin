package gfx

import glm "core:math/linalg/glsl"

MAX_TEXTURES_PER_CHANNEL :: 3

Material :: struct {
	shader:    Shader,
	diffuse:   [MAX_TEXTURES_PER_CHANNEL]int,
	ambient:   glm.vec3,
	specular:  glm.vec3,
	shininess: f32,
}
