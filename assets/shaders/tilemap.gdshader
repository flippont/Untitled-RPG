shader_type canvas_item;

uniform vec2 tile_size;
uniform vec2 atlas_size;

varying vec2 atlas_uv;

void vertex() {
	vec2 uv = UV;
	if (INSTANCE_CUSTOM.z > 0.5)
		uv.x = 1.0 - uv.x;
	if (INSTANCE_CUSTOM.w > 0.5)
		uv.y = 1.0 - uv.y;
	vec2 atlas_tiles = atlas_size / tile_size;
	atlas_uv = (INSTANCE_CUSTOM.xy + uv) / atlas_tiles;
}

void fragment() {
	COLOR = texture(TEXTURE, atlas_uv);
}