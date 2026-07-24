#!/bin/sh

set -e

currentDirectory=$(realpath $(dirname $0))

if [ -z $PYTHON_EXECUTABLE ]
then
    PYTHON_EXECUTABLE=$(which python3)
fi
echo "Use Python from $PYTHON_EXECUTABLE"

if [ -z $ORT_BUILD_CONFIG ]
then
    ORT_BUILD_CONFIG=Release
fi

cmakeExtraDefines=()
if [ $ORT_BUILD_CONFIG = 'Debug' ]
then
    cmakeExtraDefines+=(CMAKE_XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT='dwarf')
    cmakeExtraDefines+=(CMAKE_XCODE_ATTRIBUTE_GCC_GENERATE_DEBUGGING_SYMBOLS='YES')
fi

sourcePath=$currentDirectory/source

buildPath=$sourcePath/build
mkdir -p $buildPath

frameworkPaths=()
for arch in arm64 x86_64
do
    archBuildPath=$buildPath/$arch

    buildArguments=()
    if [ ! -f $archBuildPath/$ORT_BUILD_CONFIG/CMakeCache.txt ] || [ ! -z $ORT_UPDATE_CMAKE ]
    then
        buildArguments+=(--update)
    fi

    cd $sourcePath && $PYTHON_EXECUTABLE                \
        $sourcePath/tools/ci_build/build.py             \
        --build_dir $archBuildPath                      \
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
        --skip_submodule_sync                           \
        --skip_tests                                    \
        --macos MacOSX                                  \
        --apple_sysroot macosx                          \
        --use_xcode                                     \
        --osx_arch $arch                                \
        --apple_deploy_target 15.0                      \
        --build_objc                                    \
        --enable_arm_neon_nchwc                         \
        --use_coreml                                    \
        ${buildArguments[@]}

    frameworkPaths+=($archBuildPath/$ORT_BUILD_CONFIG/$ORT_BUILD_CONFIG/onnxruntime.framework)
done

universalFramework=$buildPath/onnxruntime.framework
if [ -d $universalFramework ]
then
    rm -r $universalFramework
fi

cp -R ${frameworkPaths[0]} $buildPath

frameworkBinaryPath=Versions/A/onnxruntime

lipoInputs=()
for path in ${frameworkPaths[@]}
do
    lipoInputs+=($path/$frameworkBinaryPath)
done
lipo ${lipoInputs[@]} -create -output $universalFramework/$frameworkBinaryPath

xcframeworkPath=$currentDirectory/onnxruntime.xcframework
if [ -d $xcframeworkPath ]
then
    rm -r $xcframeworkPath
fi
xcrun xcodebuild -create-xcframework -framework $universalFramework -output $xcframeworkPath
