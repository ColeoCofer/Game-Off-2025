shader_type canvas_item;

uniform vec2 velocity = vec2(0.0, 0.0);
uniform float trail_length : hint_range(0.0, 1.0) = 0.3;
uniform int trail_samples : hint_range(3, 16) = 8;
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 0.4, 1.0);
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.5;

void fragment() {
	// Sample the base texture
	vec4 base_color = texture(TEXTURE, UV);

	// Calculate motion blur trail
	vec4 trail_color = vec4(0.0);
	float speed = length(velocity);

	if (speed > 1.0) {
		// Normalize velocity for direction
		vec2 motion_dir = normalize(velocity);

		// Calculate trail offset based on speed
		float trail_dist = speed * trail_length * 0.001;

		// Sample along the motion direction for motion blur
		for (int i = 0; i < trail_samples; i++) {
			float t = float(i) / float(trail_samples - 1);

			// Sample backwards along the velocity vector
			vec2 offset = -motion_dir * trail_dist * t;
			vec2 sample_uv = UV + offset;

			vec4 sample_color = texture(TEXTURE, sample_uv);

			// Weight samples based on position (stronger in front, fading behind)
			float weight = 1.0 - t * 0.7;

			trail_color += sample_color * weight;
		}

		// Average the samples
		trail_color /= float(trail_samples);

		// Blend base with trail
		base_color = mix(base_color, trail_color, 0.6);
	}

	// Add glow effect
	float luminance = dot(base_color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 glow = glow_color.rgb * luminance * glow_intensity;

	// Combine base color with glow
	COLOR = vec4(base_color.rgb + glow, base_color.a);
}
