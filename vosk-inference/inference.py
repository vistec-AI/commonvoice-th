#!/usr/bin/env python3

import argparse
import logging

from vosk_transcriber import VoskTranscriber

logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)


def run_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument("--wav-path", type=str, required=True, help="Path to inference sample")
    parser.add_argument("--model-path", type=str, default="model", help="Path to tdnn-chain model directory " + \
        "(as in vosk format see https://alphacephei.com/kaldi/models/vosk-model-small-en-us-0.15.zip")
    return parser.parse_args()


def main(args):
    # unpack
    model_path = args.model_path
    # wav_paths will be list of wav_path to be inference
    # use this code as an example in case you want to use
    # it in production
    wav_paths = [args.wav_path]
    
    transcriber = VoskTranscriber(model_path)

    for wav in wav_paths:
        logging.info("Transcribing `{wav}`".format(wav=wav))
        text = transcriber.transcribe(wav)
        logging.info("\tTranscription: {text}".format(text=text))


if __name__ == "__main__":
    args = run_parser()
    main(args)

