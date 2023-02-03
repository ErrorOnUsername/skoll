package main

import glm "core:math/linalg/glsl"

Material :: struct {
	shader:    Shader,
	diffuse:   glm.vec3,
	ambient:   glm.vec3,
	specular:  glm.vec3,
	shininess: f32,
}
