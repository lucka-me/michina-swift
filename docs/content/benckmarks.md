---
title: Benchmarks
---

Test environment:

- MacBook Air M2, 4+4 CPU, 10 GPU, 24 GB, 1 TB
- macOS Tahoe 26
- Michina 1.0.0 (50)
- ONNXRuntime 1.26.0 (with fixes)

Columns in results:
- **Optimization**: Size of optimization files
- **Clean Load**: Elapse of loading model from scratch
- **Regular Load**: Elapse of loading model with optimization files available
- **Inference** Average elapse of inferences on all input images / texts

These benchmarks are very simple and rough, for reference only. Result may vary on different devices, OS versions and even temperature of your computer.

## Facial Recognition

Inputs:

- Images:
  [1](https://x.com/Chestnut_LUO/status/1819750909766942805/photo/1)
  [2](https://x.com/MikumoSaki/status/1170368592811966464/photo/1)
  [3](https://x.com/Ilovemathlover/status/2073607569374089557/photo/1)
  [4](https://x.com/MushroomAreas/status/2007447391704694792/photo/1)
  [5](https://x.com/fshokkaido/status/2073400698952425693/photo/1)
- Minimal Confidence for Detection: `0.7`

Results:

{% details(summary="`antelopev2`") %}
- `detection` 16.9 MB
  | Execution Provider | Optimization | Clean Load | Regular Load | Inference |
  | :----------------- | :--------- | :----------- | :----------- | :-------- |
  | Core ML (MLProgram) | 34 MB | 574 ms | 325 ms | 98 ms
  | Core ML (NeuralNetwork) | 33.9 MB | 253 ms | 72 ms | 84 ms
  | CPU | 18.5 MB | 52 ms | 42 ms | 249 ms

- `recognition` 260.7 MB
  | Execution Provider | Optimization | Clean Load | Regular Load | Inference |
  | :----------------- | :--------- | :----------- | :----------- | :-------- |
  | Core ML (MLProgram) | 522.3 MB | 2.016 s | 969 ms | 466 ms
  | Core ML (NeuralNetwork) | 522 MB | 4.744 s | 175 ms | 6.09 s
  | CPU | 260.6 MB | 523 ms | 449 ms | 3.66 s
{% end %}

{% details(summary="`buffalo_l`") %}
- `detection` (Same model as `antelopev2` / `detection`)

- `recognition` 174.4 MB
  | Execution Provider | Optimization | Clean Load | Regular Load | Inference |
  | :----------------- | :--------- | :----------- | :----------- | :-------- |
  | Core ML (MLProgram) | 349.3 MB | 1.416 s | 870 ms | 295 ms
  | Core ML (NeuralNetwork) | 349.1 MB | 2.287 s | 122 ms | 4.33 s
  | CPU | 174.3 MB | 287 ms | 259 ms | 1.95 s
{% end %}

{% details(summary="`buffalo_m`") %}
- `detection` 3.3 MB
  | Execution Provider | Optimization | Clean Load | Regular Load | Inference |
  | :----------------- | :--------- | :----------- | :----------- | :-------- |
  | Core ML (MLProgram) | 6.7 MB | 510 ms | 316 ms | 32 ms
  | Core ML (NeuralNetwork) | 6.7 MB | 171 ms | 78 ms | 45 ms
  | CPU | 3.8 MB | 27 ms | 27 ms | 88 ms

- `recognition` (Same model as `buffalo_l` / `recognition`)
{% end %}

{% details(summary="`buffalo_s`") %}
- `detection` 2.5 MB
  | Execution Provider | Optimization | Clean Load | Regular Load | Inference |
  | :----------------- | :--------- | :----------- | :----------- | :-------- |
  | Core ML (MLProgram) | 5.2 MB | 519 ms | 333 ms | 61 ms
  | Core ML (NeuralNetwork) | 5.1 MB | 171 ms | 77 ms | 31 ms
  | CPU | 2.8 MB | 25 ms | 21 ms | 32 ms

- `recognition` 13.6 MB
  | Execution Provider | Optimization | Clean Load | Regular Load | Inference |
  | :----------------- | :--------- | :----------- | :----------- | :-------- |
  | Core ML (MLProgram) | 27.4 MB | 356 ms | 229 ms | 348 ms
  | Core ML (NeuralNetwork) | 27.3 MB | 566 ms | 44 ms | 29 ms
  | CPU | 13.6 MB | 49 ms | 42 ms | 141 ms
{% end %}

{% details(summary="`apple-vision`") %}
The numbers of detected face are significantly less that all other models.

- `detection` Apple's Vision Framework
  | Execution Provider | Optimization | Clean Load | Regular Load | Inference |
  | :----------------- | :--------- | :----------- | :----------- | :-------- |
  | - | - | - | - | 208 ms
{% end %}

## Smart Search (CLIP)

## Character Recognition (OCR)
