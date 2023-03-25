
#ifndef FRACTAL_GENERATOR_CAMERA_H
#define FRACTAL_GENERATOR_CAMERA_H

#include "init.h"


/*
 * We setup the camera attributes in here
 */

// origin of the camera -> Point
vec3 cameraOrigin = vec3(0, 0.2, 2);

// lookat direction of the camera -> vector
vec3 cameraLookat = normalize(vec3(0,0,-1));

// up direction of the camera -> vector
vec3 cameraUp = vec3(0,1,0);

// right direction of the camera -> vector
vec3 cameraRight = vec3(1,0,0);

// field of view -> degrees
float fov = 1.2;

mat4 view = lookAt(cameraOrigin,
                   cameraLookat,
                   cameraUp);

#endif //FRACTAL_GENERATOR_CAMERA_H
