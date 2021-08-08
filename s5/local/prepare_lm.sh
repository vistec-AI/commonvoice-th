#!/bin/bash

# Modified from Voxforge
# by Chompakorn Chaksangchaichot

. ./path.sh || exit 1;

echo "=== Building a language model ..."

locdata=data/local
loctmp=$locdata/tmp

echo "--- Preparing a corpus from test and train transcripts ..."

# Language model order
order=3

. utils/parse_options.sh

# Prepare a LM from both train / dev corpus
# This is cheating but we are trying to reproduce the 
# experiment results from official which fused both train / dev
mkdir -p $loctmp
cat data/train/text > $loctmp/utt.txt
cut -f2- -d' ' < $loctmp/utt.txt | sed -e 's:[ ]\+: :g' | sort -u > $loctmp/corpus.txt
rm $loctmp/utt.txt


loc=`which ngram-count`;
if [ -z $loc ]; then
	if uname -a | grep 64 >/dev/null; then # some kind of 64 bit...
		sdir=$KALDI_ROOT/tools/srilm/bin/i686-m64 
	else
		sdir=$KALDI_ROOT/tools/srilm/bin/i686
	fi
	if [ -f $sdir/ngram-count ]; then
		echo Using SRILM tools from $sdir
		export PATH=$PATH:$sdir
	else
		echo You appear to not have SRILM tools installed, either on your path,
		echo or installed in $sdir.  See tools/install_srilm.sh for installation
		echo instructions.
		exit 1
	fi
fi

ngram-count -order $order -write-vocab $locdata/vocab-full.txt -wbdiscount \
	-text $loctmp/corpus.txt -lm $locdata/lm.arpa

echo "*** Finished building the LM model!"
