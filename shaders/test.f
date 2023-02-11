#version 400 core

struct Material {
    vec3  ambient;
    sampler2D diffuse_maps;
    vec3  specular;
    float shininess;
};

in VS_OUT {
    vec3 frag_pos;
    vec3 normal;
    vec2 uv;
} fs_in;

uniform Material u_material;
uniform vec3 u_camera_pos;

out vec4 out_color;

void main() {
    vec3 light_pos = vec3(1.0, 2.0, 0.0);
    vec3 light_color = vec3(1.0, 1.0, 1.0);

    vec3 norm = normalize(fs_in.normal);
    vec3 light_dir = normalize(light_pos - fs_in.frag_pos);
    vec3 cam_dir = normalize(u_camera_pos - fs_in.frag_pos);
    vec3 reflect_dir = reflect(-light_dir, norm);

    float diff = max(dot(norm, light_dir), 0.0);
    vec3 diffuse = (diff * texture(u_material.diffuse_maps, fs_in.uv).rgb) * light_color;
    float spec = pow(max(dot(cam_dir, reflect_dir), 0.001), u_material.shininess);
    vec3 specular = (u_material.specular * spec) * light_color;

    vec3 ambient = light_color * u_material.ambient;
    vec3 result = ambient + diffuse + specular;

    out_color = vec4(fs_in.normal, 1.0);
}
