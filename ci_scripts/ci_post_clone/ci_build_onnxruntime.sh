#!/bin/zsh

set -e

packagePath=$CI_PRIMARY_REPOSITORY_PATH/ONNXRuntime

# Build onnxruntime framework
echo 'Installing CMake'
brew install -q cmake

echo 'Installing Python'
brew install -q python3

export PYTHON_EXECUTABLE=$(brew --prefix python3)/libexec/bin/python

echo 'Building onnxruntime framework'
$packagePath/Scripts/build-onnxruntime.sh

# Copy the ONNX.proto file to Magearna
$CI_PRIMARY_REPOSITORY_PATH/Magearna/Scripts/prepare-proto.sh
