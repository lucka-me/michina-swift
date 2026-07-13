#!/bin/zsh

set -e

# Copy the ONNX.proto file to Magearna
$CI_PRIMARY_REPOSITORY_PATH/Magearna/Scripts/prepare-proto.sh
