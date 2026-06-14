# Magearna

Inference infrastructure of Michina, named after [the Artificial Pokémon](https://bulbapedia.bulbagarden.net/wiki/Magearna_(Pokémon)).

## Models

All models are hard-coded in [InferenceModelSuite+All.swift](./Magearna/Sources/Magearna/ModelSuite/InferenceModelSuite+All.swift), the list is copied from [immich](https://github.com/immich-app/immich/blob/main/machine-learning/immich_ml/models/constants.py).

However, since not all models are compatible perfectly with Core ML Execution Provider, there are some extral manually-marked properties like `InferenceModel.compatibility` and `InferenceModelSuite.isVerified` to acknowledge users about the models' compatibility with Core ML and whether they have been verified bu us.