/*
--------------------------------------------------------------------------------

  Photon Shader by SixthSurge

  program/c2_dof
  Calculate depth of field

--------------------------------------------------------------------------------
*/

#include "/include/global.glsl"

layout(location = 0) out vec3 scene_color;

/* RENDERTARGETS: 0 */

in vec2 uv;

// ------------
//   Uniforms
// ------------

uniform sampler2D noisetex;

uniform sampler2D colortex0;

#if SR_SHOULD_APPLY_SCALE
uniform sampler2D colortex5;
#endif

uniform sampler2D depthtex0;
#if SR_SHOULD_APPLY_SCALE
uniform sampler2D depthtex1;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform float near, far;

uniform float aspectRatio;
#if !SR_SHOULD_APPLY_SCALE
uniform float centerDepthSmooth;
#endif

#if SR_SHOULD_APPLY_SCALE
uniform float frameTime;
#endif

uniform int frameCounter;

uniform vec2 view_pixel_size;
uniform vec2 taa_offset;

#if SR_SHOULD_APPLY_SCALE
uniform ivec2 SRScaledViewportSizeI;
#endif

#include "/include/misc/lod_mod_support.glsl"
#include "/include/utility/random.glsl"
#include "/include/utility/sampling.glsl"
#include "/include/utility/space_conversion.glsl"

void main() {
    ivec2 texel = ivec2(gl_FragCoord.xy);

    float depth = texelFetch(depthtex0, texel, 0).x;

#ifdef LOD_MOD_ACTIVE
    float depth_lod = texelFetch(lod_depth_tex, texel, 0).x;

    if (is_lod_terrain(depth, depth_lod)) {
        depth = view_to_screen_space_depth(
            gbufferProjection,
            screen_to_view_space_depth(lod_projection_matrix_inverse, depth_lod)
        );
    }
#endif

    if (depth < hand_depth) {
        scene_color = texelFetch(colortex0, texel, 0).rgb;
        return;
    };

    // Calculate vogel disk rotation
    float theta = texelFetch(noisetex, texel & 511, 0).b;
    theta = r1(frameCounter, theta);
    theta *= tau;

    // Calculate circle of confusion
#if SR_SHOULD_APPLY_SCALE
    float focus;
    float centerDepthSmooth;
    if (DOF_FOCUS < 0.0) {
        // Iris samples centerDepthSmooth at the full-size framebuffer center,
        // which lies outside the center of SR's lower-left render viewport.
        ivec2 focus_texel = clamp(
            SRScaledViewportSizeI / 2,
            ivec2(0),
            textureSize(depthtex1, 0) - 1
        );
        // Match Iris centerDepthSmooth, which is sampled before translucents.
        float current_center_depth = texelFetch(depthtex1, focus_texel, 0).x;

#ifdef LOD_MOD_ACTIVE
        float focus_depth_lod =
            texelFetch(lod_depth_tex_solid, focus_texel, 0).x;
        if (is_lod_terrain(current_center_depth, focus_depth_lod)) {
            current_center_depth = view_to_screen_space_depth(
                gbufferProjection,
                screen_to_view_space_depth(
                    lod_projection_matrix_inverse,
                    focus_depth_lod
                )
            );
        }
#endif

        float encoded_previous_center_depth =
            texelFetch(colortex5, ivec2(1, 0), 0).a;
        float previous_center_distance = -encoded_previous_center_depth;
        bool valid_history = encoded_previous_center_depth < 0.0 &&
            previous_center_distance <= 65504.0 &&
            !isnan(previous_center_distance) &&
            !isinf(previous_center_distance);
        float previous_center_depth = valid_history
            ? view_to_screen_space_depth(
                  gbufferProjection,
                  previous_center_distance
              )
            : current_center_depth;
        float fade_factor = exp2(-frameTime * 10.0) * float(valid_history);

        centerDepthSmooth = mix(
            current_center_depth,
            previous_center_depth,
            fade_factor
        );
        focus = centerDepthSmooth;
    } else {
        focus = view_to_screen_space_depth(gbufferProjection, DOF_FOCUS);
    }
#else
    float focus = DOF_FOCUS < 0.0
        ? centerDepthSmooth
        : view_to_screen_space_depth(gbufferProjection, DOF_FOCUS);
#endif
    vec2 CoC = min(abs(depth - focus), 0.1) * (DOF_INTENSITY * 0.2 / 1.37) *
        vec2(1.0, aspectRatio) * gbufferProjection[1][1];

    scene_color = vec3(0.0);

    for (int i = 0; i < DOF_SAMPLES; ++i) {
        vec2 offset = vogel_disc_sample(i, DOF_SAMPLES, theta);
        scene_color +=
            textureLod(
                colortex0,
                clamp(
                    vec2(uv + offset * CoC),
                    vec2(0.0),
                    vec2(1.0 - 2.0 * view_pixel_size * rcp(taau_render_scale))
                ) * taau_render_scale,
                0
            )
                .rgb;
    }

    scene_color *= rcp(DOF_SAMPLES);
}

#ifndef DOF
#error "This program should be disabled if Depth of Field is disabled"
#endif
