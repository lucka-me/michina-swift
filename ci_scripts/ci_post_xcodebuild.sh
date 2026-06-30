#!/bin/zsh

set -e

ls -R $CI_DERIVED_DATA_PATH

sourceDirectory=$(realpath $(dirname $0))

source $sourceDirectory/ci_env.sh

scriptsPath=$sourceDirectory/ci_post_xcodebuild

$scriptsPath/cache_onnxruntime.sh
