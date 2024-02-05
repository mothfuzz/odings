struct Material {
    sampler2D albedo_texture;
    vec4 albedo_tint;
    sampler2D normal_texture;
    sampler2D roughness_texture;
    vec4 roughness_tint;
    sampler2D metallic_texture;
    vec4 metallic_tint;
};
