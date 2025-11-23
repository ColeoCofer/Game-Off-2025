shader_type canvas_item;

// Vignette intensity (0.0 = no effect, 1.0 = full red vignette)
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

// Pulse effect (0.0 to 1.0, animates over time)
uniform float pulse : hint_range(0.0, 1.0) = 0.0;

// Vignette size (how far from edges the red starts)
uniform float vignette_radius : hint_range(0.0, 1.0) = 0.4;

// How sharp the vignette edge is
uniform float vignette_softness : hint_range(0.0, 1.0) = 0.5;

// Red tint color (dark crimson for subtle danger)
uniform vec3 danger_color = vec3(0.5, 0.0, 0.0);

void fragment() {
	// Get UV coordinates (0,0 at top-left, 1,1 at bottom-right)
	vec2 uv = UV;

	// Center the coordinates (-0.5 to 0.5)
	vec2 centered_uv = uv - vec2(0.5);

	// Calculate distance from center (accounting for aspect ratio)
	float dist = length(centered_uv);

	// Create vignette effect (dark at edges, clear in center)
	float vignette = smoothstep(vignette_radius, vignette_radius + vignette_softness, dist);

	// Add pulse effect (makes vignette breathe in and out)
	float pulse_intensity = intensity * (1.0 + pulse * 0.3);

	// Apply vignette
	float alpha = vignette * pulse_intensity;

	// Output red color with calculated alpha
	COLOR = vec4(danger_color, alpha);
}
