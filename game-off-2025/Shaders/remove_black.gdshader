shader_type canvas_item;

// Threshold for what is considered "black" (adjust if needed)
uniform float threshold : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    // Calculate brightness of the pixel
    float brightness = (color.r + color.g + color.b) / 3.0;

    // If pixel is darker than threshold, make it transparent
    if (brightness < threshold) {
        color.a = 0.0;
    }

    COLOR = color;
}
