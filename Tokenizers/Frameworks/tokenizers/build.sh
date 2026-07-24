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

export MACOSX_DEPLOYMENT_TARGET=15.0

sourcePath=$currentDirectory/source
cd $sourcePath && $CARGO_EXECUTABLE build --release

packageTargetPath=$currentDirectory/../../Sources/Tokenizers
$CXXBRIDGE_EXECUTABLE --header -o $packageTargetPath/bridge.rs.h
$CXXBRIDGE_EXECUTABLE $sourcePath/src/lib.rs --header -o $packageTargetPath/tokenizers-bridge.rs.h
$CXXBRIDGE_EXECUTABLE $sourcePath/src/lib.rs -o $packageTargetPath/tokenizers-bridge.rs.cc

buildTargetPath=$sourcePath/target

xcframeworkPath=$currentDirectory/tokenizers.xcframework
if [ -d $xcframeworkPath ]
then
    rm -r $xcframeworkPath
fi

xcodebuild -create-xcframework                                              \
    -library $buildTargetPath/aarch64-apple-darwin/release/libtokenizers.a  \
    -output $xcframeworkPath
