# Tokenizers

This package contains bridge from Rust in [tokenizers](https://github.com/huggingface/tokenizers) to Swift (via C++ and
Objective-C).

## Preprocess

One of the target in this package requires `tokenizers.xcframework`, which is built from source in [Rust](./Rust).

Rust and [cxxbridge-cmd](https://crates.io/crates/cxxbridge-cmd) are used as building tools to build the framwork and
generate C++ glue code. Please follow [their official instruction](https://rust-lang.org/tools/install/) to install Rust
and then install cxxbridge-cmd with cargo:

```shell
cargo install --version 1.0.194 cxxbridge-cmd
```

Michina supports both `arm64` and `x86_64` architectures, so should `tokenizers.xcframework`. Install cross-compile
target with `rustup`:

```shell
rustup target add x86_64-apple-darwin   # Install x86_64 target on Apple Silicon Mac
rustup target add aarch64-apple-darwin  # Install arm64 target on Intel Mac
```

Then run the script to build the rust code and generate universal XCFramework:

```shell
./Frameworks/tokenizers/build.sh
```
