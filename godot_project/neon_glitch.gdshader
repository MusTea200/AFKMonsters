shader_type canvas_item;

uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.05;
uniform float glitch_speed : hint_range(0.0, 10.0) = 5.0;
uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;

    // Add time-based glitch steps
    float time_step = floor(TIME * glitch_speed);

    // Horizontal glitch offset
    float offset_x = (rand(vec2(time_step, uv.y)) - 0.5) * glitch_intensity;

    // RGB split channels
    float r = texture(TEXTURE, vec2(uv.x + offset_x * 1.5, uv.y)).r;
    float g = texture(TEXTURE, uv).g;
    float b = texture(TEXTURE, vec2(uv.x - offset_x * 1.5, uv.y)).b;
    float a = texture(TEXTURE, uv).a;

    vec4 base_color = vec4(r, g, b, a);

    // Emissive glow blend
    float glow_mask = step(0.5, r + g + b) * a;
    COLOR = mix(base_color, glow_color, glow_mask * 0.3 * (sin(TIME * 3.0) * 0.5 + 0.5));
    COLOR.a = a;
}
