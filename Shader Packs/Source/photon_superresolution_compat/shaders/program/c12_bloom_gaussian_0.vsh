/*
--------------------------------------------------------------------------------

  Photon Shader by SixthSurge

  program/post/bloom/gaussian0.fsh
  1D horizontal gaussian blur pass for bloom tiles

--------------------------------------------------------------------------------
*/

#include "/include/global.glsl"

#if !SR_ENABLE
#define bloom_tile_scale(i) 0.5 * exp2(-(i))
#define bloom_tile_offset(i) \
    vec2(1.0 - exp2(-(i)), float((i) & 1) * (1.0 - 0.5 * exp2(-(i))))
#endif

out vec2 uv;

void main() {
    uv = gl_MultiTexCoord0.xy;

#if SR_ENABLE
    vec2 vertex_pos = gl_Vertex.xy;
    vertex_pos *= taau_render_scale;
    gl_Position = vec4(vertex_pos * 2.0 - 1.0, 0.0, 1.0);
#else
    gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0.0, 1.0);
#endif
}
