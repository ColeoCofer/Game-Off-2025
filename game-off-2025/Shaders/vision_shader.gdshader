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
uniform float wave_thickness = 100.0;

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
		}
	}

	// Combine vision and echo
	float final_alpha = min(vision_alpha, echo_alpha) * darkness_intensity;

	// Output black with calculated alpha
	COLOR = vec4(0.0, 0.0, 0.0, final_alpha);
}
