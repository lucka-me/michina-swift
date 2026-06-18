#!/bin/zsh

set -e

packagePath=$CI_PRIMARY_REPOSITORY_PATH/ONNXRuntime

xcFrameworkPath=$packagePath/onnxruntime/build/$ORT_BUILD_CONFIG/$ORT_BUILD_CONFIG/onnxruntime.xcframework
derivedDataCachePath=$CI_DERIVED_DATA_PATH/Cache

echo "Copying onnxruntime framework to $derivedDataCachePath for caching"
mkdir -p $derivedDataCachePath
cp -r $xcFrameworkPath $derivedDataCachePath
