#!/bin/zsh

set -e

sourceDirectory=$(realpath $(dirname $0))

source $sourceDirectory/ci_env.sh

scriptsPath=$sourceDirectory/ci_post_clone

$scriptsPath/ci_prepare_onnxruntime.sh
$scriptsPath/ci_prepare_magearna.sh
$scriptsPath/ci_prepare_tokenizers.sh
$scriptsPath/ci_setup_security.sh
