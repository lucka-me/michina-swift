# Michina

<picture>
    <source src="./Michina/Resources/Assets.xcassets/AppIconPreview/Default.imageset/Default-iOS-Dark-1024x1024@1x.png" media="(prefers-color-scheme: dark)"/>
    <source src="./Michina/Resources/Assets.xcassets/AppIconPreview/Default.imageset/Default-iOS-Default-1024x1024@1x.png" media="(prefers-color-scheme: light)"/>
    <img src="./Michina/Resources/Assets.xcassets/AppIconPreview/Default.imageset/Default-iOS-Default-1024x1024@1x.png" width="128">
</picture>

Immich Machine Learning Server on macOS.

Join TestFlight [here](https://testflight.apple.com/join/rJP9acvk).

## ⚠️ Disclaimer

This project is still under development, and most models are not verified yet. **Use AT YOUR OWN RISK, and do not forget
to BACKUP your database before running massive machine learning jobs on your Immich instance with Michina.**

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
