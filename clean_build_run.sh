#!/bin/bash
set -e -u

rm -rf .build

swift build -c release
time .build/release/DMCWingWorksSim

open movie.mov
