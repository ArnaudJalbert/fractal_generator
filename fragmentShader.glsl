#version 330 core

uniform sampler2D textureSampler;

// raymarch settings
#define MAX_RAYMARCH_STEPS 500
float EPSILON = 0.001;
#define MAX_DISTANCE 150
// utils
#define INFINITY 999999999
#define PI 3.14159265358979
// normals
#define NORMAL_OFFSET vec2(EPSILON, 0)
// geometry
#define FLOOR_PLANE_NORMAL vec3(0,1,0)
// repeats
float MOD_SCALE_X = 5;
float MOD_SCALE_Y = 5;
float MOD_SCALE_Z = 5;
bool MOD_X = true;
bool MOD_Y = true;
bool MOD_Z = true;
// shadows
#define MIN_SHADOW 1
#define MAX_SHADOW 50
#define PENUMBRA_FACTOR 74
// ambient occlusion
#define AO_STEPS 10
#define AO_STEP_SIZE 0.01f
#define AO_INTENSITY 1.0f
// mandelbulb
#define MB_REPETITIONS 10
#define MB_ITERATIONS 5
#define MB_BAILOUT 2.0
// menger sponge
#define MS_REPETITIONS 4
#define MS_SCALE vec3(1)
#define MS_RADIUS 0.1
#define MS_ITERATIONS 3.7f
// julia
#define JUL_REPETITIONS 7
#define M 0.7
// octahedron
#define OH_SCALE 2
// try
#define MINRAD2 .25
float minRad2 = clamp(MINRAD2, 1.0e-9, 1.0);


// ---- MODE -----
#define SPHERE_MODE 0
#define MANDELBULB_MODE 1
#define MENGER_CUBE_MODE 2
#define MENGER_OCTAHEDRON_MODE 3
#define PYRAMID_MODE 4

smooth in vec3 fragPosition; // position of the fragment
out vec4 outColor; // outputted color

// camera
uniform vec2 resolution;
uniform float aspectRatio;
uniform vec3 cameraOrigin;
uniform vec3 cameraLookat;
uniform vec3 cameraUp;
uniform vec3 cameraRight;
uniform float fov;
uniform vec3 lightPosition;
uniform float lightIntensity;

// mandelbulb
uniform float animate;

// mode
uniform int mode;

// repeat shapes
uniform int repeat;

// color of fractal
uniform vec3 mainColor;

//---------------------
// basic transormations

// mod position axis
// used to repeat a shape along an axis
float modAxis (inout float p, float size)
{
    float halfsize = size * 0.5;
    float c = floor((p+halfsize)/size);
    p = mod(p+halfsize,size)-halfsize;
    p = mod(-p+halfsize,size)-halfsize;
    return c;
}

// translation
vec3 translate(float x, float y, float z) {
    return vec3(x,y,z);
}

// Rotation matrix around the x axis
// inverting it natively
mat3 rotateX(float theta) {

    // cosine value
    float c = cos(theta);

    // sin value
    float s = sin(theta);

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

    return mat3(
    vec3(c, -s, 0),
    vec3(s, c, 0),
    vec3(0, 0, 1)
    );
}

// given two distance from sdfs, returns the distance of the union of them
float shapeUnion(float a, float b){
    return min(a, b);
}

// given two distance from sdfs, substracts shape a from b
float shapeSubtraction(float a, float b){
    return min(-a, b);
}

// given two distance from sdfs, returns the distance of the intersection of them
float shapeIntersection(float a, float b){
    return max(a,b);
}

// twists point p with a given strength
vec3 twist(vec3 p, float strength){

    float c = cos(strength * p.y);
    float s = sin(strength * p.y);

    // transformation matrix
    mat2  m = mat2(c, -s,
                   s, c);
    vec2 xz = m * p.xz;
    return vec3(xz, p.y);

}

// sin weighted displacement of a ditance
float displacement(float dist, vec3 displacedP)
{
    float d1 = sin(20*displacedP.x)*sin(20*displacedP.y)*sin(20*displacedP.z);
    return d1 + dist;
}

// ----------------------------
// computations for quaternions

// to square a quaternion
vec4 quaternionSquare(vec4 a){
    return vec4(a.x*a.x - a.y*a.y - a.z*a.z - a.w*a.w,
                2.0 * a.x * a.y,
                2.0 * a.x * a.z,
                2.0 * a.x * a.w );
}

// multiply two quaternions
vec4 quaternionMultiply(vec4 a, vec4 b){
    return vec4(a.x * b.x - a.y * b.y - a.z * b.z - a.w * b.w,
                a.y * b.x + a.x * b.y + a.z * b.w - a.w * b.z,
                a.z * b.x + a.x * b.z + a.w * b.y - a.y * b.w,
                a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y );

}

// length of quaternion
float quaternionLength(vec4 q){
    return dot(q,q);
}

//---------------
// primitive sdfs

/*
Computes the distance from a point to a sphere
p: point of the ray -> vec3
r: radius of the sphere -> float
*/
float sphere(vec3 p, float r){
    return length(p)-r;
}

/*
SDF of round box used for menger sponge
*/
float roundbox( vec3 p, vec3 b, float r ){
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

/*
SDF of ocatahedron used for menger sponge
*/
float octahedron( vec3 p){
    p = abs(p);
    return (p.x+p.y+p.z-OH_SCALE*5)*0.57735027;
}

//-------------
// fractals sdfs

float arnoFractal2(vec3 p){

    vec3 p0 = p;

    float d;
    for(int i = 0 ; i< 10; i++){

        p = abs(p);

        p = 2*p - vec3(3, 3, 3);

        p *= rotateY(animate*0.01);

        p *= rotateZ(i);

        p.xyz = clamp(p.xyz, -0.1, 0.1) - p.xyz-0.25;

        p.xy = p.yx;

        p *= rotateX(animate*0.1);

    }

    return length(p)*pow(2, -float(10))-.1;
}

float arnoFractal(vec3 p){

    vec3 p0 = p;

    for(int i = 0 ; i< 10; i++){

        p = abs(p);

        p = 2*p - vec3(3, 10, 3);

        p = p * rotateZ(animate*0.1);

        p = p * rotateX(animate*0.05);

        p = p - sin(vec3(animate*0.1));

        p.z += animate*0.001;

        p.xy = p.yx;
    }

    return length(p)*pow(2, -float(10))-.1;
}

float soapBlob(vec3 p){

    float len = length(p);
    float scale = 1.25;
    int iterations = 20;
    float l = 0.;

    vec3 juliaOffset = vec3(-3.,-1.15,-.8);

    for (int i=0; i<10; i++) {

        p = abs(p);

        // scale and offset the position
        p = p*scale + juliaOffset;

        p.xyz = p.zxy;
//        p.z = p.z * cos(animate*0.01);

        float offset = mod(animate * 0.1, 10);
        p = p * rotateX(animate * 0.1);
        p = p + translate(offset*0.1,0,0);

        l=length(p);
    }
    return l*pow(scale, -float(10))-.25;
}

float try3(vec3 pos){

    // converting to 4d
    vec4 p = vec4(pos,1);

    // original p
    vec4 p0 = p;


    float defaultScale = 4;

    vec4 scale = (vec4(defaultScale, defaultScale, defaultScale, abs(defaultScale)) / minRad2);

    for (int i = 0; i < 10; i++)
    {
        p.xyz = clamp(p.xyz, -3.0, 2.5) * 1.5 - p.xyz;


        float r2 = dot(p.xyz, p.xyz);

        p *= clamp(max(minRad2/r2, minRad2), 0.0, 2.0);

        // scale, translate
        p = p*scale + p0;

        p.xyz = p.xyz * rotateY(animate*0.07);

    }

    float dist = ((length(p.xyz) - abs(2.8 - 1.0)) / p.w - pow(abs(4.8), float(1-10)));

    return dist;
}

float try2(vec3 pos){

    // converting to 3d
    vec4 p = vec4(pos,1);
    vec4 p0 = p;

    float defaultScale = 2.8;

    vec4 scale = (vec4(defaultScale, defaultScale, defaultScale, abs(defaultScale)) / minRad2);

    for (int i = 0; i < 9; i++)
    {
        p.xyz = clamp(p.xyz, -3.0, 2.0) * 2.0 - p.xyz;
        p.xyz = rotateX(animate*0.1) * p.xyz;

        float r2 = dot(p.xyz, p.xyz);
        p *= clamp(max(minRad2/r2, minRad2), 0.0, 1.0);

        // scale, translate
        p = p*scale + p0;

    }
    return ((length(p.xyz) - abs(2.8 - 1.0)) / p.w - pow(abs(2.8), float(1-10)));
}

float try(vec3 pos){

    // converting to 3d
    vec4 p = vec4(pos,1);
    vec4 p0 = p;

    float defaultScale = 2.8;

    vec4 scale = (vec4(defaultScale, defaultScale, defaultScale, abs(defaultScale)) / minRad2);

    for (int i = 0; i < 9; i++)
    {
        p.xyz = clamp(p.xyz, -1.0, 1.0) * 2.0 - p.xyz;
        p.xyz = rotateX(animate*0.1) * p.xyz;
        p.xyz *= rotateZ(0.1*animate);

        float r2 = dot(p.xyz, p.xyz);
        p *= clamp(max(minRad2/r2, minRad2), 0.0, 1.0);

        // scale, translate
        p = p*scale + p0;

    }
    return ((length(p.xyz) - abs(2.8 - 1.0)) / p.w - pow(abs(2.8), float(1-10)));
}

float pyramids(vec3 z){

    // define parameters
    float scale = 2;
    float offset = 3;
    float r;

    int n = 0;
    int iterations = 10;

    for(int i = 0; i < iterations; i++) {

        if(z.x+z.y<0) z.xy = -z.yx; // fold 1
        if(z.x+z.z<0) z.xz = -z.zx; // fold 2
        if(z.y+z.z<0) z.zy = -z.yz; // fold 3

        z = z * scale - offset * (scale - 1.0);

        z = z* rotateX(animate*0.05);
        z = z* rotateY(animate*0.05);
        z = z* rotateZ(animate*0.05);
    }


    return (length(z) ) * pow(scale, -float(iterations));
}

// julia based on iq's implementation
float julia(vec3 p){

    // c parameter
    vec4 c = 0.5*vec4(cos(animate),cos(animate*1.1),cos(animate*2.3),cos(animate*3.1));

    // zeta variable
    vec4 zeta = vec4( p, 0.0 );

    // scale factor
    float md2 = 1.0;
    // scale step
    float mz2 = dot(zeta, zeta);

    for(int i=0;i<JUL_REPETITIONS;i++)
    {
        // scaling
        md2 *= 4.0 * mz2;

        // new zeta
        zeta = quaternionSquare(zeta) + c;

        // new scale step
        mz2 = quaternionLength(zeta);

        if(mz2>4.0)
        {
            break;
        }
    }

    return 0.25*sqrt(mz2/md2)*log(mz2);
}

float cross(vec3 p){

    float da = roundbox(p, MS_SCALE, MS_RADIUS);
    float db = roundbox(p, MS_SCALE, MS_RADIUS);
    float dc = roundbox(p, MS_SCALE, MS_RADIUS);

    return min(da,min(db,dc));
}

float mengerSponge(vec3 p){

    float d;

    // distance from base box
    if(mode == MENGER_CUBE_MODE){
        d = roundbox(p, MS_SCALE*8, MS_RADIUS);
    }
    if(mode == MENGER_OCTAHEDRON_MODE)
        d = octahedron(p);
    float s = sin(animate*0.01);

    for(int i = 0; i < MS_REPETITIONS; i++){

        float slowdown = 0.01;

        // transformation of the fractal
        p = p * rotateX(animate * slowdown);
        p = p * rotateY(animate * slowdown);
        p = p * rotateZ(animate * slowdown);
        p.xyz = p.xzy;

        p = p + translate(animate * slowdown, animate * slowdown, animate * slowdown);

        vec3 a = mod( p * s, 2.0 )-1.0;

        // scaling
        s *= MS_ITERATIONS;


        vec3 r = abs(2.0 - 3.0*abs(a));

        // derive the new coordinate
        float da = max(r.x,r.y);
        float db = max(r.y,r.z);
        float dc = max(r.z,r.x);

        //
        float c = (min(da,min(db,dc))-1.0)/s;

        d = max(d,c);
    }

    return d;
}

/*
SDF of the mandelbulb fractals
Computes the distance from a point to the closest
*/
float mandelbulb (vec3 p) {

    // zeta variable to be computed
    vec3 zeta = p;
    //derivative of the mandelbulb
    float dr = 1.0;
    // current distance from the origin
    float r = 0.0;

    float mbIterations = mod(animate, 20) + MB_ITERATIONS;

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
        zeta = zr * vec3 (x,y,z) * rotateY(animate) * rotateZ(animate * 0.5);
        // march over the position
        zeta += p;
    }

    // estimating the distance with Douady-Hubbard Potential(
    float dst = 0.5 * log (r) * r / dr;

    // current distance from ray
    return dst;
}

/*
Computes the distance from a point to a plane
p: point of the ray -> vec3
n: normal of the plane(normalized) -> vec3
*/
float floorPlane( vec3 p, vec3 n){
    return dot(p,n) + 0.75;
}

//-----------------
// rendering logic

/*
Returns the closest distance from a point
Distance will be determined by the current mode
p: point -> vec3
*/
float map(vec3 p){

    // we first make all the transofrmation we wish to do
    // rotations, translations, scaling, mod repeat...

    EPSILON = 0.001;

    if(repeat == 1){
        if(MOD_X)
            modAxis(p.x, MOD_SCALE_X);
        if(MOD_Z)
            modAxis(p.z, MOD_SCALE_Z);
        if(MOD_Y)
            modAxis(p.y, MOD_SCALE_Y);
    }

    float offset = animate * 0.1;
    mat3 rotateZ = rotateZ(offset);

    p = p * rotateZ;

    mat3 rotateY = rotateY(offset);

    p = p * rotateY;

    // current smallest distance
    float d = INFINITY;

//    if(mode == SPHERE_MODE)
//        d = sphere(p, 0.75 );

    if(mode == MANDELBULB_MODE){
        EPSILON = 0.0007;
        d = mandelbulb(p);
    }

    if(mode == MENGER_CUBE_MODE ||
       mode == MENGER_OCTAHEDRON_MODE){

        if(mode == MENGER_OCTAHEDRON_MODE){
            MOD_SCALE_X = 5;
            MOD_SCALE_Y = 5;
            MOD_SCALE_Z = 5;
            MOD_X = true;
            MOD_Y = true;
            MOD_Z = true;
        }
        EPSILON = 0.001;
        d = mengerSponge(p);
    }

    if(mode == PYRAMID_MODE){
        EPSILON = 0.01;
        MOD_SCALE_X = 20;
        MOD_SCALE_Y = 20;
        MOD_SCALE_Z = 20;
        d = pyramids(p);
    }

    if(mode == 5){
        EPSILON = 0.01;
        d = try(p);
    }

    if(mode == 6){
        EPSILON = 0.01;
        d = try2(p);
    }

    if(mode == 7){

        EPSILON = 0.01;
        d = try3(p);
    }

    if(mode == 8){
        MOD_Z = false;
        MOD_SCALE_X = 20;
        MOD_SCALE_Y = MOD_SCALE_X;
        EPSILON = 0.0001;
        d = soapBlob(p);
    }

    if(mode == 9){
        d = arnoFractal(p);
    }

    if(mode == 0){
        d = arnoFractal2(p);
//        d = sphere(p,1);
    }

    return d;
}

/*
From a ray origin and direction, it checks if that ray intersects with a geometry
ro: ray origin -> vec3
rd: ray direction -> vec3
*/
bool raymarching(vec3 ro, vec3 rd, out vec3 p, out float d){

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
        d = map(p);

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

// not working
vec3 juliaNormal(vec3 p){

    vec4 z = vec4(p,0.0);

    vec4 c = 0.5*vec4(cos(animate),cos(animate*1.1),cos(animate*2.3),cos(animate*3.1));

    // identity derivative
    mat4x4 J = mat4x4(1,0,0,0,
    0,1,0,0,
    0,0,1,0,
    0,0,0,1 );

    for(int i=0; i<JUL_REPETITIONS; i++)
    {
        // chain rule of jacobians (removed the 2 factor)
        J = J*mat4x4(z.x, -z.y, -z.z, -z.w,
        z.y,  z.x,  0.0,  0.0,
        z.z,  0.0,  z.x,  0.0,
        z.w,  0.0,  0.0,  z.x);

        // z -> z2 + c
        z = quaternionSquare(z) + c;

        if(quaternionLength(z)>4.0) break;
    }

    return normalize( (J*z).xyz );

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
    vec3 rd = normalize(cameraLookat +
                        cameraRight * fragPosition.x * aspectRatio +
                        cameraUp * fragPosition.y);

    vec3 p; // point of intersection

    float d; // distance from ray origin

    // check if there is an interesection woth geometry
    bool intersection = raymarching(ro, rd, p, d);

    // check if there is an intersection
    if(intersection){
        // color of the point

        // computing the normal of the point
        vec3 normal = getNormal(p);

        // direction of the light
        vec3 lightDirection = getLightDirection(p);

        color = shading(p, normal, lightDirection, color) * color;

        color = softShadow(p, lightDirection) * color;

        color = ambientOcclusion(p, normal) * color;

        float px = 1.0*(2.0/resolution.y)*(1.0/3.5);

        color *= clamp(1.0-0.1*length(p),0.2,1.0);

        color = mix( color, smoothstep( 0.0, 1.0, color ), 0.5 );

        color += 0.15;

    }
    else{
        // TODO define default BG color
        color = vec3(0.1,0.1,0.1);
    }

    return color;

}

void main(){

    // color of the pixel
    vec3 color = mainColor;

    // render the color of the pixel
    color = render(fragPosition, color);


    outColor = vec4(color, 1);
}