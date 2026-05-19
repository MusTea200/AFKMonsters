shader_type canvas_item;

uniform vec4 grid_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform vec4 bg_color : source_color = vec4(0.05, 0.0, 0.1, 1.0);
uniform float grid_size = 20.0;
uniform float line_width = 0.05;
uniform vec2 scroll_speed = vec2(0.0, 1.0);

void fragment() {
    vec2 uv = UV * grid_size + TIME * scroll_speed;
    vec2 grid = fract(uv);

    float on_line = step(grid.x, line_width) + step(grid.y, line_width);
    on_line = clamp(on_line, 0.0, 1.0);

    COLOR = mix(bg_color, grid_color, on_line);
}
