#!/bin/zsh

set -e

repositoryPath=$(realpath $(dirname $0)/..)

if [ ! -z $CI_DERIVED_DATA_PATH ]
then
    xcFrameworkPath=$repositoryPath/ONNXRuntime/onnxruntime/build/Release/Release/onnxruntime.xcframework
    derivedDataCachePath=$CI_DERIVED_DATA_PATH/Cache

    echo "Copying onnxruntime framework to $derivedDataCachePath for caching"
    mkdir -p $derivedDataCachePath
    cp -r $xcFrameworkPath $derivedDataCachePath
fi
