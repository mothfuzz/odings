precision highp float;

in vec3 frag_position;
in vec2 frag_texcoord;
in vec4 frag_color;
in float depth;
in vec3 eyedir;

in mat3 TBN;

uniform bool texture_correct;

uniform sampler2D albedo_texture;
uniform vec4 albedo_tint;
uniform sampler2D normal_texture;
uniform sampler2D roughness_texture;
uniform vec4 roughness_tint;
uniform sampler2D metallic_texture;
uniform vec4 metallic_tint;

uniform vec4 fog_color;
#define MAX_LIGHTS 128
//1024 uniforms vectors total (i.e. *0.5 for each light)
//and only 16 texture units. 4 are being used by the material, possibly more for an environment map of sorts.
//leaving 8-12 shadow maps.
//we should prooooobably leave it at 8 lights per instance, but that would require undoing instancing.
//but that might be more performant anyway...? do more research.
//WAIT
//ARRAYS ONLY TAKE UP 1 TEXTURE UNIT FUCK ALL THAT

//precision highp sampler2DArrayShadow;
//uniform sampler2DArrayShadow directional_light_shadows;
//precision highp samplerCubeArrayShadow;
//uniform samplerCubeArrayShadow point_light_shadows;

struct DirectionalLight {
    vec3 direction;
    vec4 color;
    //sampler2DShadow shadow_map;
};
uniform int num_directional_lights;
uniform DirectionalLight directional_lights[MAX_LIGHTS];

struct PointLight {
    vec3 position;
    vec4 color;
    //samplerCubeShadow shadow_map;
};
uniform int num_point_lights;
uniform PointLight point_lights[MAX_LIGHTS];

layout(location=0) out vec4 screen_color;

const float fog_min = 1024.0;
const float fog_max = fog_min + 4096.0;

//test
//vec3 light_dir = vec3(0.5, -1.0, 0.0);
const vec3 ex_light_pos = vec3(0, -500, 0);
//color rgb, then radius/intensity
const vec4 ex_light_col = vec4(1.0, 1.0, 1.0, 2000.0);

float calc_light(vec3 normal, float roughness, vec3 eyedir, vec3 lightdir) {
    vec3 n = normalize(normal * 2.0 - 1.0);
    vec3 l = normalize(lightdir);
    float diffuse = clamp(dot(n, l), 0.0, 1.0);
    vec3 v = normalize(eyedir);
    vec3 r = reflect(-l, n);
    float specular = pow(clamp(dot(v, r), 0.0, 1.0), 64.0*roughness);
    return diffuse + specular;
}

void main() {
    vec4 f = frag_color;
    vec2 uv = frag_texcoord;
    if(!texture_correct){
        f = frag_color/depth;
        uv = frag_texcoord/depth;
    }

    screen_color = f * texture(albedo_texture, uv);
    vec3 normal = texture(normal_texture, uv).rgb;
    float roughness = texture(roughness_texture, uv).r;

    vec3 ambient = vec3(0.2, 0.2, 0.2);
    vec3 total_light = vec3(1.0, 1.0, 1.0);
    if(num_point_lights > 0 || num_directional_lights > 0) {
        total_light = ambient;
    }
    for(int i = 0; i < num_directional_lights; i++) {
        vec3 lightdir = TBN * directional_lights[i].direction;
        float str = directional_lights[i].color.a;
        total_light += directional_lights[i].color.rgb * str * calc_light(normal, roughness, eyedir, lightdir);
    }
    for(int i = 0; i < num_point_lights; i++) {
        vec3 light_pos = point_lights[i].position;
        float radius = point_lights[i].color.a;
        float dist = length(frag_position-light_pos);
        if(dist < radius) {
            float attenuation = clamp(abs(dist - radius)/dist, 0.0, 1.0);
            vec3 lightdir = TBN * light_pos + eyedir;
            total_light += point_lights[i].color.rgb * attenuation * calc_light(normal, roughness, eyedir, lightdir);
        }
    }
    screen_color *= vec4(total_light, 1.0);

    float fog = clamp((fog_max - length(frag_position)) / (fog_max - fog_min), 0.0, 1.0);
    screen_color = mix(fog_color, screen_color, fog);
}