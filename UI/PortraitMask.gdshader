shader_type canvas_item;

uniform vec2 box_ratio = vec2(1.0);
varying vec4 portrait_modulate;

void vertex() {
    portrait_modulate = COLOR;
}

// The frame's inner lip begins at 54 px in the 512 px source artwork.
// Draw the full portrait inside that opening, leaving the outer corners clear.
void fragment() {
    const float inset = 54.0 / 512.0;
    vec2 square_uv = (UV - vec2(0.5)) * box_ratio + vec2(0.5);
    vec2 portrait_uv = (square_uv - vec2(inset)) / (1.0 - 2.0 * inset);
    float inside = step(0.0, portrait_uv.x) * step(0.0, portrait_uv.y)
        * step(portrait_uv.x, 1.0) * step(portrait_uv.y, 1.0);
    // Cover the square opening without stretching rectangular ruler portraits.
    float source_aspect = TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
    vec2 sample_uv = portrait_uv - vec2(0.5);
    sample_uv *= vec2(min(1.0, 1.0 / source_aspect), min(1.0, source_aspect));
    COLOR = portrait_modulate * texture(TEXTURE, clamp(sample_uv + vec2(0.5), vec2(0.0), vec2(1.0)));
    COLOR.a *= inside;
}
