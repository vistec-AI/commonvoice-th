# CommonVoice-TH Recipe
A commonvoice-th recipe for training ASR engine using Kaldi. The following recipe follows `commonvoice` recipe with slight modification

## Installation
The author use docker to run the container. **GPU is required** to train `tdnn_chain`, else the script can train only up to `tri3b`.
### Building Docker
```bash
$ docker build -t <docker-name> .
```
### Run docker and attach command line
```bash
$ docker run -it -v <path-to-repo>:/opt/kaldi/egs/commonvoice-th -v <path-to-labels>:/mnt/labels -v <path-to-cv-corpus>:/mnt --gpus all --name <container-name> <built-docker-name> bash
```
Once you finish this step, you should be in a docker container bash shell now

## Usage
To run the training pipeline, go to recipe directory and run `run.sh` script
```bash
$ cd /opt/kaldi/egs/commonvoice-th
$ ./run.sh --stage 0
```

## Experiment Results
Here are some experiment results evaluated on dev set:
|Model|dev WER|
|:----|:----:|
|mono|-%|
|tri1|-%|
|tri2a|-%|
|tri2b|-%|
|tri3b|-%|
|tdnn-chain|-%|

Here is final `test` set result evaluated on `tdnn-chain`
|Model|dev WER|test WER|
|:----|:------|:------:|
|tdnn-chain|-%|-%|

## Author
Chompakorn Chaksangchaichot
