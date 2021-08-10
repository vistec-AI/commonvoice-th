#!/bin/bash

# Commonvoice-th kaldi's recipe
# Modify from kaldi's commonvoice recipe
# Modified by Chompakorn CChaichot


. ./path.sh || exit 1;
. ./cmd.sh || exit 1;

# default path
cv_path="/mnt/cv-corpus-7.0-2021-07-21"
labels_path="/mnt/labels"
data_path="data"
mfccdir=mfcc

njobs=$(nproc)  # num jobs, default as num CPU
lm_order=3  # lm order

stage=0

. ./utils/parse_options.sh || exit 1;


if [ $stage -le 0 ]; then
  # prepare dataset
  echo "local/prepare_cv.py --labels-path $labels_path --data-path $data_path --cv-path $cv_path"
  local/prepare_cv.py --labels-path $labels_path --data-path $data_path --cv-path $cv_path || { echo "Fail running local/prepare_cv.py"; exit 1; }
fi

if [ $stage -le 1 ]; then
  # validate prepared data
  for part in train dev dev_unique test test_unique; do
    utils/validate_data_dir.sh --no-feats data/$part || { echo "Fail validating $part"; exit 1; }
  done

  utils/prepare_lang.sh data/local/lang '<UNK>' data/local data/lang

  # prepare LM and format to G.fst
  local/prepare_lm.sh --order $lm_order || { echo "Fail preparing LM"; exit 1; }
  local/format_data.sh || { echo "Fail creating G.fst"; exit 1; }
fi

if [ $stage -le 2 ]; then
  # create MFCC feats
  for part in train dev dev_unique test test_unique; do
    steps/make_mfcc_pitch.sh --cmd "$train_cmd" --nj $njobs data/$part exp/make_mfcc/$part $mfccdir || { echo "Error make MFCC features"; exit 1; }
    steps/compute_cmvn_stats.sh data/$part exp/make_mfcc/$part $mfccdir || { echo "Error computing CMVN"; exit 1; }
  done

  # get shortest K utterances first, likely to have more accurate alignment
  # follows main recipe but K need to be modified (K=10000 default)
  # i'll use 2000 for this case as TH commonvoice is a lot smaller
  # utils/subset_data_dir.sh --shortest data/train 2000 data/train_2kshort || exit 1;
  # utils/subset_data_dir.sh data/train 20000 data/train_20k || exit 1;
fi

# train monophone
if [ $stage -le 3 ]; then
  steps/train_mono.sh --boost-silence 1.25 --nj $njobs --cmd "$train_cmd" \
    data/train data/lang exp/mono || { echo "Error training mono"; exit 1; };
  (
    utils/mkgraph.sh data/lang exp/mono exp/mono/graph || { echo "Error making graph for mono"; exit 1; }
    for testset in dev dev_unique; do
      steps/decode.sh --nj $njobs --cmd "$decode_cmd" exp/mono/graph \
        data/$testset exp/mono/decode_$testset || { echo "Error decoding mono"; exit 1; }
    done
  )&
  steps/align_si.sh --boost-silence 1.25 --nj $njobs --cmd "$train_cmd" \
    data/train data/lang exp/mono exp/mono_ali_train || { echo "Error aligning mono"; exit 1; }
fi

# train delta + delta-delta triphone
if [ $stage -le 4 ]; then
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    2000 10000 data/train data/lang exp/mono_ali_train exp/tri1 || { echo "Error training delta tri1"; exit 1; }

  # decode tri1
  (
    utils/mkgraph.sh data/lang exp/tri1 exp/tri1/graph || { echo "Error making graph for tri1"; exit 1; }
    for testset in dev dev_unique; do
      steps/decode.sh --nj $njobs --cmd "$decode_cmd" exp/tri1/graph \
        data/$testset exp/tri1/decode_$testset || { echo "Error decoding tri1"; exit 1; }
    done
  )&

  steps/align_si.sh --nj $njobs --cmd "$train_cmd" \
    data/train data/lang exp/tri1 exp/tri1_ali_train || { echo "Error aligning tri1"; exit 1; }
fi

# LDA+MLLT
if [ $stage -le 5 ]; then
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
      data/train data/lang exp/tri1_ali_train exp/tri2b || { echo "Error training tri2b (LDA+MLLT)"; exit 1; }

  # decode LDA+MLTT
  utils/mkgraph.sh data/lang exp/tri2b exp/tri2b/graph || { echo "Error making graph for tri2b"; exit 1; }
  (
    for testset in dev dev_unique; do
    steps/decode.sh --nj $njobs --cmd "$decode_cmd" exp/tri2b/graph \
      data/$testset exp/tri2b/decode_$testset || { echo "Error decoding tri2b"; exit 1; }
    done
  )&

  # Align using tri2b
  steps/align_si.sh --nj $njobs --cmd "$train_cmd" --use-graphs true \
    data/train data/lang exp/tri2b exp/tri2b_ali_train || { echo "Error aligning tri2b"; exit 1; }
fi

# tri3b, LDA+MLLT+SAT
if [ $stage -le 6 ]; then
  steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
    data/train data/lang exp/tri2b_ali_train exp/tri3b || { echo "Error training tri3b (LDA+MLLT+SAT)"; exit 1; }

  # decode using the tri3b model
  (
    utils/mkgraph.sh data/lang exp/tri3b exp/tri3b/graph || { echo "Error making graph for tri3b"; exit 1; }
    for testset in dev dev_unique; do
      steps/decode_fmllr.sh --nj $njobs --cmd "$decode_cmd" \
        exp/tri3b/graph data/$testset exp/tri3b/decode_$testset || { echo "Error decoding tri3b"; exit 1; }
    done
  )&
fi

if [ $stage -le 7 ]; then
  # Align utts in the full training set using the tri3b model
  steps/align_fmllr.sh --nj $njobs --cmd "$train_cmd" \
    data/train data/lang \
    exp/tri3b exp/tri3b_ali_train || { echo "Error aligning FMLLR for tri4b"; exit 1; }

  # train another LDA+MLLT+SAT system on the entire training set
  steps/train_sat.sh  --cmd "$train_cmd" 4200 40000 \
    data/train data/lang \
    exp/tri3b_ali_train exp/tri4b || { echo "Error training tri4b"; exit 1; }

  # decode using the tri4b model
  (
    utils/mkgraph.sh data/lang exp/tri4b exp/tri4b/graph || { echo "Error making graph for tri4b"; exit 1; }
    for testset in dev dev_unique; do
      steps/decode_fmllr.sh --nj $njobs --cmd "$decode_cmd" \
        exp/tri4b/graph data/$testset \
        exp/tri4b/decode_$testset || { echo "Error decoding tri4b"; exit 1; }
    done
  )&
fi

# train a chain model
if [ $stage -le 8 ]; then
  local/chain/run_tdnn.sh --stage 0
fi

# wait for jobs to finish
wait
