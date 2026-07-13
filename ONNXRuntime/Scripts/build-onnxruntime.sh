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
cmakeExtraDefines=()
if [ $ORT_BUILD_CONFIG = 'Debug' ]
then
    cmakeExtraDefines+=(CMAKE_XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT='dwarf')
    cmakeExtraDefines+=(CMAKE_XCODE_ATTRIBUTE_GCC_GENERATE_DEBUGGING_SYMBOLS='YES')
fi

projectPath=$(realpath $(dirname $0)/../onnxruntime)

buildPath=$projectPath/build

if [ ! -f $buildPath/$ORT_BUILD_CONFIG/CMakeCache.txt ] || [ ! -z ORT_UPDATE_CMAKE ]
then
    buildArguments+=(--update)
fi

cd $projectPath && $PYTHON_EXECUTABLE               \
    $projectPath/tools/ci_build/build.py            \
    --build_dir $buildPath                          \
    --config $ORT_BUILD_CONFIG                      \
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
        ${cmakeExtraDefines[@]}                     \
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

xcframeworkPath=$buildPath/onnxruntime.xcframework
if [ -d $xcframeworkPath ]
then
    rm -r $xcframeworkPath
fi

xcrun xcodebuild -create-xcframework                                                \
    -framework $buildPath/$ORT_BUILD_CONFIG/$ORT_BUILD_CONFIG/onnxruntime.framework \
    -output $xcframeworkPath
