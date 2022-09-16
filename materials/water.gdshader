// NOTE: Shader automatically converted from Godot Engine 3.4.3.stable's SpatialMaterial.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform float metallic : hint_range(0,1);
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_normal : hint_normal;
uniform float normal_scale : hint_range(-2,2);
uniform float uv1_scale;
uniform float shore_max_depth : hint_range(0, 64);
uniform float shore_noise_factor : hint_range(0, 16);
uniform float shore_period : hint_range(0, 16);
uniform float shore_speed;
uniform sampler2D texture_shore_noise : hint_white;
const float M_2PI = 2.0 * 3.14159265359;
const float phi = 1.61803398875;

vec3 normalize_nmap(vec3 n) {
	return normalize(n * 2. - 1.) * .5 + .5;
}
vec3 average_nmap(vec3 a, vec3 b) {
	return normalize((a-.5) + (b-.5)) * .5 + .5;
}
void vertex() {
	UV = UV * uv1_scale;
	//UV2 = UV * uv1_scale * phi*1.0;
}
void light()
{
}

void fragment() {
	vec2 base_uv = UV;
	//vec2 base_uv2 = UV2;
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	float normal_far_attenuation = smoothstep(0., 0.1, dot(NORMAL,VIEW));
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = 0.5;
	NORMALMAP = texture(texture_normal, base_uv).rgb;
	//NORMALMAP = normalize_nmap(NORMALMAP);
	//NORMALMAP = average_nmap(texture(texture_normal,base_uv).rgb, vec3(0.5,0.5,-1));
	//NORMALMAP = average_nmap(texture(texture_normal,base_uv).rgb, texture(texture_normal,base_uv2).rgb);
	NORMALMAP_DEPTH = normal_scale * normal_far_attenuation;
	//vec4 proj = PROJECTION_MATRIX * vec4(VERTEX, 1.0);
	//DEPTH = proj.z / proj.w *.5+.5;
	/*
	float shore_noise_tex = texture(texture_shore_noise, base_uv).r;
	float depth_tex = texture(DEPTH_TEXTURE,SCREEN_UV).r;
	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV*2.0-1.0,depth_tex*2.0-1.0,1.0);
	float depth = max(VERTEX.z - world_pos.z / world_pos.w, 0.0);
	float shore_ratio = clamp((shore_max_depth - depth) / shore_max_depth, 0.0, 1.0);
	float shore_anim = sin((shore_ratio * shore_period + shore_noise_tex * shore_noise_factor) * 2.0 * 3.1415 + TIME * shore_speed) * .5 + .5;
	float shore = shore_ratio * (1.0 + shore_anim);
	float shore_sharp = smoothstep(0.8, 1.0, shore);*/
}
