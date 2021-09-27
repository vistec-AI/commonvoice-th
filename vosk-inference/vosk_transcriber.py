#!/usr/bin/env python3

import logging
import os
import wave

from vosk import Model, KaldiRecognizer, SetLogLevel

SetLogLevel(0)


class VoskTranscriber:
    def __init__(self, model_path):
        self.model_path = model_path
        # sanity check model path
        if not os.path.exists(model_path):
            raise FileNotFoundError("Cannot find model path: `{model_path}`".format(model_path=model_path))
        self.model = Model(model_path)

    def transcribe(self, wav_path):
        wf = wave.open(wav_path, "rb")
        if wf.getnchannels() != 1 or wf.getsampwidth() != 2 or wf.getcomptype() != "NONE":
            raise OSError("Cannot read wav file: `{wav_path}`. Make sure your audio file is in .wav format and mono channel".format(wav_path=wav_path))

        rec = KaldiRecognizer(self.model, wf.getframerate())
        rec.SetWords(True)

        while True:
            data = wf.readframes(4000)
            if len(data) == 0:
                break
            if rec.AcceptWaveform(data):
                logging.debug(rec.Result())
            else:
                logging.debug(rec.PartialResult())

        return rec.FinalResult()

