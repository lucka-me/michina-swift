#!/bin/zsh

set -e

export BUILD_CONFIG=Release

repositoryPath=$(realpath $(dirname $0)/..)

buildOutputPath=$repositoryPath/ONNXRuntime/onnxruntime/build/$BUILD_CONFIG/$BUILD_CONFIG

# Restore onnxruntime framework from cached derived data
if [ ! -z $CI_DERIVED_DATA_PATH ]
then
    echo "Derived Data available in $CI_DERIVED_DATA_PATH"
    xcFrameworkCachePath=$CI_DERIVED_DATA_PATH/Cache/onnxruntime.xcframework
    if [ -d $xcFrameworkCachePath ]
    then
        echo "Cached onnxruntime framework available in $xcFrameworkCachePath"
        mkdir -p $buildOutputPath
        cp -r $xcFrameworkCachePath $buildOutputPath
    fi
fi

# Build onnxruntime framework
if [ ! -d $buildOutputPath/onnxruntime.xcframework ]
then
    if [ $CI_XCODE_CLOUD = 'TRUE' ]
    then
        echo 'Installing CMake'
        brew install -q cmake

        echo 'Installing Python'
        brew install -q python3

        export PYTHON_EXECUTABLE=$(brew --prefix python3)/libexec/bin/python
    fi

    echo 'Building onnxruntime framework'
    $repositoryPath/ONNXRuntime/Scripts/build-onnxruntime.sh
fi
