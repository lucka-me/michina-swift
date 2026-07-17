#!/bin/sh

set -e

currentDirectory=$(realpath $(dirname $0))

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

sourcePath=$currentDirectory/source
cd $sourcePath && $CARGO_EXECUTABLE build --release

targetPath=$currentDirectory/../../Sources/Tokenizers
$CXXBRIDGE_EXECUTABLE --header -o $targetPath/bridge.rs.h
$CXXBRIDGE_EXECUTABLE $sourcePath/src/lib.rs --header -o $targetPath/tokenizers-bridge.rs.h
$CXXBRIDGE_EXECUTABLE $sourcePath/src/lib.rs -o $targetPath/tokenizers-bridge.rs.cc

xcframeworkPath=$currentDirectory/tokenizers.xcframework
if [ -d $xcframeworkPath ]
then
    rm -r $xcframeworkPath
fi

xcodebuild -create-xcframework                                                  \
    -library $sourcePath/target/aarch64-apple-darwin/release/libtokenizers.a    \
    -output $xcframeworkPath
