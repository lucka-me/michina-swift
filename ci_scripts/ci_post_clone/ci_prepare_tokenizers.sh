#!/bin/zsh

set -e

apiURL=https://api.github.com/repos/lucka-me/michina-swift/actions/artifacts

packagePath=$CI_PRIMARY_REPOSITORY_PATH/Tokenizers

targetPath=$packagePath/Rust/target
if [ ! -d $targetPath ]
then
    mkdir -p $targetPath
fi

echo 'Fetching XCFramework'

curl -s -S -L $apiURL/8286269427/zip                                    \
    -H "Authorization: Bearer $GITHUB_ACTIONS_ARTIFACTS_DOWNLOAD_TOKEN" \
    | aa extract -d $targetPath

echo 'Fetching Generated Sources'
curl -s -S -L $apiURL/8286270043/zip                                    \
    -H "Authorization: Bearer $GITHUB_ACTIONS_ARTIFACTS_DOWNLOAD_TOKEN" \
    | aa extract -d $packagePath/Sources
