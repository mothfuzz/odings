in vec3 frag_world_position;
in vec3 frag_position;
in vec2 frag_texcoord;
in vec4 frag_color;
in float depth;
in vec3 eyedir;

in mat3 TBN;

uniform bool texture_correct;
uniform bool depth_prepass;
uniform bool trans_pass;

//Material struct included
uniform Material material;

uniform vec4 fog_color;

precision highp sampler2DArrayShadow;
uniform sampler2DArrayShadow directional_light_shadows;
uniform sampler2DArrayShadow spot_light_shadows;
#ifdef POINT_LIGHT_SHADOWS
precision highp samplerCubeArrayShadow;
uniform samplerCubeArrayShadow point_light_shadows;
#endif

struct CombinedLight {
    vec4 posdir; //xyz0 if directional, xyz1 if positional
    vec4 color; //rgb + strength/radius
    //transform for shadows is stored in following 2 lights.
    //mat4 viewproj;
};

struct SpotLight {
    vec4 position; //xyz1
    vec4 direction; //xyz0
    vec4 color; //rgb cos(angle)
    vec4 padding; //ugh
    //transform for shadows is stored in following light.
    //mat4 viewproj;
};

layout(std140) uniform CombinedLights {
    ivec4 num_combined_lights; //directional w/shadows, directional, point w/shadows, point
    CombinedLight combined_lights[498];
};

layout(std140) uniform SpotLights {
    ivec4 num_spot_lights; //w/shadows, without, 2x padding
    SpotLight spot_lights[248];
};

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

vec3 calc_directional_light(vec3 normal, float roughness, vec3 eyedir, vec3 direction, vec3 color, float str) {
    vec3 lightdir = TBN * direction;
    return color * str * calc_light(normal, roughness, eyedir, lightdir);
}
vec3 calc_directional_light_shadow(vec3 normal, float roughness, vec3 eyedir, vec3 direction, vec3 color, float str, int shadow_index, mat4 viewproj) {
    vec3 lightdir = TBN * direction;
    //calculate if in shadow or not...
    vec4 frag_light_pos = viewproj * vec4(frag_world_position, 1.0);
    vec3 frag_light_proj = frag_light_pos.xyz / frag_light_pos.w;
    frag_light_proj = frag_light_proj * 0.5 + 0.5;
    float bias_min = 0.0005;
    float bias_max = 0.05;
    float bias = max(bias_max * (1.0 - dot(normal, lightdir)), bias_min);
    float shadow = texture(directional_light_shadows, vec4(frag_light_proj.xy, shadow_index, frag_light_proj.z - bias));
    return color * str * calc_light(normal, roughness, eyedir, lightdir) * shadow;
}

vec3 calc_point_light(vec3 normal, float roughness, vec3 eyedir, vec3 position, vec3 color, float radius) {
    float dist = length(frag_position-position);
    if(dist < radius) {
        float attenuation = clamp(abs(dist - radius)/dist, 0.0, 1.0);
        vec3 lightdir = TBN * position + eyedir;
        return color * attenuation * calc_light(normal, roughness, eyedir, lightdir);
    } else {
        return vec3(0);
    }
}

vec3 calc_spot_light(vec3 normal, float roughness, vec3 eyedir, vec3 position, vec3 direction, vec3 color, float angle) {
    vec3 lightdir = TBN * position + eyedir;
    vec3 spotdir = TBN * direction;
    float theta = dot(normalize(lightdir), normalize(-spotdir));
    float soft = 0.05;
    float intensity = clamp((theta - (angle - soft)) / soft, 0.0, 1.0);
    if(intensity > 0.0) {
        return color * calc_light(normal, roughness, eyedir, lightdir) * intensity;
    } else {
        return vec3(0);
    }
}

uniform float screen_width;
uniform float screen_height;
void main() {
    vec4 f = frag_color;
    vec2 uv = frag_texcoord;
    if(!texture_correct){
        f = frag_color/depth;
        uv = frag_texcoord/depth;
    }
    screen_color = f * texture(material.albedo_texture, uv) * material.albedo_tint;
    //screen_color = vec4(texture(directional_light_shadows, vec4(uv, depth, 0)));
    //screen_color.a = 1.0;

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

    vec3 normal = texture(material.normal_texture, uv).rgb;
    float roughness = (texture(material.roughness_texture, uv) * material.roughness_tint).r;

    vec3 ambient = vec3(0.2, 0.2, 0.2);
    vec3 total_light = ambient;
    if(num_combined_lights == ivec4(0, 0, 0, 0) && num_spot_lights.xy == ivec2(0, 0)) {
        total_light = vec3(1.0, 1.0, 1.0);
    }

    //ivec4 num_combined_lights; //directional w/shadows, directional, point w/shadows, point
    int num_directional_shadows = num_combined_lights[0];
    int num_directional_lights = num_combined_lights[1];
    int num_point_shadows = num_combined_lights[2];
    int num_point_lights = num_combined_lights[3];
    int num_spot_shadows = num_spot_lights[0];
    int num_spot_lights = num_spot_lights[1];

    int offset = 0;
    int shadow_i = 0;
    for(int i = 0; i < num_directional_shadows*3; i+=3) {
        CombinedLight l = combined_lights[offset+i];
        CombinedLight l2 = combined_lights[offset+i+1];
        CombinedLight l3 = combined_lights[offset+i+2];
        mat4 viewproj = mat4(l2.posdir, l2.color, l3.posdir, l3.color);
        total_light += calc_directional_light_shadow(normal, roughness, eyedir, l.posdir.xyz, l.color.rgb, l.color.a, shadow_i, viewproj);
        shadow_i++;
    }
    offset += num_directional_shadows*3;
    for(int i = 0; i < num_directional_lights; i++) {
        CombinedLight l = combined_lights[offset+i];
        total_light += calc_directional_light(normal, roughness, eyedir, l.posdir.xyz, l.color.rgb, l.color.a);
    }
    offset += num_directional_lights;
    shadow_i = 0;
    for(int i = 0; i < num_point_shadows; i++) {
        CombinedLight l = combined_lights[offset+i];
        total_light += calc_point_light(normal, roughness, eyedir, l.posdir.xyz, l.color.rgb, l.color.a);
        shadow_i++;
    }
    offset += num_point_shadows;
    for(int i = 0; i < num_point_lights; i++) {
        CombinedLight l = combined_lights[offset+i];
        total_light += calc_point_light(normal, roughness, eyedir, l.posdir.xyz, l.color.rgb, l.color.a);
    }

    offset = 0;
    shadow_i = 0;
    for(int i = 0; i < num_spot_shadows*2; i+=2) {
        SpotLight l = spot_lights[offset+i];
        SpotLight l2 = spot_lights[offset+i+1];
        mat4 viewproj = mat4(l2.position, l2.direction, l2.color, l2.padding);
        total_light += calc_spot_light(normal, roughness, eyedir, l.position.xyz, l.direction.xyz, l.color.rgb, l.color.a);
        shadow_i++;
    }
    offset += num_spot_shadows*2;
    for(int i = 0; i < num_spot_lights; i++) {
        SpotLight l = spot_lights[offset+i];
        total_light += calc_spot_light(normal, roughness, eyedir, l.position.xyz, l.direction.xyz, l.color.rgb, l.color.a);
    }

    screen_color *= vec4(total_light, 1.0);

    float fog = clamp((fog_max - length(frag_position)) / (fog_max - fog_min), 0.0, 1.0);
    screen_color = mix(fog_color, screen_color, fog);
}
