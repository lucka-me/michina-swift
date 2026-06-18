#!/bin/zsh

set -e

packagePath=$CI_PRIMARY_REPOSITORY_PATH/ONNXRuntime

xcFrameworkCachePath=$CI_DERIVED_DATA_PATH/Cache/onnxruntime.xcframework
if [ -d $xcFrameworkCachePath ]
then
    # Restore onnxruntime framework from cached derived data
    echo "Cached onnxruntime framework available in $xcFrameworkCachePath"

    buildOutputPath=$packagePath/onnxruntime/build/$ORT_BUILD_CONFIG/$ORT_BUILD_CONFIG

    mkdir -p $buildOutputPath
    cp -r $xcFrameworkCachePath $buildOutputPath
else
    # Build onnxruntime framework
    echo 'Installing CMake'
    brew install -q cmake

    echo 'Installing Python'
    brew install -q python3

    export PYTHON_EXECUTABLE=$(brew --prefix python3)/libexec/bin/python

    echo 'Building onnxruntime framework'
    $packagePath/Scripts/build-onnxruntime.sh
fi
