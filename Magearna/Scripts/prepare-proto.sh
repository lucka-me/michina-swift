#!/bin/sh

set -e

repositoryPath=$(realpath $(dirname $0)/../../)

sed 's/^package onnx;$/package onnx;\noption swift_prefix = "ONNX";/'                               \
    $repositoryPath/ONNXRuntime/Frameworks/onnxruntime/source/cmake/external/onnx/onnx/onnx.proto3  \
    > $repositoryPath/Magearna/Sources/Magearna/Utilities/ONNX/Protobuf/Definitions/ONNX.proto
