# Swift Package Manager for ONNX Runtime

This package is a modified version of
[microsoft/onnxruntime-swift-package-manager](https://github.com/microsoft/onnxruntime-swift-package-manager).

We have made some minor fixes on ONNXRuntime for running models with Core ML Execution Provider, but these changes are
[not released yet](https://github.com/microsoft/onnxruntime/pull/29394), so we include the modified repository as a
submodule in the package, and [a script](Frameworks/onnxruntime/build.sh) is provided to build the XCFramework from
source.

## Preprocess

One of the target in this package requires `onnxruntime.xcframework` , which is built from source in
[onnxruntime](./Frameworks/onnxruntime/source).

Python 3.10+ and CMake are used as building tools. It's recommended to install them with Homebrew:

```shell
brew install python3
brew install cmake
```

Then run the script to build the onnxruntime for both `arm64` and `x86_64`, and generate universal XCFramework:

```shell
./Frameworks/onnxruntime/build.sh
```
