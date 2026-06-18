#!/bin/zsh

set -e

# NOTICE: The CI_TEAM_ID is an UUID instead of the real ID
# if [ ! -z $CI_TEAM_ID ]
# then
#     export SIGNING_TEAM_ID=$CI_TEAM_ID
# fi

ciScriptsPath=$(realpath $(dirname $0))

$ciScriptsPath/ci_build_onnxruntime.sh
$ciScriptsPath/ci_build_tokenizers.sh
$ciScriptsPath/ci_setup_security.sh
