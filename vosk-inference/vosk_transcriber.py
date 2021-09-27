#!/usr/bin/env python3

import json
import logging
import os
import wave
from typing import Any, Dict, Optional

from vosk import Model, KaldiRecognizer, SetLogLevel

SetLogLevel(0)


class VoskTranscriber:
    """
    Vosk Transcriber

    Vosk wrapper to do transcription or instantiating server

    Attributes
    ----------
    model_path: str
        Path to loaded model
    model: vosk.Model
        Vosk model loaded from Kaldi file
    """
    def __init__(self, model_path: str) -> None:
        """
        Constructor of VoskTranscriver

        model_path: str
            Path for Kaldi model to read. Model must be properly formatted. (See example in github release)
        """
        self.model_path: str = model_path
        # sanity check model path
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Cannot find model path: `{model_path}`")
        self.model: Model = Model(model_path)

    def transcribe(self, wav_path: str) -> Dict[str, Any]:
        """
        Transcribe audio given a path
        """
        wf: Any = wave.open(wav_path, "rb")

        # check file eligibility
        if wf.getnchannels() != 1 or wf.getsampwidth() != 2 or wf.getcomptype() != "NONE":
            raise OSError(f"Cannot read wav file: `{wav_path}`. Make sure your audio file is in .wav format and mono channel")

        rec: KaldiRecognizer = KaldiRecognizer(self.model, wf.getframerate())
        rec.SetWords(True)

        while True:
            data: Any = wf.readframes(4000)
            if len(data) == 0:
                break
            if rec.AcceptWaveform(data):
                logging.debug(rec.Result())
            else:
                logging.debug(rec.PartialResult())

        return json.loads(rec.FinalResult())

