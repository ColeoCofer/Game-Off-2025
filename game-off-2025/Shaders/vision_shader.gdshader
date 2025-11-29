shader_type canvas_item;

// Player position in screen coordinates
uniform vec2 player_position = vec2(0.0, 0.0);

// Vision radius around the player
uniform float vision_radius = 75.0;

// Fade distance for vision circle (how gradually it fades to black)
uniform float vision_fade_distance = 40.0;

// Echolocation pulse positions, intensities, and radii (up to 10 simultaneous pulses)
uniform vec2 echo_positions[10];
uniform float echo_intensities[10]; // 0.0 to 1.0, fades over time
uniform float echo_radii[10]; // Current expansion radius of each pulse

// Maximum distance echolocation reveals
uniform float echo_reveal_distance = 800.0;

// Wave thickness (how thick each expanding ring is)
uniform float wave_thickness = 20.0;

// Wave brightness (how visible the wave rings are)
uniform float wave_brightness = 1.6;

// How far ahead of the reveal the leading wave appears
uniform float wave_offset = 30.0;

// Number of trailing wave rings (sound wave effect)
uniform int wave_ring_count = 5;

// Spacing between each concentric ring
uniform float wave_ring_spacing = 35.0;

// Darkness intensity (0.0 = fully visible, 1.0 = completely dark)
uniform float darkness_intensity = 0.95;

// Dithering settings
uniform float dither_scale = 1.0; // Scale of dither pattern (higher = larger pixels)
uniform bool use_dithering = true; // Toggle between dithering and smooth fade

// 4x4 Bayer dithering threshold matrix
const mat4 BAYER_MATRIX = mat4(
	vec4(1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0),
	vec4(13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0),
	vec4(4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0),
	vec4(16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0)
);

// Get Bayer threshold for current pixel
float get_bayer_threshold(vec2 pixel_pos) {
	vec2 scaled_pos = pixel_pos / dither_scale;
	int x = int(mod(scaled_pos.x, 4.0));
	int y = int(mod(scaled_pos.y, 4.0));
	return BAYER_MATRIX[x][y];
}

// Apply dithering to alpha value - returns 0.0 or 1.0
float dither_alpha(float alpha, vec2 pixel_pos) {
	float threshold = get_bayer_threshold(pixel_pos);
	return alpha > threshold ? 1.0 : 0.0;
}

void fragment() {
	// Get current pixel position in screen space
	vec2 pixel_pos = FRAGCOORD.xy;

	// Calculate distance from player
	float dist_from_player = distance(pixel_pos, player_position);

	// Player vision circle (always visible around bat)
	float vision_alpha;

	if (use_dithering) {
		// DITHERING MODE: Use Bayer dithering for pixelated edge
		float dither_zone_width = vision_fade_distance * 0.8; // Dithering covers outer portion
		float dither_start = vision_radius - dither_zone_width;

		// Dithering gradient: 0 at dither_start, 1 at vision_radius
		float dither_gradient = smoothstep(dither_start, vision_radius, dist_from_player);

		// Apply Bayer dithering - creates sharp pixel pattern
		float vision_alpha_dithered = dither_alpha(dither_gradient, pixel_pos);

		// Apply fade to dithered pixels - inner ones are more transparent
		float fade_factor = dither_gradient * dither_gradient; // Squared for smoother fade
		vision_alpha = vision_alpha_dithered * fade_factor;
	} else {
		// SMOOTH FADE MODE: Original smooth gradient fade
		float vision_visibility = smoothstep(vision_radius, vision_radius - vision_fade_distance, dist_from_player);
		vision_alpha = 1.0 - vision_visibility;
	}

	// Check echolocation reveals with expanding wave
	float echo_alpha = 1.0;
	float wave_glow = 0.0; // Accumulate wave ring brightness

	for (int i = 0; i < 10; i++) {
		if (echo_intensities[i] > 0.0) {
			float dist_from_echo = distance(pixel_pos, echo_positions[i]);

			// Only reveal areas that the wave has passed through
			// The wave expands from 0 to echo_reveal_distance
			if (dist_from_echo <= echo_radii[i]) {
				// Calculate reveal based on distance from echo center and max reveal distance
				float max_reveal_at_distance = smoothstep(echo_reveal_distance, echo_reveal_distance - 50.0, dist_from_echo);

				// Areas revealed stay lit (fade over time with intensity)
				float echo_reveal = max_reveal_at_distance * echo_intensities[i];
				echo_alpha = min(echo_alpha, 1.0 - echo_reveal);
			}

			// Create multiple concentric wave rings for sound wave effect
			// Leading wave appears at: current_radius + wave_offset
			float leading_edge = echo_radii[i] + wave_offset;

			// Generate multiple trailing rings behind the leading edge
			for (int ring = 0; ring < 5; ring++) {
				if (ring >= wave_ring_count) break;

				// Each ring trails behind the leading edge
				float ring_position = leading_edge - float(ring) * wave_ring_spacing;

				// Don't show rings that would be at negative radius
				if (ring_position < 0.0) continue;

				float distance_from_ring = abs(dist_from_echo - ring_position);

				// Only show wave if we're within the wave thickness
				if (distance_from_ring < wave_thickness) {
					// Create smooth falloff from center of wave ring
					float ring_intensity = smoothstep(wave_thickness, 0.0, distance_from_ring);

					// Each trailing ring is progressively fainter
					float ring_fade = 1.0 - (float(ring) / float(wave_ring_count)) * 0.7;
					ring_intensity *= ring_fade;

					// Fade the wave with pulse intensity
					ring_intensity *= echo_intensities[i];

					// Leading ring (ring 0) gets a brighter edge for emphasis
					if (ring == 0) {
						float edge_boost = smoothstep(wave_thickness * 0.5, 0.0, distance_from_ring);
						ring_intensity += edge_boost * 0.25 * echo_intensities[i];
					}

					// Accumulate wave brightness (in case multiple waves overlap)
					wave_glow = max(wave_glow, ring_intensity);
				}
			}
		}
	}

	// Combine vision and echo
	float final_alpha = min(vision_alpha, echo_alpha) * darkness_intensity;

	// Apply wave distortion effect
	// The wave creates a clearish distortion that moves through the darkness
	float wave_effect = wave_glow * wave_brightness;

	// Reduce the darkness alpha where the wave passes (makes it more transparent)
	final_alpha = final_alpha * (1.0 - wave_effect * 0.7);

	// Add a very subtle white tint to the wave for visibility (not blue, just a hint of light)
	vec3 base_color = vec3(0.0, 0.0, 0.0); // Black darkness
	vec3 wave_tint = vec3(0.95, 0.95, 1.0); // Very subtle cool white (barely any blue)

	// Mix in a tiny bit of tint only where the wave is
	vec3 final_color = mix(base_color, wave_tint, wave_effect * 0.3);

	// Output color with modified alpha for distortion effect
	COLOR = vec4(final_color, final_alpha);
}
