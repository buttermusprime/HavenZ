shader_type canvas_item;

// F.1: unifies palette_remap.gdshader (D.2) and palette_glow.gdshader (D.5)
// into one shader/one shared material, so every pixelpipe-managed sprite
// gets both effects without a CanvasItem.material single-slot conflict
// (the gap D.5 flagged but didn't fix). Reads a 4-row LUT texture built by
// PixelPipeLutGenerator.build_unified_lut_texture(): an (N, 4) image where
// row 0 (v=0.125) is the project's canonical palette in a fixed order
// (match key, raw sRGB bytes), row 1 (v=0.375) is the applied/remap color
// for that index, row 2 (v=0.625) is that index's independent glow color,
// and row 3 (v=0.875) packs glow intensity/max_intensity into every
// channel (r=g=b). palette_size == 0 is a deliberate no-op passthrough,
// same convention as both predecessor shaders.
//
// Compositing is ADDITIVE, not multiplicative -- result = applied_color +
// glow_color * intensity -- so glow_color is a real independent hue rather
// than D.5's old "this color, but brighter." intensity == 0 makes the glow
// term exactly zero regardless of glow_color, so a non-emissive index is a
// true no-op past the remap step, matching D.5's original guarantee.
//
// Matches against row 0 both as raw stored bytes and as an sRGB->linear
// conversion of those bytes -- carried over from palette_remap.gdshader
// (D.2/D.5 follow-up), required because Godot auto-converts an IMPORTED
// texture's sample (TEXTURE here) from sRGB to linear when the viewport has
// use_hdr_2d enabled, but does NOT apply that same conversion to a
// runtime-built texture like this LUT. Row 1 and row 2 are both stored raw
// sRGB (not pre-converted) and are converted the same way row 0's match
// result implies, so the applied color and the glow color both composite
// correctly in either viewport configuration -- glow no longer assumes an
// HDR-only viewport the way D.5's standalone shader did; it's simply inert
// (zero visible bloom) without HDR + Glow + BG_CANVAS, per Build Guideline
// 07a's documented prerequisites.
uniform sampler2D lut_texture : filter_nearest, repeat_disable;
uniform int palette_size = 0;
uniform float max_intensity : hint_range(0.0, 16.0) = 4.0;
uniform float match_threshold : hint_range(0.0, 0.25) = 0.02;

vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	vec3 result = src.rgb;

	if (palette_size > 0) {
		for (int i = 0; i < palette_size; i++) {
			float u = (float(i) + 0.5) / float(palette_size);
			vec3 from_color = texture(lut_texture, vec2(u, 0.125)).rgb;
			bool raw_match = distance(src.rgb, from_color) < match_threshold;
			bool linear_match = distance(src.rgb, srgb_to_linear(from_color)) < match_threshold;
			if (raw_match || linear_match) {
				vec3 applied_raw = texture(lut_texture, vec2(u, 0.375)).rgb;
				vec3 glow_raw = texture(lut_texture, vec2(u, 0.625)).rgb;
				float packed_intensity = texture(lut_texture, vec2(u, 0.875)).r;
				float intensity = packed_intensity * max_intensity;

				// Prefer the raw interpretation on a rare ambiguous
				// double-match (near-black/gray colors where sRGB and
				// linear values land close together) -- matches D.2's
				// original, extensively-tested non-HDR default.
				vec3 applied = (raw_match) ? applied_raw : srgb_to_linear(applied_raw);
				vec3 glow_color = (raw_match) ? glow_raw : srgb_to_linear(glow_raw);

				result = applied + glow_color * intensity;
				break;
			}
		}
	}

	COLOR = vec4(result, src.a);
}
