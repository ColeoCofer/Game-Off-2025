shader_type canvas_item;

// Adjust this value to control darkness (0.0 = black, 1.0 = original brightness)
uniform float brightness : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	// Get the original color from the texture
	vec4 color = texture(TEXTURE, UV);

	// Darken the color by multiplying RGB values
	color.rgb *= brightness;

	// Keep the alpha channel unchanged
	COLOR = color;
}
