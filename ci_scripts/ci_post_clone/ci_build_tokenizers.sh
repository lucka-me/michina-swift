#!/bin/zsh

set -e

packagePath=$CI_PRIMARY_REPOSITORY_PATH/Tokenizers

if [ $CI_XCODE_CLOUD = 'TRUE' ]
then
    echo 'Installing Rust'
    brew install -q rust

    echo 'Installing cxxbridge-cmd'
    cargo install cxxbridge-cmd
fi

echo 'Building tokenizers framework'
$packagePath/Scripts/build_tokenizers.sh
