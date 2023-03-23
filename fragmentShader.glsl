#version 330 core

// raymarch settings
#define MAX_RAYMARCH_STEPS 1024
#define EPSILON 0.001f
#define MAX_DISTANCE 150
// utils
#define INFINITY 999999999
#define PI 3.14159265358979
// normals
#define NORMAL_OFFSET vec2(EPSILON, 0)
// geometry
#define FLOOR_PLANE_NORMAL vec3(0,1,0)
// shadows
#define MIN_SHADOW 1
#define MAX_SHADOW 5
#define PENUMBRA_FACTOR 8
// ambient occlusion
#define AO_STEPS 10
#define AO_STEP_SIZE 0.01f
#define AO_INTENSITY 1.0f
// mandelbulb
#define MB_REPETITIONS 10
#define MB_ITERATIONS 31
#define MB_BAILOUT 2.0


smooth in vec3 fragPosition; // position of the fragment
out vec4 outColor; // outputted color

uniform vec2 resolution;
uniform float aspectRatio;
uniform vec3 cameraOrigin;
uniform vec3 cameraLookat;
uniform vec3 cameraUp;
uniform vec3 cameraRight;
uniform float fov;
uniform vec3 lightPosition;
uniform float lightIntensity;

uniform float mbIterations;


/*
SDF of the mandelbulb fractals
Computes the distance from a point to the closest
*/
float mandelbulb (vec3 position) {

    // zeta variable to be computed
    vec3 zeta = position;
    //derivative of the mandelbulb
    float dr = 1.0;
    // current distance from the origin
    float r = 0.0;

    for (int i = 0; i < MB_REPETITIONS; i++) {

        // convert to polar coordinates
        r = length (zeta);
        if (r > MB_BAILOUT) break; // check if the distance from the fractal is too far
        float phi = acos (zeta.z / r);
        float theta = atan (zeta.y, zeta.x);
        dr = pow (r, mbIterations - 1.0) * mbIterations * dr + 1.0;

        // scale and rotate the point
        float zr = pow (r, mbIterations);
        phi = phi * mbIterations;
        theta = theta * mbIterations;

        // converting back to euclidean coordinatees
        float x = sin (phi) * cos(theta);
        float y = sin(theta) * sin(phi);
        float z = cos(phi);

        // scale with r
        zeta = zr * vec3 (x,y,z);
        // march over the position
        zeta += position;
    }

    // estimating the distance with Douady-Hubbard Potential(
    float dst = 0.5 * log (r) * r / dr;

    // current distance from ray
    return dst;
}

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
    return dot(p,n) + 0.75;
}

// Mod Position Axis
float modAxis (inout float p, float size)
{
    float halfsize = size * 0.5;
    float c = floor((p+halfsize)/size);
    p = mod(p+halfsize,size)-halfsize;
    p = mod(-p+halfsize,size)-halfsize;
    return c;
}

// Rotation matrix around the x axis
// inverting it natively
mat3 rotateX(float theta) {
    // cosine value
    float c = cos(theta);
    // sin value
    float s = sin(theta);
    // see transformation matrices
    return mat3(
    vec3(1, 0, 0),
    vec3(0, c, -s),
    vec3(0, s, c)
    );
}

// Rotation matrix around the y axis
// inverting it natively
mat3 rotateY(float theta) {
    // cosine value
    float c = cos(theta);
    // sin value
    float s = sin(theta);
    // see transformation matrices
    return mat3(
    vec3(c, 0, s),
    vec3(0, 1, 0),
    vec3(-s, 0, c)
    );
}

// Rotation matrix around the z axis
// inverting it natively
mat3 rotateZ(float theta) {
    // cosine value
    float c = cos(theta);
    // sin value
    float s = sin(theta);
    // see transformation matrices
    return mat3(
    vec3(c, -s, 0),
    vec3(s, c, 0),
    vec3(0, 0, 1)
    );
}

/*
Returns the closest distance from a point
p: point -> vec3
*/
float map(vec3 p){

    // we first make all the transofrmation we wish to do
    // rotations, translations, scaling, mod repeat...

//    modAxis(p.x, 2);
//    modAxis(p.y, 2);

    float offset = mbIterations * 0.25;
    mat3 rotateZ = rotateZ(offset);

    p = p * rotateZ;

    mat3 rotateY = rotateY(offset);

    p = p* rotateY;



    // current smallest distance
    float d = INFINITY;

//    d = sphere(p - vec3(0,0,-1.5), 0.75 );
    d = mandelbulb(p - vec3(0,0, 0));

    // floor plane

//    float floorPlane = floorPlane(p,FLOOR_PLANE_NORMAL);
//
//    d = min(d, floorPlane);

    return d;
}

/*
From a ray origin and direction, it checks if that ray intersects with a geometry
ro: ray origin -> vec3
rd: ray direction -> vec3
*/
bool raymarching(vec3 ro, vec3 rd, out vec3 p){

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
vec3 getNormal(vec3 p){

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
vec3 getLightDirection(vec3 p){

    vec3 direction = lightPosition-p;
    direction = normalize(direction);

    return direction;
}

/*
Compute the shading intensity of the point from the normal and the light direction
*/
float shading(vec3 p, vec3 normal, vec3 lightDirection, vec3 color){

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
Computes soft shadows with the point and the light direction

*/
float softShadow(in vec3 lightOrigin, in vec3 lightDirection){

    // penumbra of the shadow
    float penumbra = 1.0;

    // stating travel point
    float t = MIN_SHADOW;

    // marching until we reach the max shadow's distance
    for(int i = 0; t < MAX_DISTANCE; i++){

        // current marching point
        vec3 p = lightOrigin + lightDirection * t;

        // current distance
        float d = map(p);

        // checking if we intersected
        if(d < EPSILON){
            return 0.5;
        }

        // computing the penumbra
        penumbra = min(penumbra, PENUMBRA_FACTOR*d/t);

        // adding the distance
        t += d;
    }

    return penumbra * 0.5 + 0.5;
}

float ambientOcclusion(in vec3 p, in vec3 n){

    float occlusion = 0;

    float stepSize = AO_STEP_SIZE;

    for(int i = 0; i < AO_STEPS; i++){
        // current marching point
        vec3 rp = p + n * stepSize;

        // distance from point
        float d = map(rp);

        // summing the occlusion
        occlusion += stepSize - d;

        stepSize += AO_STEP_SIZE;

    }

    occlusion *= AO_INTENSITY;

    return 1 - clamp(occlusion, 0, 1);
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

        color = softShadow(p, lightDirection) * color;

        color = ambientOcclusion(p, normal) * color;


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