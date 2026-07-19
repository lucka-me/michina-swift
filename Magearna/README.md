# Magearna

Inference infrastructure of Michina, named after
[the Artificial Pokémon](https://bulbapedia.bulbagarden.net/wiki/Magearna_(Pokémon)).

## Models

All models are hard-coded in
[InferenceModelSuite+All.swift](./Sources/Magearna/ModelSuite/InferenceModelSuite+All.swift), the list is from
[immich](https://github.com/immich-app/immich/blob/main/machine-learning/immich_ml/models/constants.py).

However, some models are not compatible perfectly with Core ML Execution Provider in MLProgram format, so we defined an
extral manually-marked properties `InferenceModel.compatibility` to acknowledge users about the models' compatibility
with Core ML and restrict the load options.

## Preprocess

This package requires a modified `onnx.proto3` from ONNX, use the script to generate it:

```shell
./Scripts/prepare-proto.sh
```
