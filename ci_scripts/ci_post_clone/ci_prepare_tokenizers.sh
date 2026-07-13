#!/bin/zsh

set -e

packagePath=$CI_PRIMARY_REPOSITORY_PATH/Tokenizers

targetPath=$packagePath/Rust/target
if [ ! -d $targetPath ]
then
    mkdir -p $targetPath
fi

echo 'Fetching XCFramework'
artifactURL=https://api.github.com/repos/lucka-me/michina-swift/actions/artifacts/8281541814/zip
curl -s -S -L $artifactURL                                              \
    -H "Authorization: Bearer $GITHUB_ACTIONS_ARTIFACTS_DOWNLOAD_TOKEN" \
    | aa extract -d $targetPath

echo 'Fetching Generated Sources'
artifactURL=https://api.github.com/repos/lucka-me/michina-swift/actions/artifacts/8283814710/zip
curl -s -S -L $artifactURL                                              \
    -H "Authorization: Bearer $GITHUB_ACTIONS_ARTIFACTS_DOWNLOAD_TOKEN" \
    | aa extract -d $packagePath/Sources/Tokenizers
