/*
--------------------------------------------------------------------------------

  Photon Shader by SixthSurge

  program/c11_bloom_merge_buffers:
  Copy bloom tiles from read buffer to write buffer

--------------------------------------------------------------------------------
*/

#include "/include/global.glsl"

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
