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

// Wave thickness (how thick the expanding ring is)
uniform float wave_thickness = 60.0;

// Wave brightness (how visible the wave ring is)
uniform float wave_brightness = 0.4;

// How far ahead of the reveal the wave appears
uniform float wave_offset = 40.0;

// Darkness intensity (0.0 = fully visible, 1.0 = completely dark)
uniform float darkness_intensity = 0.95;

void fragment() {
	// Get current pixel position in screen space
	vec2 pixel_pos = FRAGCOORD.xy;

	// Calculate distance from player
	float dist_from_player = distance(pixel_pos, player_position);

	// Player vision circle (always visible around bat)
	// Smoothstep creates gradual fade from (vision_radius - vision_fade_distance) to vision_radius
	float fade_start = vision_radius - vision_fade_distance;
	float vision_alpha = smoothstep(fade_start, vision_radius, dist_from_player);

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

			// Create visible wave ring ahead of the reveal edge
			// Wave appears at: current_radius + wave_offset
			float wave_position = echo_radii[i] + wave_offset;
			float distance_from_wave = abs(dist_from_echo - wave_position);

			// Only show wave if we're within the wave thickness
			if (distance_from_wave < wave_thickness) {
				// Create smooth falloff from center of wave ring
				float wave_intensity = smoothstep(wave_thickness, 0.0, distance_from_wave);

				// Fade the wave with pulse intensity
				wave_intensity *= echo_intensities[i];

				// Add a subtle pulse effect (brighter at the leading edge)
				float edge_boost = smoothstep(wave_thickness * 0.5, 0.0, distance_from_wave);
				wave_intensity += edge_boost * 0.2 * echo_intensities[i];

				// Accumulate wave brightness (in case multiple waves overlap)
				wave_glow = max(wave_glow, wave_intensity);
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
