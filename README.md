# CommonVoice-TH Recipe
A commonvoice-th recipe for training ASR engine using Kaldi. The following recipe follows `commonvoice` recipe with slight modification

## Installation
The author use docker to run the container. **GPU is required** to train `tdnn_chain`, else the script can train only up to `tri3b`.

### Downloading Commonvoice Corpus
We will need a commonvoice corpus for training ASR Engine. We are using Commonvoice Corpus 7.0 in Thai language which can be download [here](https://commonvoice.mozilla.org/th/datasets). Once downloaded, unzip it as we will use it later to mount dataset to the docker container.

### Downloading SRILM
Before building docker, SRILM file need to be downloaded. You can download it from [here](http://www.speech.sri.com/projects/srilm/download.html). Once the file is downloaded, remove version name (e.g. from `srilm-1.7.3.tar.gz` to `srilm.tar.gz` and place it inside `docker` directory. Your `docker` directory should contains 2 files: `dockerfile`, and `srilm.tar.gz`.

## Building Docker for Training with Kaldi
Once you have prepared SRILM file, you are ready to build docker for training this recipe. This docker automatically install project's dependendies and stored it in an image. To build a docker image, run:
```bash
$ cd docker
$ docker build -t <docker-name> kaldi
```

### Run docker and attach command line
Once the image had been built, all you have to do is interactively attach to its bash terminal via the following command:
```bash
$ docker run -it -v <path-to-repo>:/opt/kaldi/egs/commonvoice-th \
                 -v <path-to-repo>/labels:/mnt/labels \
                 -v <path-to-cv-corpus>:/mnt \
                 --gpus all --name <container-name> <built-docker-name> bash
```
Once you finish this step, you should be in a docker container's bash terminal now

## Building Docker for inferencing via Vosk
We also provide an example of how to inference a trained kaldi model using Vosk. Berore we begin, let's build Vosk docker image:
```bash
$ cd docker
$ docker build -t <docker-name> vosk-inference
$ cd ..  # back to root directory
```

### Preparing Directories for Vosk Inferencing
The first step is to download provided Vosk model format on this github's release. Unzip it to `vosk-inference` directory. Or you can just follow this code.
```
$ cd vosk-inference
$ wget https://github.com/vistec-AI/commonvoice-th/releases/download/vosk-v1/model.zip
$ unzip model.zip
```

### Run docker and test inference script
To prevent dependencies problem, the Vosk inference python script must be run inside a docker image that we just built. First, let's initiate a docker
```bash
$ docker run -it -v <path-to-repo>:/workspace \
                 --name <container-name> \
                 -p 8000:8000 \
                 <build-docker-name> bash
```
Then, you will be attached to a linux terminal inside the container. To inference an audio file, run:
```bash
$ cd vosk-inference
$ python3.8 inference.py --wav-path <path-to-wav>  # test it with test.wav
```
**Note that audio file must be 16k samping rate and mono channel!**

### Instaltiating Vosk Server to Processing audio files
We also provide a `fastapi` server that will allow user to transcribe their own audio file via RESTful API. To instantiate server, run this command **inside a docker shell**
```bash
$ cd vosk-inference
$ uvicorn server:app --host 0.0.0.0 --reload
```
Now, the server will instantiate at `http://localhost:8000`. To see if server is correctly instantiated, try to browse `http://localhost:8000/healthcheck`. If the webpage loaded then we are good to go!

#### API Endpoint
The endpoint will be in form-data format where each file is attached to a form field named `audios`. See python example
```python
import requests

url = "localhost:8000/transcribe"

payload={}
files=[
    ('audios', (<file-name>, open(<file-path>, 'rb'), 'audio/wav')),
    ...
]
headers = {}

response = requests.request("POST", url, headers=headers, data=payload, files=files)

print(response.text)
```

## Online Decoding with WebRTC Protocol
Read more at [this repository](https://github.com/danijel3/KaldiWebrtcServer). The provided repository contains an easy way to deploy Kaldi `tdnn-chain` model to webRTC server.


## Usage
To run the training pipeline, go to recipe directory and run `run.sh` script
```bash
$ cd /opt/kaldi/egs/commonvoice-th/s5
$ ./run.sh --stage 0
```


## Experiment Results
Here are some experiment results evaluated on dev set:

<table>
  <thead>
    <tr>
      <th rowspan="2">Model</th>
      <th colspan="2">dev</th>
      <th colspan="2">dev-unique</th>
    </tr>
    <tr>
      <th>WER</th>
      <th>CER</th>
      <th>WER</th>
      <th>CER</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>mono</td>
      <td>79.13%</td>
      <td>57.31%</td>
      <td>77.79%</td>
      <td>48.97%</td>
    </tr>
    <tr>
      <td>tri1</td>
      <td>56.55%</td>
      <td>37.88%</td>
      <td>53.26%</td>
      <td>27.99%</td>
    </tr>
    <tr>
      <td>tri2b</td>
      <td>50.64%</td>
      <td>32.85%</td>
      <td>47.38%</td>
      <td>21.89%</td>
    </tr>
    <tr>
      <td>tri3b</td>
      <td>50.52%</td>
      <td>32.70%</td>
      <td>47.06%</td>
      <td>21.67%</td>
    </tr>
    <tr>
      <td>tri4b</td>
      <td>46.81%</td>
      <td>29.47%</td>
      <td>43.18%</td>
      <td>18.05%</td>
    </tr>
    <tr>
      <td>tdnn-chain</td>
      <td>29.15%</td>
      <td>14.96%</td>
      <td>30.84%</td>
      <td>8.75%</td>
    </tr>
    <tr>
      <td>tdnn-chain-online</td>
      <td>29.02%</td>
      <td>14.64%</td>
      <td>30.41%</td>
      <td>8.28%</td>
    </tr>
  </tbody>
</table>

Here is final `test` set result evaluated on `tdnn-chain`

<table>
  <thead>
    <tr>
      <th rowspan="2">Model</th>
      <th colspan="2">test</th>
      <th colspan="2">test-unique</th>
    </tr>
    <tr>
      <th>WER</th>
      <th>CER</th>
      <th>WER</th>
      <th>CER</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>tdnn-chain-online</td>
      <td>9.71%</td>
      <td>3.12%</td>
      <td>23.04%</td>
      <td>7.57%</td>
    </tr>
  </tbody>
  <tbody>
    <tr>
      <td>airesearch/wav2vec2-xlsr-53-th</td>
      <td>-</td>
      <td>-</td>
      <td>13.63</td>
      <td>2.81%</td>
    </tr>
  </tbody>
  <tbody>
    <tr>
      <td>Google Web Speech API</td>
      <td>-</td>
      <td>-</td>
      <td>13.71%</td>
      <td>7.36%</td>
    </tr>
  </tbody>
  <tbody>
    <tr>
      <td>Microsoft Bing Search API</td>
      <td>-</td>
      <td>-</td>
      <td>12.58%</td>
      <td>5.01%</td>
    </tr>
  <tbody>
    <tr>
      <td>Amazon Transcribe</td>
      <td>-</td>
      <td>-</td>
      <td>21.86%</td>
      <td>7.08%</td>
    </tr>
  </tbody>

  </tbody>

</table> 

## Author
Chompakorn Chaksangchaichot
