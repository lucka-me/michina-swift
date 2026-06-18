#!/bin/zsh

set -e

sourceDirectory=$(realpath $(dirname $0))

source $sourceDirectory/ci_env.sh

scriptsPath=$sourceDirectory/ci_post_clone

$scriptsPath/ci_build_onnxruntime.sh
$scriptsPath/ci_build_tokenizers.sh
$scriptsPath/ci_setup_security.sh
