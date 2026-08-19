# Michina

<picture>
    <source srcset="./docs/static/images/app-icon-dark.png 2x" media="(prefers-color-scheme: dark)" />
    <source srcset="./docs/static/images/app-icon-light.png 2x" media="(prefers-color-scheme: light)" />
    <img src="./docs/static/images/app-icon-light.png" />
</picture>

Immich Machine Learning Server on macOS.

[![Build Release][workflow-build-release-badge]][workflow-build-release]
[![Download Release][release-download-badge]](https://github.com/lucka-me/michina-swift/releases/latest)
[![TestFlight](https://img.shields.io/badge/TestFlight-join-blue)](https://testflight.apple.com/join/rJP9acvk)

[workflow-build-release]: https://github.com/lucka-me/michina-swift/actions/workflows/build-release.yml
[workflow-build-release-badge]: https://github.com/lucka-me/michina-swift/actions/workflows/build-release.yml/badge.svg
[release-download-badge]: https://img.shields.io/github/downloads/lucka-me/michina-swift/total?label=Downloads

If you like Michina, buy it from App Store as a tip!

[![Download on the App Store][app-store-badge]](https://apps.apple.com/app/id6778828879)

[app-store-badge]: https://toolbox.marketingtools.apple.com/api/v2/badges/download-on-the-app-store/black/en-us

## Glance

In a nutshell, Michina is a Swift implementation of
[immich/machine_learning](https://github.com/immich-app/immich/tree/main/machine-learning), with a GUI, for macOS.

> [!NOTE]
> Because of the differences in image processing ecosystem between of Swift (Core Image, Core Graphic, vImage...) and
> Python (Pillow, OpenCV, NumPy...), Michina doesn't always behave exactly the same as the original official
> implementation does, which may lead to slight differences in the outputs.  
> But these differences are expected to be toleratable, like the facial recognition embedding being different but still
> close enough to be classified as the same person.

## Packages

This Xcode Workspace contains following local packages, READMEs are available.

- [Magearna](./Magearna): Core component of Michina, provides basic inference features.
- [ONNXRuntime](./ONNXRuntime): The fundamental library to run models.
- [Tokenizers](./Tokenizers): Tokenize text for Textual Smart Search, bridged from Rust.

## Build

Some XCFramework and source file of the packages need to be built or generated before resolving, please refer to their
`README.md` for details of building.

## Execution Providers

Backed by ONNXRuntime, Michina can run models with Core ML framework accelerated or with CPU directly, please refer to
the [benchmark](./docs/content/benckmarks.md) ([web page](https://michina.lucka.dev/benckmarks)) for their comparison.
