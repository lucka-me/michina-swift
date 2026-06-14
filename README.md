# Michina

<picture>
    <source src="./Michina/Resources/Assets.xcassets/AppIconPreview/Default.imageset/Default-iOS-Default-1024x1024@1x.png" media="(prefers-color-scheme: light)"/>
    <source src="./Michina/Resources/Assets.xcassets/AppIconPreview/Default.imageset/Default-iOS-Dark-1024x1024@1x.png" media="(prefers-color-scheme: dark)"/>
    <img src="./Michina/Resources/Assets.xcassets/AppIconPreview/Default.imageset/Default-iOS-Default-1024x1024@1x.png" width="128">
</picture>

Immich Machine Learning Server on macOS.

## Glance

In a nutshell, Michina is a Swift implementation of
[immich/machine_learning](https://github.com/immich-app/immich/tree/main/machine-learning), with a GUI, for macOS.

This project is still under development.

## Packages

This Xcode Workspace contains following local packages, READMEs are available.

- [Magearna](./Magearna): Core component of Michina, provides basic inference features.
- [ONNXRuntime](./ONNXRuntime): The fundamental library to run models.
- [Tokenizers](./Tokenizers): Tokenize text for textual smart search.

## Build

Please check the README.md in [ONNXRuntime](./ONNXRuntime) and build `onnxruntime.xcframework` before everything.
