#!/bin/zsh

set -e

buildDirectory=$CI_PRIMARY_REPOSITORY_PATH/ONNXRuntime/onnxruntime/build
if [ ! -d $buildDirectory ]
then
    mkdir -p $buildDirectory
fi

artifactURL=https://api.github.com/repos/lucka-me/michina-swift/actions/artifacts/8282040286/aar

curl -s -S -L $artifactURL                                              \
    -H "Authorization: Bearer $GITHUB_ACTIONS_ARTIFACTS_DOWNLOAD_TOKEN" \
    | aa extract -d $buildDirectory
