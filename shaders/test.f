#version 400 core

in VS_OUT {
    vec3 frag_pos;
    vec3 normal;
	vec2 uv;
} fs_in;

uniform vec3 u_camera_pos;

out vec4 out_color;

void main() {
    vec3 light_pos = vec3(1.0, 2.0, 0.0);
    vec3 light_color = vec3(1.0, 1.0, 1.0);
    vec3 obj_color = vec3(0.8);

    vec3 norm = normalize(fs_in.normal);
    vec3 light_dir = normalize(light_pos - fs_in.frag_pos);
    vec3 cam_dir = normalize(u_camera_pos - fs_in.frag_pos);
    vec3 reflect_dir = reflect(-light_dir, norm);

    float amb_strength = 0.1;
    float spec_strength = 0.5;

    float diff = max(dot(norm, light_dir), 0.0);
    vec3 diffuse = diff * light_color;
    float spec = pow(max(dot(cam_dir, reflect_dir), 0.0), 32);
    vec3 specular = spec_strength * spec * light_color;

    vec3 ambient = light_color * amb_strength;
    vec3 result = (ambient + diffuse + specular) * obj_color;

    out_color = vec4(result, 1.0);
}
