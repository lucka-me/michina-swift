#!/bin/zsh

set -e

sourceDirectory=$(realpath $(dirname $0))

source $sourceDirectory/ci_env.sh

scriptsPath=$sourceDirectory/ci_post_xcodebuild

$scriptsPath/cache_onnxruntime.sh
