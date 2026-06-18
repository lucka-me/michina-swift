#!/bin/zsh

set -e

packagePath=$CI_PRIMARY_REPOSITORY_PATH/Tokenizers

echo 'Installing Rust'
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --target aarch64-apple-darwin

echo 'Installing cxxbridge-cmd'
cargo install cxxbridge-cmd

echo 'Building tokenizers framework'
$packagePath/Scripts/build_tokenizers.sh
