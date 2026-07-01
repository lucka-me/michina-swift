# Michina

<picture>
    <source srcset="./docs/static/images/app-icon-dark.png 2x" media="(prefers-color-scheme: dark)" />
    <source srcset="./docs/static/images/app-icon-light.png 2x" media="(prefers-color-scheme: light)" />
    <img src="./docs/static/images/app-icon-light.png" />
</picture>

Immich Machine Learning Server on macOS.

[Join TestFlight](https://testflight.apple.com/join/rJP9acvk).

## ⚠️ Disclaimer

This project is still under development. **Use AT YOUR OWN RISK, and do not forget to BACKUP your database before
running massive machine learning jobs on your Immich instance with Michina.**

Because of the differences in image processing ecosystem between of Swift (Core Image, Core Graphic, vImage...) and
Python (Pillow, OpenCV, NumPy...), Machina doesn't always behave exactly the same as the original official
implementation does, which may lead to slight differences in the outputs.  
But these differences are expected to be toleratable, like the facial recognition embedding being different but still
close enough to be classified as the same person.

## Glance

In a nutshell, Michina is a Swift implementation of
[immich/machine_learning](https://github.com/immich-app/immich/tree/main/machine-learning), with a GUI, for macOS.

## Packages

This Xcode Workspace contains following local packages, READMEs are available.

- [Magearna](./Magearna): Core component of Michina, provides basic inference features.
- [ONNXRuntime](./ONNXRuntime): The fundamental library to run models.
- [Tokenizers](./Tokenizers): Tokenize text for Textual Smart Search, bridged from Rust.

## Build

Binary targets `onnxruntime.xcframework` and `tokenizers.xcframework` should be built before resolving dependencies,
please check the README.md in [ONNXRuntime](./ONNXRuntime) and [Tokenizers](./Tokenizers) for details of building.
