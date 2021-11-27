#!/bin/bash

set -e -u

# Follows advice from `brew install llvm libomp`
export LDFLAGS="-L/usr/local/opt/llvm/lib -Wl,-rpath,/usr/local/opt/llvm/lib"
export PATH="/usr/local/opt/llvm/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/llvm/lib"
export CPPFLAGS="-I/usr/local/opt/llvm/include"
export CXX=/usr/local/opt/llvm/bin/clang++

# brew g++:
# export PATH="/usr/local/bin:$PATH"
# export CC=/usr/local/bin/gcc-10
# export CXX=/usr/local/bin/g++-10

rm -rf build
mkdir build
cd build
cmake ..

cmake --build . --target demo

demo_path=${PWD}/demo

cd ..
rm -rf example_output/data/out
mkdir -p example_output/data/out
cd example_output/data/out
time ${demo_path}

cd ../../../
python display_results.py
open movie.mp4
