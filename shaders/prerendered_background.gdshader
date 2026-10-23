shader_type spatial;
render_mode unshaded, fog_disabled, shadows_disabled, depth_draw_never, cull_disabled;

uniform sampler2D background_image : source_color, filter_linear, repeat_disable;

void vertex() {
	// Reversed Z: stay just inside the far plane (strict depth test rejects 0).
	POSITION = vec4(VERTEX.xy, 0.00001, 1.0);
}

void fragment() {
	ALBEDO = texture(background_image, SCREEN_UV).rgb;
}
