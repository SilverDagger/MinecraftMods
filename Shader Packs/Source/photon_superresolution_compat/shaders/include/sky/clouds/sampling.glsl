#if !defined INCLUDE_SKY_CLOUDS_SAMPLING
#define INCLUDE_SKY_CLOUDS_SAMPLING

// Sample filtered clouds
vec4 read_clouds_and_aurora(vec2 uv, out float apparent_distance) {
#if defined WORLD_OVERWORLD
#if SR_SHOULD_APPLY_SCALE
    vec2 texture_size = vec2(textureSize(colortex12, 0));
    ivec2 bounds_max = max(
        ivec2(texture_size * taau_render_scale - 1.0),
        ivec2(0)
    );
    ivec2 texel = clamp(
        ivec2(uv * texture_size * taau_render_scale),
        ivec2(0),
        bounds_max
    );

    // Soften clouds for new pixels
    float pixel_age = texelFetch(colortex12, texel, 0).y;
    float ld = 2.0 * dampen(max0(1.0 - 0.1 * pixel_age));

    vec2 sample_uv = clamp(
        uv * taau_render_scale,
        0.5 / texture_size,
        (vec2(bounds_max) + 0.5) / texture_size
    );

    vec4 result;
    if (any(equal(texel, bounds_max))) {
        // The cloud buffers occupy a scaled rectangle inside persistent,
        // full-size textures. Filtering the top/right source texels would read
        // stale pixels outside that rectangle; at native scale the hardware
        // texture edge hides this. Keep the edge lookup inside valid data.
        ivec2 texel_min = max(texel - 1, ivec2(0));
        float distance_00 = texelFetch(colortex12, texel_min, 0).x;
        float distance_10 = texelFetch(
            colortex12,
            ivec2(texel.x, texel_min.y),
            0
        ).x;
        float distance_01 = texelFetch(
            colortex12,
            ivec2(texel_min.x, texel.y),
            0
        ).x;
        float distance_11 = texelFetch(colortex12, texel, 0).x;

        apparent_distance = min(
            min(distance_00, distance_10),
            min(distance_01, distance_11)
        );
        result = texelFetch(colortex11, texel, 0);
    } else {
        apparent_distance = min_of(textureGather(colortex12, sample_uv, 0));
        result = textureLod(colortex11, sample_uv, ld);
    }

    if (LIGHTNING_FLASH_UNIFORM > 0.01) {
        float ambient_scattering = texelFetch(colortex12, texel, 0).z;
        result.xyz += LIGHTNING_FLASH_UNIFORM * lightning_flash_intensity *
            ambient_scattering;
    }
#else
    // Soften clouds for new pixels
    float pixel_age =
        texelFetch(colortex12, ivec2(uv * view_res * taau_render_scale), 0).y;
    float ld = 2.0 * dampen(max0(1.0 - 0.1 * pixel_age));

    apparent_distance =
        min_of(textureGather(colortex12, uv * taau_render_scale, 0));
    vec4 result = textureLod(colortex11, uv * taau_render_scale, ld);

    if (LIGHTNING_FLASH_UNIFORM > 0.01) {
        float ambient_scattering =
            texture(colortex12, uv * taau_render_scale).z;
        result.xyz += LIGHTNING_FLASH_UNIFORM * lightning_flash_intensity *
            ambient_scattering;
    }
#endif

    result.xyz *= clamp01(1.0 - blindness - darknessFactor);

    return result;
#else
    return vec4(0.0, 0.0, 0.0, 1.0);
#endif
}

#endif // INCLUDE_SKY_CLOUDS_SAMPLING
