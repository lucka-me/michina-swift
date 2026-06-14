#!/bin/zsh

set -e

# NOTICE: The CI_TEAM_ID is an UUID instead of the real ID
# if [ ! -z $CI_TEAM_ID ]
# then
#     export SIGNING_TEAM_ID=$CI_TEAM_ID
# fi

if [ -z $BUILD_CONFIG ]
then
    export BUILD_CONFIG=Release
fi

repositoryPath=$(realpath $(dirname $0)/..)

onnxruntimeBuildOutputPath=$repositoryPath/ONNXRuntime/onnxruntime/build/$BUILD_CONFIG/$BUILD_CONFIG
onnxruntimeBuildXCFrameworkPath=$onnxruntimeBuildOutputPath/onnxruntime.xcframework

# Restore framework from cached derived data
if [ ! -z $CI_DERIVED_DATA_PATH ]
then
    echo "Derived Data available in $CI_DERIVED_DATA_PATH"
    derivedDataCachePath=$CI_DERIVED_DATA_PATH/Cache
    onnxruntimeXCFrameworkCachePath=$derivedDataCachePath/onnxruntime.xcframework
    if [ -d $onnxruntimeXCFrameworkCachePath ]
    then
        echo "Cached onnxruntime framework available in $onnxruntimeXCFrameworkCachePath"
        mkdir -p $onnxruntimeBuildOutputPath
        cp -r $onnxruntimeXCFrameworkCachePath $onnxruntimeBuildOutputPath
    fi
fi

# Build onnxruntime framework
if [ ! -d $onnxruntimeBuildXCFrameworkPath ]
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

    # Copy the built XCFramework to derived data, expected to be cached by Xcode cloud.
    if [ ! -z $derivedDataCachePath ]
    then
        echo "Copying onnxruntime framework to $derivedDataCachePath for caching"
        mkdir -p $derivedDataCachePath
        cp -r $onnxruntimeBuildXCFrameworkPath $derivedDataCachePath
    fi
fi

# Trust the SwiftProtobuf plugin
swiftPMSecurityPath=~/Library/org.swift.swiftpm/security
mkdir -p $swiftPMSecurityPath
cp $repositoryPath/ci_scripts/Security/plugins.json $swiftPMSecurityPath
