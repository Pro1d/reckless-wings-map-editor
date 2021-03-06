// NOTE: Shader automatically converted from Godot Engine 3.4.3.stable's SpatialMaterial.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx,world_vertex_coords;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
//uniform float point_size : hint_range(0,128);
uniform sampler2D texture_albedo : hint_albedo;
uniform sampler2D texture_roughness : hint_white;
uniform sampler2D texture_normal : hint_normal;
uniform sampler2D texture_ambient_occlusion : hint_white;
uniform sampler2D texture_albedo_top : hint_albedo;
uniform sampler2D texture_roughness_top : hint_white;
uniform sampler2D texture_normal_top : hint_normal;
uniform sampler2D texture_ambient_occlusion_top : hint_white;
uniform sampler2D texture_albedo_bottom : hint_albedo;
uniform sampler2D texture_roughness_bottom : hint_white;
uniform sampler2D texture_normal_bottom : hint_normal;
uniform sampler2D texture_ambient_occlusion_bottom : hint_white;
//uniform vec4 roughness_texture_channel;
uniform float normal_scale : hint_range(-16,16);
//uniform vec4 ao_texture_channel;
uniform float ao_light_affect;
varying vec3 uv1_triplanar_pos;
const int uv1_blend_sharpness = 16;
varying vec3 uv1_power_normal;
uniform float uv1_scale;
varying float v_height;
const float wet_metallic = 0.85;
const float wet_roughness = 0.6;
const float shore_height = 17.0; // must be > 2^lod_max

void vertex() {
	TANGENT = vec3(0.0,0.0,-1.0) * abs(NORMAL.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.z);
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0,1.0,0.0) * abs(NORMAL.x);
	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(NORMAL.y);
	BINORMAL+= vec3(0.0,1.0,0.0) * abs(NORMAL.z);
	BINORMAL = normalize(BINORMAL);
	uv1_power_normal=pow(abs(NORMAL), vec3(float(uv1_blend_sharpness)));
	//uv1_power_normal.xz *= uv1_power_normal.xz*uv1_power_normal.xz;
	uv1_power_normal/=dot(uv1_power_normal,vec3(1.0));
	uv1_power_normal.y *= NORMAL.y < 0.0 ? -1.0 : 1.0;
	uv1_triplanar_pos = VERTEX * uv1_scale * vec3(1.0,-1.0, 1.0) + vec3(.0, .3, .6);
	v_height = VERTEX.y;
}


vec4 triplanar_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}
vec4 triplanar_texture_top(sampler2D p_sampler,sampler2D p_sampler_top,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_weights.y < 0.0 ? p_sampler : p_sampler_top, p_triplanar_pos.xz) * abs(p_weights.y);
	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}
vec4 triplanar_texture_auto(sampler2D p_sampler,sampler2D p_sampler_top,sampler2D p_sampler_bottom,float bottom_top,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	if (p_weights.y < 0.0)
		samp+= texture(p_sampler, p_triplanar_pos.xz) * abs(p_weights.y);
	else {
		samp+= texture(p_sampler_top, p_triplanar_pos.xz) * abs(p_weights.y) * bottom_top;
		samp+= texture(p_sampler_bottom, p_triplanar_pos.xz) * abs(p_weights.y) * (1.-bottom_top);
	}
	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}
vec3 normalize_nmap(vec3 n) {
	return normalize(n * 2. - 1.) * .5 + .5;
}

void fragment() {
	float shore = smoothstep(0, shore_height, v_height);
	vec4 albedo_tex = triplanar_texture_auto(
		texture_albedo, texture_albedo_top, texture_albedo_bottom, shore, uv1_power_normal, uv1_triplanar_pos);
	//float roughness_tex = triplanar_texture_auto(
	//	texture_roughness, texture_roughness_top, texture_roughness_bottom, shore, uv1_power_normal, uv1_triplanar_pos).r;
	float ao_tex = triplanar_texture_auto(
		texture_ambient_occlusion, texture_ambient_occlusion_top, texture_ambient_occlusion_bottom, shore, uv1_power_normal, uv1_triplanar_pos).r;
	vec3 normal_tex = normalize_nmap(triplanar_texture_auto(
		texture_normal, texture_normal_top, texture_normal_bottom, shore, uv1_power_normal, uv1_triplanar_pos).rgb);
	float wet = 1.0 - smoothstep(0, 2, v_height);
	ALBEDO = albedo_tex.rgb;
	METALLIC = mix(metallic, wet_metallic, wet);
	ROUGHNESS = mix(/*roughness_tex * */roughness, wet_roughness, wet);
	SPECULAR = specular;
	NORMALMAP = normal_tex;
	NORMALMAP_DEPTH = normal_scale;
	AO = ao_tex;
	AO_LIGHT_AFFECT = ao_light_affect;
}
