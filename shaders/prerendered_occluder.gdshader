shader_type spatial;
render_mode unshaded, fog_disabled, shadows_disabled, depth_draw_opaque;

uniform sampler2D background_image : source_color, filter_linear, repeat_disable;

void fragment() {
	// The opaque proxy reproduces the baked pixel but retains its real 3D depth.
	// Do not write ALPHA: that would move this material into the transparent pass.
	ALBEDO = texture(background_image, SCREEN_UV).rgb;
}
