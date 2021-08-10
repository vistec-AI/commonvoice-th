#!/usr/bin/python3.8

import os
import re
from argparse import ArgumentParser, Namespace

import pandas as pd

from pythainlp.tokenize import newmm


def run_parser() -> Namespace:
    """Run argument parser"""
    parser = ArgumentParser()
    parser.add_argument("--labels-path", type=str, required=True, help="Path to labels directory")
    parser.add_argument("--data-path", type=str, required=True, help="Path to data root")
    parser.add_argument("--cv-path", type=str, required=True, help="Path to commonvoice root")
    return parser.parse_args()


def format_df(df: pd.DataFrame, data_path: str, set_name: str, commonvoice_root: str, sr: int = 16000) -> None:
    """Format train/dev/test dataframe and stored in data root"""
    df = df[["path", "sentence"]]
    set_path = "{data_path}/{set_name}".format(data_path=data_path, set_name=set_name)
    if not os.path.exists(set_path):
        os.makedirs(set_path)
    wav_scp = open("{set_path}/wav.scp".format(set_path=set_path), "w")
    utt2spk = open("{set_path}/utt2spk".format(set_path=set_path), "w")
    spk2utt = open("{set_path}/spk2utt".format(set_path=set_path), "w")
    text = open("{set_path}/text".format(set_path=set_path), "w")
    for i, (path, sent) in df.sort_values("path").iterrows():
        # tokenize sentence with newmm
        tokenized_sent = " ".join(newmm.segment(sent.replace(".", "")))
        tokenized_sent = re.sub(r" +", " ", tokenized_sent)
        
        # write files to data/[train,dev,test]
        f_id = path.replace(".wav", "").replace(".mp3", "")
        wav_scp.write("{f_id} sox {commonvoice_root}/th/clips/{path} -t wav -r {sr} -c 1 -b 16 - |\n".format(f_id=f_id, commonvoice_root=commonvoice_root, path=path, sr=sr))
        utt2spk.write("{f_id} {f_id}\n".format(f_id=f_id))  # we wont specify spk id here
        spk2utt.write("{f_id} {f_id}\n".format(f_id=f_id))
        text.write("{f_id} {tokenized_sent}\n".format(f_id=f_id, tokenized_sent=tokenized_sent))
    wav_scp.close()
    utt2spk.close()
    spk2utt.close()
    text.close()


def prepare_lexicon(data_path: str) -> None:
    """Prepare data/local/lang directory"""
    with open("{data_path}/train/text".format(data_path=data_path), "r") as f:
        train_data = [" ".join(line.split(" ")[1:]).strip() for line in f.readlines()]
    words = sorted(set([w for sent in train_data for w in sent.split(" ")]))
    
    lexicon = ["!SIL sil\n", "<UNK> spn\n"] + [" ".join([word] + list(word))+"\n" for word in words]
    nonsilence_phones = [g+"\n" for g in sorted(set([char for word in words for char in word]))]
    optional_silence = ["sil\n"]
    silence_phones = ["sil\n", "spn\n"]
    
    if not os.path.exists("{data_path}/local/lang".format(data_path=data_path)):
        os.makedirs("{data_path}/local/lang".format(data_path=data_path))
    
    open("{data_path}/local/lang/lexicon.txt".format(data_path=data_path), "w").writelines(lexicon)
    open("{data_path}/local/lang/nonsilence_phones.txt".format(data_path=data_path), "w").writelines(nonsilence_phones)
    open("{data_path}/local/lang/optional_silence.txt".format(data_path=data_path), "w").writelines(optional_silence)
    open("{data_path}/local/lang/silence_phones.txt".format(data_path=data_path), "w").writelines(silence_phones)
    open("{data_path}/local/lang/extra_questions.txt".format(data_path=data_path), "w").writelines([])
    
    
def main(args: Namespace) -> None:
    train = pd.read_csv(args.labels_path+"/train.tsv", delimiter="\t")
    dev = pd.read_csv(args.labels_path+"/dev.tsv", delimiter="\t")
    dev_unique = pd.read_csv(args.labels_path+"/dev-unique.tsv", delimiter="\t")
    test = pd.read_csv(args.labels_path+"/test.tsv", delimiter="\t")
    test_unique = pd.read_csv(args.labels_path+"/test-unique.tsv", delimiter="\t")

    format_df(train, args.data_path, "train", args.cv_path)
    format_df(dev, args.data_path, "dev", args.cv_path)
    format_df(dev_unique, args.data_path, "dev_unique", args.cv_path)
    format_df(test, args.data_path, "test", args.cv_path)
    format_df(test_unique, args.data_path, "test_unique", args.cv_path)

    prepare_lexicon(args.data_path)


if __name__ == "__main__":
    args = run_parser()
    main(args)

