# Swift Package Manager for ONNX Runtime

This package is a modified version of
[microsoft/onnxruntime-swift-package-manager](https://github.com/microsoft/onnxruntime-swift-package-manager).

We have made some minor fixes on ONNXRuntime for running models with Core ML Execution Provider, but these changes are
[not merged to the main branch yet](https://github.com/microsoft/onnxruntime/pull/28702), so we include the modified
repository as a submodule in the package, and [a script](Scripts/build-onnxruntime.sh) is provided to build
the XCFramework from source.

## Preprocess

Before resolving the package, the `onnxruntime.xcframework` should be built.

Building ONNXRuntime requires Python 3.10+ and CMake, they will be used as building tools. It's recommended to install
them with Homebrew:

```shell
brew install python3
brew install cmake
```

Then use the script to build the onnxruntime and generate XCFramework:

```shell
./Scripts/build-onnxruntime.sh
```