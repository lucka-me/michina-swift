#!/bin/zsh

set -e

ls -R $CI_DERIVED_DATA_PATH

sourceDirectory=$(realpath $(dirname $0))

source $sourceDirectory/ci_env.sh

scriptsPath=$sourceDirectory/ci_post_clone

$scriptsPath/ci_build_onnxruntime.sh
$scriptsPath/ci_build_tokenizers.sh
$scriptsPath/ci_setup_security.sh
