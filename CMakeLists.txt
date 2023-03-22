cmake_minimum_required(VERSION 3.24)
project(fractal_generator)

set(CMAKE_CXX_STANDARD 14)

set(CMAKE_PREFIX_PATH opt/homebrew/include)

include_directories(/opt/homebrew/include/)

# open gl include
find_package(OpenGL REQUIRED COMPONENTS OpenGL)

# glew include
find_package(GLEW REQUIRED)

# glfw include
find_package(glfw3 REQUIRED)

# glm include
find_package(glm REQUIRED)

add_executable(${PROJECT_NAME} main.cpp)

target_link_libraries(${PROJECT_NAME} OpenGL::GL GLEW::glew glfw)
