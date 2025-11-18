shader_type canvas_item;

// Cooldown ready pulse shader - adds a subtle outer glow to indicate ability is ready
uniform float pulse_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 0.3, 1.0); // Warm gold glow
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float glow_size : hint_range(0.0, 0.1) = 0.03;

void fragment() {
    vec2 uv = UV;
    vec4 original_color = texture(TEXTURE, uv);

    // Calculate pulse strength (fades in and out smoothly)
    float pulse_strength = sin(pulse_progress * 3.14159) * glow_intensity;

    // Sample surrounding pixels to create outer glow
    float glow_alpha = 0.0;
    int samples = 8;
    float radius = glow_size * pulse_strength;

    for (int i = 0; i < samples; i++) {
        float angle = float(i) * 6.28318 / float(samples); // 2*PI / samples
        vec2 offset = vec2(cos(angle), sin(angle)) * radius;
        glow_alpha += texture(TEXTURE, uv + offset).a;
    }

    glow_alpha /= float(samples);

    // Only show glow where sprite is NOT already drawn (outer glow effect)
    float glow_factor = glow_alpha * (1.0 - original_color.a) * pulse_strength;

    // Combine original sprite with glow
    vec4 final_color = original_color;

    // Add subtle brightness boost to the sprite itself
    final_color.rgb += original_color.rgb * 0.2 * pulse_strength * original_color.a;

    // Add outer glow
    final_color = mix(final_color, glow_color, glow_factor);
    final_color.a = max(original_color.a, glow_factor);

    COLOR = final_color;
}
