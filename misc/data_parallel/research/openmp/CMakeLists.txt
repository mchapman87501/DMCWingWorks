project(data_parallel)

cmake_minimum_required(VERSION 3.19)

set(CXX_STANDARD_REQUIRED ON)
set(CXX_STANDARD 17)
set(CXX_EXTENSIONS ON)

add_compile_options(-Wall -fopenmp)
add_link_options(-fopenmp)

# How to target a GPU?  My iMac has an AMD Radeon R9 M390.
# https://releases.llvm.org/8.0.1/docs/AMDGPUUsage.html
# https://clang.llvm.org/docs/OpenMPSupport.html
#   "Clang supports offloading to X86_64, AArch64, PPC64[LE] and
#    has basic support for Cuda devices."

include_directories(src/include)

add_library(wingworks
    src/lib/bbox.cpp
    src/lib/point.cpp
    src/lib/particle.cpp
    src/lib/segment.cpp
    src/lib/polygon.cpp
    src/lib/dot_min_max.cpp
    src/lib/sat_poly_collision.cpp
    src/lib/airfoil.cpp
    src/lib/airfoil_collision.cpp
    src/lib/world_cells.cpp
    src/lib/world.cpp)

add_executable(demo src/demo.cpp)
target_link_libraries(demo wingworks)

# Add the tests.
enable_testing()
add_subdirectory(tests)

