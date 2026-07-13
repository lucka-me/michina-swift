#!/bin/zsh

set -e

targetPath=$CI_PRIMARY_REPOSITORY_PATH/Tokenizers/Rust/target
if [ ! -d $targetPath ]
then
    mkdir -p $targetPath
fi

artifactURL=https://api.github.com/repos/lucka-me/michina-swift/actions/artifacts/8281541814/zip
curl -s -S -L $artifactURL                                              \
    -H "Authorization: Bearer $GITHUB_ACTIONS_ARTIFACTS_DOWNLOAD_TOKEN" \
    | aa extract -d $targetPath
