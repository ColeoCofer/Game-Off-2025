/*
Shader from Godot Shaders - the free shader library.
godotshaders.com/shader/god-rays

Feel free to use, improve and change this shader according to your needs
and consider sharing the modified result on godotshaders.com.
*/

shader_type canvas_item;

uniform float angle = -0.3;
uniform float position = -0.2;
uniform float spread : hint_range(0.0, 1.0) = 0.5;
uniform float cutoff : hint_range(-1.0, 1.0) = 0.1;
uniform float falloff : hint_range(0.0, 1.0) = 0.2;
uniform float edge_fade : hint_range(0.0, 1.0) = 0.15;

uniform float speed = 1.0;
uniform float ray1_density = 8.0;
uniform float ray2_density = 30.0;
uniform float ray2_intensity : hint_range(0.0, 1.0) = 0.3;

uniform vec4 color : source_color = vec4(1.0, 0.9, 0.65, 0.8);

uniform bool hdr = false;
uniform float seed = 5.0;

// Random and noise functions from Book of Shader's chapter on Noise.
float random(vec2 _uv) {
    return fract(sin(dot(_uv.xy,
                         vec2(12.9898, 78.233))) *
        43758.5453123);
}

float noise (in vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));


    // Smooth Interpolation

    // Cubic Hermine Curve. Same as SmoothStep()
    vec2 u = f * f * (3.0-2.0 * f);

    // Mix 4 coorners percentages
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

mat2 rotate(float _angle){
    return mat2(vec2(cos(_angle), -sin(_angle)),
                vec2(sin(_angle), cos(_angle)));
}

vec4 screen(vec4 base, vec4 blend){
    return 1.0 - (1.0 - base) * (1.0 - blend);
}

void fragment()
{
    // Start with basic UVs
    vec2 uv = UV;

    // Create animated vertical rays
    float x_pos = uv.x + position;

    // Apply spread - makes the beam wider at the bottom
    float spread_factor = mix(1.0, 1.0 + spread, uv.y);
    x_pos = (x_pos - 0.5) * spread_factor + 0.5;

    // Animate the ray with time
    vec2 ray1_uv = vec2(x_pos * ray1_density + sin(TIME * 0.1 * speed) * 2.0 + seed, uv.y);
    vec2 ray2_uv = vec2(x_pos * ray2_density + sin(TIME * 0.2 * speed) * 2.0 + seed, uv.y);

    // Generate the ray patterns using noise
    float ray_pattern = noise(ray1_uv) * (1.0 - ray2_intensity) + noise(ray2_uv) * ray2_intensity;

    // Make the rays more pronounced (increase contrast)
    ray_pattern = pow(ray_pattern, 2.0);

    // Fade out at the bottom
    float vertical_fade = 1.0 - smoothstep(1.0 - falloff, 1.0, uv.y);

    // Fade out at the sides
    float horizontal_fade = smoothstep(0.0, edge_fade, x_pos) * smoothstep(0.0, edge_fade, 1.0 - x_pos);

    // Combine everything
    float final_intensity = ray_pattern * vertical_fade * horizontal_fade;

    // Apply color
    vec3 beam_color = color.rgb * final_intensity;
    float beam_alpha = final_intensity * color.a;

    COLOR = vec4(beam_color, beam_alpha);
}
