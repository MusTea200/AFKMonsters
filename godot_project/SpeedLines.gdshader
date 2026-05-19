shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.5);
uniform float speed_multiplier : hint_range(0.0, 10.0) = 1.0;
uniform float line_density : hint_range(0.0, 100.0) = 50.0;
uniform float line_length : hint_range(0.0, 1.0) = 0.5;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV - 0.5;
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);

    // Polar coordinates for radial streaks
    float noise = rand(vec2(floor(angle * line_density), 0.0));

    // Time-based streaming
    float stream = fract(radius * 5.0 - TIME * speed_multiplier * 5.0 * noise);

    // Fade out towards center
    float alpha = smoothstep(1.0 - line_length, 1.0, stream) * smoothstep(0.1, 0.5, radius);

    COLOR = line_color;
    COLOR.a *= alpha * noise * speed_multiplier * 0.5; // Intensity based on speed
}
