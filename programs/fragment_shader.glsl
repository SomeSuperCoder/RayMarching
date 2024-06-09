#version 430 core
#include hg_sdf.glsl

layout (location = 0) out vec4 fragColor;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

const float FOV = 1.0;
const int MAX_STEPS = 256;
const float MAX_DIST = 500;
const float EPSILON = 0.0001;

vec2 fOpUnionId(vec2 res1, vec2 res2) {
    return (res1.x < res2.x) ? res1 : res2;
}

vec2 fOpDifferenceID(vec2 res1, vec2 res2) {
    return (res1.x > -res2.x) ? res1 : vec2(-res2.x, res2.y);
}

vec2 map(vec3 p) {
    float planceDist = fPlane(p, vec3(0, 1, 0), 1.0);
    float planceID = 2.0;
    vec2 plane = vec2(planceDist, planceID);

    float sphereDist = fSphere(p, 1.0);
    float sphereID = 1.0;
    vec2 sphere = vec2(sphereDist, sphereID);

    float boxDist = fBox(p + vec3(3, 0, 0), vec3(1, 1, 1));
    float boxID = 3.0;
    vec2 box = vec2(boxDist, boxID);
    
    vec2 res = sphere;
    res = fOpUnionId(res, box);
    res = fOpUnionId(res, plane);

    return res;
}

vec2 ray_march(vec3 ro, vec3 rd) {
    vec2 hit, object = vec2(0);
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + object.x * rd;
        hit = map(p);
        object.x += hit.x;
        object.y = hit.y;
        if (abs(hit.x) < EPSILON || object.x > MAX_DIST) break;
    }
    return object;
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(EPSILON, 0);
    vec3 n = vec3(map(p).x) - vec3(map(p - e.xxy).x, map(p - e.yxy).x, map(p - e.yyx).x);

    return normalize(n);
}

vec3 getLight(vec3 p, vec3 rd, vec3 color) {
    vec3 lightPos = vec3(20, 40, -30);
    vec3 L = normalize(lightPos - p);
    vec3 N = getNormal(p);
    vec3 V = -rd;
    vec3 R = reflect(-L, N);

    vec3 specColor = vec3(0.5);
    vec3 specular = specColor * pow(clamp(dot(R, V), 0, 1), 10);
    vec3 diffuse = color * clamp(dot(L, N), 0.0, 1.0);
    vec3 ambient = color * 0.05;
    vec3 fresnel = 0.25 * color * pow(1.0 + dot(rd, N), 3.0);

    float d = ray_march(p + N * 0.02, normalize(lightPos)).x;

    if (d < length(lightPos - p)) return ambient + fresnel;

    return diffuse + ambient + specular + fresnel;
}

vec3 getMaterial(vec3 p, float id) {
    vec3 m = vec3(0);

    switch (int(id)) {
        case 1:
            m = vec3(0.9, 0.9, 0); break;
        case 2:
            m = vec3(0.2 + 0.4 * mod(floor(p.x) + floor(p.z), 2.0)); break;
        case 3:
            m = vec3(1); break;
    }

    return m;
}

mat3 getCam(vec3 ro, vec3 lookAt) {
    vec3 camF = normalize(vec3(lookAt - ro));
    vec3 camR = normalize(cross(vec3(0, 1, 0), camF));
    vec3 camU = cross(camF, camR);

    return mat3(camR, camU, camF);
}

void mouseControl(inout vec3 ro) {
    vec2 m = u_mouse / u_resolution;

    pR(ro.yz, m.y * PI * 0.5 - 0.5);
    pR(ro.xz, m.x * TAU);
}

void main() {
    vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution.xy) / u_resolution.y;

    vec3 col = vec3(0.0);
    vec3 ro = vec3(3.0, 1.0, -4);
    mouseControl(ro);
    vec3 lookAt = vec3(0);
    vec3 rd = getCam(ro, lookAt) * normalize(vec3(uv, FOV));

    vec2 object = ray_march(ro, rd);

    vec3 background = vec3(0.5, 0.8, 0.9);
    if (object.x < MAX_DIST) {
        vec3 p = ro + object.x * rd;
        vec3 material = getMaterial(p, object.y);
        col += getLight(p, rd, material);

        // fog
        col = mix(col, background, 1 - exp(-0.0008 * object.x * object.x));
    } else {
        col += background - max(0.95 * rd.y, 0.0);
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
