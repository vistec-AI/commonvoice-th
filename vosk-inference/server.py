import os
import subprocess
from typing import List

import aiofiles
from fastapi import FastAPI, File, UploadFile

from vosk_transcriber import VoskTranscriber

app = FastAPI()
model_path: str = "model"  # change this if neccessary
transcriber = VoskTranscriber(model_path)


def clear_audio(audio_paths: List[str]) -> None:
    for f in audio_paths:
        os.remove(f)


@app.get("/healthcheck")
async def healthcheck():
    return {"status": "healthy"}


@app.post("/transcribe")
async def transcribe(audios: List[UploadFile] = File(...)):
    """
    Predict audio POST from front-end server using `form-data` files
    NOTE: note that this might bug if > 1 requests are sent with the same file name
    """
    # save files
    audio_paths = []
    for audio in audios:
        if not os.path.exists("tmp"):
            os.makedirs("tmp")
        # save tmp audio file
        tmp_name = f"tmp/{audio.filename}.tmp"
        save_name = f"tmp/{audio.filename}".replace(".mp3", ".wav")
        async with aiofiles.open(tmp_name, "wb") as f:
            content = await audio.read()
            await f.write(content)

        # convert to mono, 16k sampling rate
        result = subprocess.run(
            [
                "ffmpeg",
                "-i",
                tmp_name,
                "-ac", "1",
                "-ar", "16000",
                save_name
            ],
            stdout=subprocess.PIPE
        )
        audio_paths.append(save_name)
        assert os.path.exists(save_name)

    # inference
    result = {
        wav: transcriber.transcribe(wav)
        for wav in audio_paths
    }

    clear_audio(audio_paths)
    return result, 200
