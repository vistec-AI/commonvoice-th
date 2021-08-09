# CommonVoice-TH Recipe
A commonvoice-th recipe for training ASR engine using Kaldi. The following recipe follows `commonvoice` recipe with slight modification

## Installation
The author use docker to run the container. **GPU is required** to train `tdnn_chain`, else the script can train only up to `tri3b`.

### Downloading Commonvoice Corpus
We will need a commonvoice corpus for training ASR Engine. We are using Commonvoice Corpus 7.0 in Thai language which can be download [here](https://commonvoice.mozilla.org/th/datasets). Once downloaded, unzip it as we will use it later to mount dataset to the docker container.

### Downloading SRILM
Before building docker, SRILM file need to be downloaded. You can download it from [here](http://www.speech.sri.com/projects/srilm/download.html). Once the file is downloaded, remove version name (e.g. from `srilm-1.7.3.tar.gz` to `srilm.tar.gz` and place it inside `docker` directory. Your `docker` directory should contains 2 files: `dockerfile`, and `srilm.tar.gz`.

### Building Docker
Once you have prepared SRILM file, you are ready to build docker for training this recipe. This docker automatically install project's dependendies and stored it in a container. To build a container, run:
```bash
$ docker build -t <docker-name> .
```

### Run docker and attach command line
Once the container had been built, all you have to do is interactively attach to its bash terminal via the following command:
```bash
$ docker run -it -v <path-to-repo>:/opt/kaldi/egs/commonvoice-th \
                 -v <path-to-repo>/labels:/mnt/labels \
                 -v <path-to-cv-corpus>:/mnt \
                 --gpus all --name <container-name> <built-docker-name> bash
```
Once you finish this step, you should be in a docker container's bash terminal now

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
|mono|78.58%|
|tri1|53.28%|
|tri2b|47.47%|
|tri3b|46.82%|
|tdnn-chain|30.15%|

Here is final `test` set result evaluated on `tdnn-chain`
|Model|dev WER|test WER|
|:----|:------|:------:|
|tdnn-chain|30.15%|23.41%|

## Author
Chompakorn Chaksangchaichot
