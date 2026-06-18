#!/bin/sh

set -e

if [ -z $PYTHON_EXECUTABLE ]
then
    PYTHON_EXECUTABLE=$(which python3)
fi
echo "Use Python from $PYTHON_EXECUTABLE"

if [ -z $ORT_BUILD_CONFIG ]
then
    ORT_BUILD_CONFIG=Release
fi

buildArguments=()
if [ ! -z $SIGNING_TEAM_ID ]
then
    buildArguments+=(--xcode_code_signing_team_id $SIGNING_TEAM_ID)
fi
if [ ! -z $SIGNING_IDENTITY ]
then
    buildArguments+=(--xcode_code_signing_identity $SIGNING_IDENTITY)
fi

repositoryPath=$(realpath $(dirname $0)/../onnxruntime)

cd $repositoryPath

buildPath=$repositoryPath/build

$PYTHON_EXECUTABLE                                  \
    $repositoryPath/tools/ci_build/build.py         \
    --build_dir $buildPath                          \
    --config $ORT_BUILD_CONFIG                      \
    --update                                        \
    --build                                         \
    --parallel                                      \
    --compile_no_warning_as_error                   \
    --build_shared_lib                              \
    --build_apple_framework                         \
    --enable_lto                                    \
    --cmake_extra_defines                           \
        CMAKE_POLICY_VERSION_MINIMUM=3.5            \
        FETCHCONTENT_TRY_FIND_PACKAGE_MODE=NEVER    \
        onnxruntime_BUILD_UNIT_TESTS=OFF            \
    --skip_tests                                    \
    --macos MacOSX                                  \
    --apple_sysroot macosx                          \
    --use_xcode                                     \
    --osx_arch arm64                                \
    --apple_deploy_target 26.0                      \
    --build_objc                                    \
    --enable_arm_neon_nchwc                         \
    --use_coreml                                    \
    ${buildArguments[@]}

buildOutputPath=$buildPath/$ORT_BUILD_CONFIG/$ORT_BUILD_CONFIG

xcframeworkPath=$buildOutputPath/onnxruntime.xcframework
if [ -d $xcframeworkPath ]
then
    rm -r $xcframeworkPath
fi

xcrun xcodebuild -create-xcframework                    \
    -framework $buildOutputPath/onnxruntime.framework   \
    -output $xcframeworkPath

if [ ! -z $SIGNING_IDENTITY ]
then
    xcrun codesign --timestamp --sign $SIGNING_IDENTITY \
        $xcframeworkPath
fi