package main

import gl "vendor:OpenGL"

import glm "core:math/linalg/glsl"

gizmo_shader:    Shader
arrow_gizmo_geo: VertexArray

initialize_default_gizmo_data :: proc() {
    ok: bool
    gizmo_shader, ok = create_shader("shaders/gizmo.vert", "shaders/gizmo.frag")
    assert(ok, "Couldn't create gizmo shaders!")

    // Transform
    {
        vbuff := create_vertex_buffer()
        append(&vbuff.vertex_layout, VertexElement { "in_position", ShaderDataType.Float3, 0 })
        vertex_buffer_set_data(&vbuff, &arrow_verts, len(arrow_verts) * 4)

        ibuff := create_index_buffer()
        index_buffer_set_data(&ibuff, &arrow_idxs, len(arrow_idxs) * 4)

        arrow_gizmo_geo = create_vertex_array(vbuff, ibuff)
    }
}

destroy_default_gizmo_data :: proc() {
    destroy_shader(&gizmo_shader)
    destroy_vertex_array(&arrow_gizmo_geo)
}

draw_transform_gizmo :: proc(cam: ^Camera, pos: glm.vec3) {
    gl.Disable(gl.DEPTH_TEST)

    translate := glm.mat4Translate(pos)

    x_gizmo_transform := translate * glm.mat4Rotate(glm.vec3 { 0, 1, 0 }, 3.14 / 2)
    x_color           := glm.vec3 { 1.0, 0.5, 0.5 }
    y_gizmo_transform := translate * glm.mat4Rotate(glm.vec3 { 1, 0, 0 }, -3.14 / 2)
    y_color           := glm.vec3 { 0.5, 1.0, 0.5 }
    z_gizmo_transform := translate
    z_color           := glm.vec3 { 0.5, 0.5, 1.0 }

    bind(&arrow_gizmo_geo)
    bind(&arrow_gizmo_geo.index_buffer)
    shader_set_mat4(&gizmo_shader, "u_pv_matrix", &cam.pv_matrix)

    shader_set_mat4(&gizmo_shader, "u_transform_matrix", &x_gizmo_transform)
    shader_set_vec3(&gizmo_shader, "u_color", &x_color)
    gl.DrawElements(gl.TRIANGLES, cast(i32)arrow_gizmo_geo.index_buffer.idx_count, gl.UNSIGNED_INT, nil)

    shader_set_mat4(&gizmo_shader, "u_transform_matrix", &y_gizmo_transform)
    shader_set_vec3(&gizmo_shader, "u_color", &y_color)
    gl.DrawElements(gl.TRIANGLES, cast(i32)arrow_gizmo_geo.index_buffer.idx_count, gl.UNSIGNED_INT, nil)

    shader_set_mat4(&gizmo_shader, "u_transform_matrix", &z_gizmo_transform)
    shader_set_vec3(&gizmo_shader, "u_color", &z_color)
    gl.DrawElements(gl.TRIANGLES, cast(i32)arrow_gizmo_geo.index_buffer.idx_count, gl.UNSIGNED_INT, nil)

    gl.Enable(gl.DEPTH_TEST)
}

// I yoinked these from blender: https://github.com/blender/blender/blob/master/source/blender/editors/gizmo_library/geometry/geom_arrow_gizmo.c
arrow_verts := [75]f32 {
    -0.000000,  0.012320, 0.000000, -0.000000,  0.012320, 0.974306,
     0.008711,  0.008711, 0.000000,  0.008711,  0.008711, 0.974306,
     0.012320, -0.000000, 0.000000,  0.012320, -0.000000, 0.974306,
     0.008711, -0.008711, 0.000000,  0.008711, -0.008711, 0.974306,
    -0.000000, -0.012320, 0.000000, -0.000000, -0.012320, 0.974306,
    -0.008711, -0.008711, 0.000000, -0.008711, -0.008711, 0.974306,
    -0.012320,  0.000000, 0.000000, -0.012320,  0.000000, 0.974306,
    -0.008711,  0.008711, 0.000000, -0.008711,  0.008711, 0.974306,
     0.000000,  0.072555, 0.974306,  0.051304,  0.051304, 0.974306,
     0.072555, -0.000000, 0.974306,  0.051304, -0.051304, 0.974306,
    -0.000000, -0.072555, 0.974306, -0.051304, -0.051304, 0.974306,
    -0.072555,  0.000000, 0.974306, -0.051304,  0.051304, 0.974306,
     0.000000, -0.000000, 1.268098,
}

arrow_idxs := [138]u32 {
    1,  3,  2,  3,  5,  4,  5,  7,  6,  7,  9,  8,  9,  11, 10, 11, 13, 12, 5,  18, 19, 15, 1,
    0,  13, 15, 14, 6,  10, 14, 11, 21, 22, 7,  19, 20, 13, 22, 23, 3,  17, 18, 9,  20, 21, 15,
    23, 16, 1,  16, 17, 23, 22, 24, 21, 20, 24, 19, 18, 24, 17, 16, 24, 16, 23, 24, 22, 21, 24,
    20, 19, 24, 18, 17, 24, 0,  1,  2,  2,  3,  4,  4,  5,  6,  6,  7,  8,  8,  9,  10, 10, 11,
    12, 7,  5,  19, 14, 15, 0,  12, 13, 14, 14, 0,  2,  2,  4,  6,  6,  8,  10, 10, 12, 14, 14,
    2,  6,  13, 11, 22, 9,  7,  20, 15, 13, 23, 5,  3,  18, 11, 9,  21, 1,  15, 16, 3,  1,  17,
}