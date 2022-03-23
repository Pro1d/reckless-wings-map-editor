// NOTE: Shader automatically converted from Godot Engine 3.4.3.stable's SpatialMaterial.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform float specular;
uniform float metallic;
uniform float alpha_scissor_threshold;
uniform float roughness : hint_range(0,1);
uniform vec4 transmission : hint_color;
varying float hard_ao;

void vertex() {
	float h = clamp(abs(VERTEX.y) / 4.4, 0.0, 1.0);
	float r_min = 1.7 * (1.0 - h);
	float r_max = 2.0 * (1.0 - h);
	hard_ao = clamp(smoothstep(r_min, r_max, length(VERTEX.xz)), 0.1, 1.0);
	//height_ratio = ;
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	ALPHA = albedo.a * albedo_tex.a;
	TRANSMISSION = transmission.rgb;
	ALPHA_SCISSOR = alpha_scissor_threshold;
	AO = hard_ao;
	AO_LIGHT_AFFECT = 1.0;
}
