#!/bin/zsh

set -e

repositoryPath=$(realpath $(dirname $0)/..)

if [ $CI_XCODE_CLOUD = 'TRUE' ]
then
    echo 'Installing Rust'
    brew install -q rust

    echo 'Installing cxxbridge-cmd'
    cargo install cxxbridge-cmd
fi

echo 'Building tokenizers framework'
$repositoryPath/Tokenizers/Scripts/build_tokenizers.sh
