#version 400 core

layout(location = 0) in vec3 in_position;
layout(location = 1) in vec3 in_normal;
layout(location = 2) in vec2 in_uv;

uniform mat4 u_pv_matrix;
uniform mat4 u_transform_matrix;
uniform mat4 u_normal_matrix;

out VS_OUT {
	vec3 frag_pos;
	vec3 normal;
	vec2 uv;
} vs_out;

void main() {
	vs_out.frag_pos = vec3(u_transform_matrix * vec4(in_position, 1.0));
	vs_out.normal = mat3(u_normal_matrix) * in_normal;
	vs_out.uv = in_uv;

	gl_Position = u_pv_matrix * u_transform_matrix * vec4(in_position, 1.0);
}
