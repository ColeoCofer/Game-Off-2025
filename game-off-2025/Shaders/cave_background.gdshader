shader_type canvas_item;

// Cave texture for background
uniform sampler2D cave_texture : filter_linear_mipmap, repeat_enable;

// Controls how visible the texture is (lower = more subtle)
uniform float texture_opacity : hint_range(0.0, 1.0) = 0.15;

// Color tint for the cave texture (default is slightly warm/brown)
uniform vec4 texture_tint : source_color = vec4(1.0, 0.8, 0.6, 1.0);

// Scale of the texture tiling
uniform vec2 texture_scale = vec2(1.0, 1.0);

// Optional subtle movement for depth
uniform vec2 scroll_speed = vec2(0.0, 0.0);

void fragment() {
	// Calculate UV coordinates with tiling and optional scrolling
	vec2 uv = UV * texture_scale + scroll_speed * TIME;

	// Sample the cave texture
	vec4 cave_color = texture(cave_texture, uv);

	// Apply color tint to the texture
	cave_color.rgb *= texture_tint.rgb;

	// Get the current pixel color (the black tile)
	vec4 base_color = COLOR;

	// Blend the cave texture over the black background
	// Add the texture brightness to the black base (additive blend)
	// This allows texture to be visible even on pure black
	vec3 blended = base_color.rgb + (cave_color.rgb * texture_opacity);

	COLOR = vec4(blended, base_color.a);
}
