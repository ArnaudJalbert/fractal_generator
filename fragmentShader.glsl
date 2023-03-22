#version 330 core

#define MAX_RAYMARCH_STEPS 256
#define EPSILON 0.00001f
#define MAX_DISTANCE 150
#define INFINITY 999999999
#define NORMAL_OFFSET vec2(EPSILON, 0)

smooth in vec3 fragPosition; // position of the fragment
out vec4 outColor;

uniform vec2 resolution;
uniform float aspectRatio;
uniform vec3 cameraOrigin;
uniform vec3 cameraLookat;
uniform vec3 cameraUp;
uniform vec3 cameraRight;
uniform float fov;



/*
Computes the distance from a point to a sphere
p: point of the ray -> vec3
r: radius of the sphere -> float
*/
float sphere(vec3 p, float r){
    return length(p)-r;
}

/*
Returns the closest distance from a point
p: point -> vec3
*/
float map(vec3 p){

    // current smallest distance
    float d = INFINITY;

    d = sphere(p - vec3(0,0,-1.5), 1);

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
vec3 normal(in vec3 p){

    vec3 normal = vec3(map(p+NORMAL_OFFSET.xyy) - map(p-NORMAL_OFFSET.xyy),
                  map(p+NORMAL_OFFSET.yxy) - map(p-NORMAL_OFFSET.yxy),
                  map(p+NORMAL_OFFSET.yyx) - map(p-NORMAL_OFFSET.yyx)
                  );

    return normalize(normal);
}

/*
From uv and the set geometry, it renders the color of the fragment
uv: xy position of the current
*/
void render(in vec3 fragPosition, out vec3 color){

    // origin of the ray
    vec3 ro = cameraOrigin;
    // direction of the ray
    vec3 rd = normalize(cameraLookat * fov +
                        cameraRight * fragPosition.x * aspectRatio +
                        cameraUp * fragPosition.y);

    vec3 p; // point of intersection

    bool intersection = raymarching(ro, rd, p);

    // check if there is an intersection
    if(intersection){
        // TODO calculate the shading with the information
        // computing the normal of the point
        vec3 normal = normal(p);

        color = vec3(normal);
    }
    else{
        // TODO define default BG color
        color = vec3(0.1,0.5,0.1);
    }

}

void main(){

    // color of the pixel
    vec3 color;

    // render the color of the pixel
    render(fragPosition, color);

    outColor = vec4(color, 1);
}