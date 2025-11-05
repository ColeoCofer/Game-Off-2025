shader_type canvas_item;

uniform vec4 beam_color : source_color = vec4(1.0, 0.9, 0.5, 1.0);

void fragment() {
    // Simple gradient from top (bright) to bottom (transparent)
    float alpha = 1.0 - UV.y;
    COLOR = vec4(beam_color.rgb, alpha * beam_color.a);
}
