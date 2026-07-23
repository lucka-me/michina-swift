---
title: Benchmarks
---

Test environment:

- MacBook Air M2, 4+4 CPU, 10 GPU, 24 GB, 1 TB
- macOS Tahoe 26
- Michina 1.0.0 (52)
- ONNXRuntime 1.26.0 (with fixes)

Columns in results:
- **Optimization**: Size of optimization files
- **Clean Load**: Elapse of loading model from scratch
- **Regular Load**: Elapse of loading model with optimization files available
- **Inference** Average elapse of inferences on all input images / texts

These benchmarks are very simple and rough, for reference only. Result may vary on different devices, OS versions and
even temperature of your computer.

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
  | Execution Provider      | Optimization | Clean Load | Regular Load | Inference |
  | :---------------------- | :----------- | :--------- | :----------- | :-------- |
  | Core ML (MLProgram)     | 34 MB        | 574 ms     | 325 ms       | 98 ms     |
  | Core ML (NeuralNetwork) | 33.9 MB      | 253 ms     | 72 ms        | 84 ms     |
  | CPU                     | 18.5 MB      | 52 ms      | 42 ms        | 249 ms    |

- `recognition` 260.7 MB
  | Execution Provider      | Optimization | Clean Load | Regular Load | Inference |
  | :---------------------- | :----------- | :--------- | :----------- | :-------- |
  | Core ML (MLProgram)     | 522.3 MB     | 2.016 s    | 969 ms       | 466 ms    |
  | Core ML (NeuralNetwork) | 522 MB       | 4.744 s    | 175 ms       | 6.09 s    |
  | CPU                     | 260.6 MB     | 523 ms     | 449 ms       | 3.66 s    |
{% end %}

{% details(summary="`buffalo_l`") %}
- `detection` (Same model as `antelopev2` / `detection`)

- `recognition` 174.4 MB
  | Execution Provider      | Optimization | Clean Load | Regular Load | Inference |
  | :---------------------- | :----------- | :--------- | :----------- | :-------- |
  | Core ML (MLProgram)     | 349.3 MB     | 1.416 s    | 870 ms       | 295 ms    |
  | Core ML (NeuralNetwork) | 349.1 MB     | 2.287 s    | 122 ms       | 4.33 s    |
  | CPU                     | 174.3 MB     | 287 ms     | 259 ms       | 1.95 s    |
{% end %}

{% details(summary="`buffalo_m`") %}
- `detection` 3.3 MB
  | Execution Provider      | Optimization | Clean Load | Regular Load | Inference |
  | :---------------------- | :----------- | :--------- | :----------- | :-------- |
  | Core ML (MLProgram)     | 6.7 MB       | 510 ms     | 316 ms       | 32 ms     |
  | Core ML (NeuralNetwork) | 6.7 MB       | 171 ms     | 78 ms        | 45 ms     |
  | CPU                     | 3.8 MB       | 27 ms      | 27 ms        | 88 ms     |

- `recognition` (Same model as `buffalo_l` / `recognition`)
{% end %}

{% details(summary="`buffalo_s`") %}
- `detection` 2.5 MB
  | Execution Provider      | Optimization | Clean Load | Regular Load | Inference |
  | :---------------------- | :----------- | :--------- | :----------- | :-------- |
  | Core ML (MLProgram)     | 5.2 MB       | 519 ms     | 333 ms       | 61 ms     |
  | Core ML (NeuralNetwork) | 5.1 MB       | 171 ms     | 77 ms        | 31 ms     |
  | CPU                     | 2.8 MB       | 25 ms      | 21 ms        | 32 ms     |

- `recognition` 13.6 MB
  | Execution Provider      | Optimization | Clean Load | Regular Load | Inference |
  | :---------------------- | :----------- | :--------- | :----------- | :-------- |
  | Core ML (MLProgram)     | 27.4 MB      | 356 ms     | 229 ms       | 348 ms    |
  | Core ML (NeuralNetwork) | 27.3 MB      | 566 ms     | 44 ms        | 29 ms     |
  | CPU                     | 13.6 MB      | 49 ms      | 42 ms        | 141 ms    |
{% end %}

{% details(summary="`apple-vision`") %}
The numbers of detected face are significantly less than all other models.

- `detection` Apple's Vision Framework
  | Execution Provider | Optimization | Clean Load | Regular Load | Inference |
  | :----------------- | :----------- | :--------- | :----------- | :-------- |
  | -                  | -            | -          | -            | 208 ms    |
{% end %}

## Smart Search (CLIP)

Inputs:

- Images:
  [1](https://lunar.place/notes/aoto0roemnf303nl)
  [2](https://mastodon.social/@BasicAppleGuy/116943044645730277)
  [3](https://mas.to/@lucka/116392750247627914)
  [4](https://mas.to/@lucka/115987903999029399)
  [5](https://mas.to/@lucka/115502567372973518)
- Texts: `cat` `dog` `plushie` `seaside` `burger and drawings`

Results:

{% details(summary="`ViT-SO400M-16-SigLIP2-384__webli`") %}
- `visual` 1.71 GB
  | Execution Provider      | Optimization | Clean Load | Regular Load | Inference |
  | :---------------------- | :----------- | :--------- | :----------- | :-------- |
  | Core ML (MLProgram)     | 8.28 GB      | 1393 s     | 201 s        | 287 ms    |
  | Core ML (NeuralNetwork) | 3.42 GB      | 17.32 s    | 2.637 s      | 599 ms    |
  | CPU                     | 1.71 GB      | 3.674 s    | 2.846 s      | 2.96 s    |

- `textual` 2.87 GB
  | Execution Provider      | Optimization | Clean Load | Regular Load | Inference |
  | :---------------------- | :----------- | :--------- | :----------- | :-------- |
  | Core ML (MLProgram)     | 9.95 GB      | 889 s      | 263 s        | 159 ms    |
  | Core ML (NeuralNetwork) | 5.67 GB      | 28.136 s   | 3.218 s      | 273 ms    |
  | CPU                     | 334 KB       | 4.878 s    | 4.695 s      | 305 ms    |
{% end %}

## Character Recognition (OCR)

- Images:
  [1](https://demo.immich.app/photos/dd9876ac-6248-4b5e-877b-776a32520b73)
  [2](https://demo.immich.app/photos/7cd2c7bd-7d0c-4d2f-a512-3480a30cf637)
  [3](https://tabelog.com/tw/okinawa/A4701/A470101/47004995/dtlmenu/photo/?PG=1)
  [4](https://tabelog.com/tw/shizuoka/A2205/A220501/22013913/dtlmenu/photo/?PG=3)
  [5](https://commons.wikimedia.org/wiki/File:HK_KTD_KW_觀塘_Kwun_Tong_開源道_Hoi_Yuen_Road_鱷魚恤中心_Crocodile_Centre_百樂門宴會廳_Paramont_Banquet_Hall_Restaurant_飲早茶_morning_tea_meal_menu_April_2022_Px3_03.jpg)
- Minimal Confidence for Detection: `0.5`
- Maximal Resolution: `736`
- Minimal Confidence for Recognition: `0.6`

Results:

{% details(summary="`PP-OCRv5_server`") %}

Unable to load in MLProgram format, error:

> Failed to parse the model specification. Error: Unable to parse ML Program: in operation MaxPool.0: ceil_mode must be
> False when pad_type is equal to same

- `detection` 88.1 MB
  | Execution Provider      | Optimization | Clean Load | Regular Load | Inference |
  | :---------------------- | :----------- | :--------- | :----------- | :-------- |
  | Core ML (MLProgram)     | -            | -          | -            | -         |
  | Core ML (NeuralNetwork) | 175.4 MB     | 1.318 s    | 114 ms       | 655 ms    |
  | CPU                     | 87.8 MB      | 136 ms     | 109 ms       | 3.13 s    |

- `recognition` 84.6 MB
  | Execution Provider      | Optimization | Clean Load | Regular Load | Inference |
  | :---------------------- | :----------- | :--------- | :----------- | :-------- |
  | Core ML (MLProgram)     | -            | -          | -            | -         |
  | Core ML (NeuralNetwork) | 149 MB       | 941 ms     | 171 ms       | 2.56 s    |
  | CPU                     | 84.3 MB      | 165 ms     | 136 ms       | 5.13 s    |
{% end %}

{% details(summary="`PP-OCRv5_mobile`") %}

The outputs from Core ML (NeuralNetwork) are likely incorrect.

- `detection` 4.8 MB
  | Execution Provider      | Optimization | Clean Load | Regular Load | Inference |
  | :---------------------- | :----------- | :--------- | :----------- | :-------- |
  | Core ML (MLProgram)     | 9.8 MB       | 4.116 s    | 2.733 s      | 699 ms    |
  | Core ML (NeuralNetwork) | 9.7 MB       | 590 ms     | 161 ms       | -         |
  | CPU                     | 5 MB         | 46 ms      | 49 ms        | 356 ms    |

- `recognition` 16.6 MB
  | Execution Provider      | Optimization | Clean Load | Regular Load | Inference |
  | :---------------------- | :----------- | :--------- | :----------- | :-------- |
  | Core ML (MLProgram)     | 33.3 MB      | 5.245 s    | 3.474 s      | 43.58 s   |
  | Core ML (NeuralNetwork) | 13.8 MB      | 566 ms     | 211 ms       | -         |
  | CPU                     | 16.7 MB      | 85 ms      | 79 ms        | 1.06 s    |
{% end %}
