
#ifndef FRACTAL_GENERATOR_CAMERA_H
#define FRACTAL_GENERATOR_CAMERA_H

#include "init.h"


/*
 * We setup the camera attributes in here
 */

// origin of the camera -> Point
vec3 cameraOrigin = vec3(0, 0, 0);

// lookat direction of the camera -> vector
vec3 cameraLookat = normalize(vec3(0,0,-1));

// up direction of the camera -> vector
vec3 cameraUp = normalize(vec3(0,1,0));

// right direction of the camera -> vector
vec3 cameraRight = normalize(cross(cameraUp, cameraLookat));

// field of view -> degrees
float fov = 1.0f;

mat4 view = lookAt(cameraOrigin,
                   cameraLookat,
                   cameraUp);

#endif //FRACTAL_GENERATOR_CAMERA_H
