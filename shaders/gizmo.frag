#version 400 core

out vec4 out_color;

uniform vec3 u_color;

void main() {
    out_color = vec4(u_color, 1.0);
}