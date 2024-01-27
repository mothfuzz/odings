precision highp float;

in vec3 frag_position;
in vec2 frag_texcoord;
in vec4 frag_color;
in float depth;
in vec3 eyedir;

in mat3 TBN;

uniform bool texture_correct;
uniform bool depth_prepass;
uniform bool trans_pass;

uniform sampler2D albedo_texture;
uniform vec4 albedo_tint;
uniform sampler2D normal_texture;
uniform sampler2D roughness_texture;
uniform vec4 roughness_tint;
uniform sampler2D metallic_texture;
uniform vec4 metallic_tint;

uniform vec4 fog_color;

//precision highp sampler2DArrayShadow;
//precision highp samplerCubeArrayShadow;
//uniform sampler2DArrayShadow directional_light_shadows;
//uniform samplerCubeArrayShadow point_light_shadows;
//uniform sampler2DArrayShadow spot_light_Shadows;

struct DirectionalLight {
    vec3 direction;
    vec4 color;
    bool shadows;
};
uniform int num_directional_lights;
uniform DirectionalLight directional_lights[MAX_DIRECTIONAL_LIGHTS];

struct PointLight {
    vec3 position;
    vec4 color;
    bool shadows;
};
uniform int num_point_lights;
uniform PointLight point_lights[MAX_POINT_LIGHTS];

struct SpotLight {
    vec3 position;
    vec3 direction;
    vec4 color;
    bool shadows;
};
uniform int num_spot_lights;
uniform SpotLight spot_lights[MAX_SPOT_LIGHTS];

layout(location=0) out vec4 screen_color;

const float fog_min = 1024.0;
const float fog_max = fog_min + 4096.0;

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
    screen_color = f * texture(albedo_texture, uv) * albedo_tint;

    //transparent pixels do not contribute to depth writes.
    if(depth_prepass) {
        if(screen_color.a <= 0.9) {
            discard;
        }
        return;
    }

    //render transparent pixels in a separate pass
    if(trans_pass && screen_color.a > 0.9) {
       discard;
    }
    if(!trans_pass && screen_color.a <= 0.9) {
        discard;
    }

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
    for(int i = 0; i < num_spot_lights; i++) {
        vec3 light_pos = spot_lights[i].position;
        vec3 lightdir = TBN * light_pos + eyedir;
        vec3 spotdir = TBN * spot_lights[i].direction;
        float theta = dot(normalize(lightdir), normalize(-spotdir));
        float a = spot_lights[i].color.a;
        float soft = 0.05;
        float intensity = clamp((theta - (a - soft)) / soft, 0.0, 1.0);
        if(intensity > 0.0) {
            total_light += spot_lights[i].color.rgb * calc_light(normal, roughness, eyedir, lightdir) * intensity;
        }
    }
    screen_color *= vec4(total_light, 1.0);

    float fog = clamp((fog_max - length(frag_position)) / (fog_max - fog_min), 0.0, 1.0);
    screen_color = mix(fog_color, screen_color, fog);
}
