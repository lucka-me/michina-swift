#!/bin/sh

set -e

if [ -z $CARGO_EXECUTABLE ]
then
    CARGO_EXECUTABLE=$(which cargo)
fi

if [ -z $CXXBRIDGE_EXECUTABLE ]
then
    CXXBRIDGE_EXECUTABLE=$(dirname $CARGO_EXECUTABLE)/cxxbridge
fi

if [ -z $MACOSX_DEPLOYMENT_TARGET ]
then
    export MACOSX_DEPLOYMENT_TARGET=26.0
fi

packagePath=$(realpath $(dirname $0)/..)

rustPath=$packagePath/Rust

cd $rustPath && $CARGO_EXECUTABLE build --release

targetPath=$packagePath/Sources/Tokenizers

if [ ! -f $targetPath/bridge.rs.h ]
then
    $CXXBRIDGE_EXECUTABLE --header -o $targetPath/bridge.rs.h
fi
$CXXBRIDGE_EXECUTABLE $rustPath/src/lib.rs --header -o $targetPath/tokenizers-bridge.rs.h
$CXXBRIDGE_EXECUTABLE $rustPath/src/lib.rs -o $targetPath/tokenizers-bridge.rs.cc

rustTargetPath=$rustPath/target

xcframeworkPath=$rustTargetPath/tokenizers.xcframework
if [ -d $xcframeworkPath ]
then
    rm -r $xcframeworkPath
fi

xcodebuild -create-xcframework                                              \
    -library $rustTargetPath/aarch64-apple-darwin/release/libtokenizers.a   \
    -output $xcframeworkPath
