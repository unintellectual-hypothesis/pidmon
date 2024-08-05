cmake_minimum_required(VERSION 3.16.3)
project(pidmon CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(SOURCE_DIR "${CMAKE_SOURCE_DIR}/src")
set(INCLUDE_DIRECTORIES "${CMAKE_SOURCE_DIR}/include")

include_directories(${INCLUDE_DIRECTORIES})

add_executable(pidmon ${SOURCE_DIR})

set(CMAKE_BUILD_TYPE Release)

set(CMAKE_CXX_FLAGS "-Wall -Wextra")

set(CMAKE_CXX_FLAGS_DEBUG "-g")
set(CMAKE_CXX_FLAGS_RELEASE "-O2")

set_target_properties(pidmon PROPERTIES INTERPROCEDURAL_OPTIMIZATION TRUE)

install(TARGETS pidmon DESTINATION bin)