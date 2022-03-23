// NOTE: Shader automatically converted from Godot Engine 3.4.beta's SpatialMaterial.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform sampler2D texture_albedo : hint_albedo;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;
uniform vec4 rock_color : hint_color;
uniform vec4 grass_color : hint_color;
uniform vec4 sand_color : hint_color;
uniform float abyss_depth : hint_range(0.0, 1024.0);
varying float height;
varying float slope;

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	vec4 world_pos = WORLD_MATRIX * vec4(VERTEX, 1.0);
	height = world_pos.y;
	slope = NORMAL.y;
}

void fragment() {
	//vec2 base_uv = UV;
	//vec4 albedo_tex = texture(texture_albedo, base_uv);
	//NORMAL = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	float k = smoothstep(1.9, 3.0, height);// < 1.5 ? 1.0 : 0.0;
	vec4 color = mix(sand_color, grass_color, k);
	k = smoothstep(0.50, 0.65, slope);
	color = mix(rock_color, color, k);
	float abyss = pow(1.0 - clamp(-height / abyss_depth, 0.0, 1.0), 4);
	ALBEDO = color.rgb * abyss;
	METALLIC = metallic;// * (1.0 - abyss);
	ROUGHNESS = roughness;// * (1.0-abyss);
	SPECULAR = specular;// * (1.0-abyss);
}
