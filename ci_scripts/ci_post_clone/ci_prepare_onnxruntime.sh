#!/bin/zsh

set -e

apiURL=https://api.github.com/repos/lucka-me/michina-swift/actions/artifacts

buildDirectory=$CI_PRIMARY_REPOSITORY_PATH/ONNXRuntime/onnxruntime/build
if [ ! -d $buildDirectory ]
then
    mkdir -p $buildDirectory
fi

echo 'Fetching XCFramework'
curl -s -S -L $apiURL/8286253409/zip                                    \
    -H "Authorization: Bearer $GITHUB_ACTIONS_ARTIFACTS_DOWNLOAD_TOKEN" \
    | aa extract -d $buildDirectory
