shader_type canvas_item;

// Death animation shader - fades to black, adds distortion, and shrinks
uniform float death_progress : hint_range(0.0, 1.0) = 0.0;
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.5;
uniform vec4 death_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// Simple noise function for distortion
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;

    // Apply wave distortion that increases with death progress
    float distortion = sin(uv.y * 10.0 + TIME * 3.0) * distortion_strength * death_progress * 0.1;
    uv.x += distortion;

    // Sample the texture with distorted UVs
    vec4 original_color = texture(TEXTURE, uv);

    // Fade to death color (black)
    vec4 final_color = mix(original_color, death_color, death_progress);

    // Add some chromatic aberration effect for more dramatic death
    if (death_progress > 0.3) {
        float offset = death_progress * 0.02;
        float r = texture(TEXTURE, uv + vec2(offset, 0.0)).r;
        float g = texture(TEXTURE, uv).g;
        float b = texture(TEXTURE, uv - vec2(offset, 0.0)).b;
        vec3 aberration = vec3(r, g, b);
        final_color.rgb = mix(final_color.rgb, aberration, death_progress - 0.3);
    }

    // Fade out alpha as well for complete disappearance
    final_color.a *= (1.0 - death_progress * 0.7);

    COLOR = final_color;
}
