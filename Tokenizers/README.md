# Tokenizers

This package contains bridge from Rust in [tokenizers](https://github.com/huggingface/tokenizers) to Swift (via C++ and
Objective-C).

## Preprocess

One of the target of this package requires `tokenizers.xcframework`, which is built from source in [Rust](./Rust).

Rust and [cxxbridge-cmd](https://crates.io/crates/cxxbridge-cmd) are used as building tools to build the framwork and
generate C++ glue code. It's recommended to install them with Homebrew:

```shell
brew install rust
cargo install cxxbridge-cmd
```

Then run the script to build the rust code and generate XCFramework:

```shell
./Scripts/build-tokenizers.sh
```
