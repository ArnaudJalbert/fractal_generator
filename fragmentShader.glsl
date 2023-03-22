#version 330 core

#define MAX_RAYMARCH_STEPS 1024
#define EPSILON 0.0001f
#define MAX_DISTANCE 150
#define INFINITY 999999999
#define NORMAL_OFFSET vec2(EPSILON, 0)
#define FLOOR_PLANE_NORMAL vec3(0,1,0)
#define MIN_SHADOW 1
#define MAX_SHADOW 5
#define PENUMBRA_FACTOR 16

smooth in vec3 fragPosition; // position of the fragment
out vec4 outColor;

uniform vec2 resolution;
uniform float aspectRatio;
uniform vec3 cameraOrigin;
uniform vec3 cameraLookat;
uniform vec3 cameraUp;
uniform vec3 cameraRight;
uniform float fov;
uniform vec3 lightPosition;
uniform float lightIntensity;

/*
Computes the distance from a point to a sphere
p: point of the ray -> vec3
r: radius of the sphere -> float
*/
float sphere(vec3 p, float r){
    return length(p)-r;
}

/*
Computes the distance from a point to a plane
p: point of the ray -> vec3
n: normal of the plane(normalized) -> vec3
*/
float floorPlane( vec3 p, vec3 n)
{
    return dot(p,n) + 0.6;
}

/*
Returns the closest distance from a point
p: point -> vec3
*/
float map(vec3 p){

    // current smallest distance
    float d = INFINITY;

    d = sphere(p - vec3(0,0,-1.5), 0.75  );

    // floor plane

    float floorPlane = floorPlane(p,FLOOR_PLANE_NORMAL);

    d = min(d, floorPlane);

    return d;
}

/*
From a ray origin and direction, it checks if that ray intersects with a geometry
ro: ray origin -> vec3
rd: ray direction -> vec3
*/
bool raymarching(in vec3 ro, in vec3 rd, out vec3 p){

    // total distance traveled by ray
    float dt = 0;

    // raymarching loop
    for(int i = 0; i < MAX_RAYMARCH_STEPS; i++){

        if( dt > MAX_DISTANCE){
            return false;
        }

        // compute the current raymarching position
        p = ro + rd * dt;

        // compute the closest point to the current raymarching position
        float d = map(p);

        if(d < EPSILON){
            return true;
        }

        dt += d;

    }

    return false;

}

/*
Computes the normal of a point using forward and central differences
See this article for more details about this technique:
p: point -> vec3
*/
vec3 getNormal(in vec3 p){

    vec3 normal = vec3(map(p+NORMAL_OFFSET.xyy) - map(p-NORMAL_OFFSET.xyy),
                  map(p+NORMAL_OFFSET.yxy) - map(p-NORMAL_OFFSET.yxy),
                  map(p+NORMAL_OFFSET.yyx) - map(p-NORMAL_OFFSET.yyx)
                  );

    return normalize(normal);
}

/*
Computes the direction from the light to the point p
p: point -> vec3
*/
vec3 getLightDirection(in vec3 p){

    vec3 direction = lightPosition-p;
    direction = normalize(direction);

    return direction;
}

/*
Compute the shading intensity of the point from the normal and the light direction
*/
float shading(in vec3 p, in vec3 normal, in vec3 lightDirection, vec3 color){

    // finding the angle between the normal and the light direction
    // bringing back between
    float shadingIntensity = dot(normal, lightDirection);

    // clamping the values
    shadingIntensity = shadingIntensity * 0.5 + 0.5;

    // light intensity computation
    shadingIntensity = lightIntensity * shadingIntensity;

    return shadingIntensity;
}

/*
Computes soft shadows

*/
float softShadow(in vec3 ro, in vec3 rd, float minDist, float maxDist, float k){

    // penumbra of the shadow
    float penumbra = 1.0;

    // stating travel point
    float t = minDist;

    // marching until we reach the max shadow's distance
    for(int i = 0; t < maxDist; i++){

        // current marching point
        vec3 p = ro + rd * t;

        // current distance
        float d = map(p);

        // checking if we intersected
        if(d < EPSILON){
            return 0.5;
        }

        // computing the penumbra
        penumbra = min(penumbra, k*d/t);

        t += d;
    }

    return penumbra * 0.5 + 0.5;
}

/*
From uv and the set geometry, it renders the color of the fragment
uv: xy position of the current
*/
vec3 render(in vec3 fragPosition, inout vec3 color){

    // origin of the ray
    vec3 ro = cameraOrigin;
    // direction of the ray
    vec3 rd = normalize(cameraLookat * fov +
                        cameraRight * fragPosition.x * aspectRatio +
                        cameraUp * fragPosition.y);

    vec3 p; // point of intersection

    // check if there is an interesection woth geometry
    bool intersection = raymarching(ro, rd, p);

    // check if there is an intersection
    if(intersection){
        // TODO calculate the shading with the information
        // color of the point

        // computing the normal of the point
        vec3 normal = getNormal(p);

        // direction of the light
        vec3 lightDirection = getLightDirection(p);

        color = shading(p, normal, lightDirection, color) * color;

        color = softShadow(p, lightDirection, MIN_SHADOW, MAX_SHADOW, PENUMBRA_FACTOR) * color;


    }
    else{
        // TODO define default BG color
        color = vec3(1,1,1);
    }

    return color;

}

void main(){

    // color of the pixel
    vec3 color = vec3(0,1,1);

    // render the color of the pixel
    color = render(fragPosition, color);

    outColor = vec4(color, 1);
}