/*
--------------------------------------------------------------------------------

  Photon Shader by SixthSurge

  program/d3_ao:
  Calculate ambient occlusion

--------------------------------------------------------------------------------
*/

#include "/include/global.glsl"

out vec2 uv;

#if SR_SHOULD_APPLY_SCALE
uniform vec2 view_res;
uniform vec2 SRScaledViewportSize;
#endif

void main() {
    uv = gl_MultiTexCoord0.xy;

#if SR_SHOULD_APPLY_SCALE
    vec2 vertex_pos = gl_Vertex.xy;
    vertex_pos *= SRScaledViewportSize / view_res;
    gl_Position = vec4(vertex_pos * 2.0 - 1.0, 0.0, 1.0);
#else
    gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0.0, 1.0);
#endif
}
