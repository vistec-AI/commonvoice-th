#!/bin/bash

# Modified from Voxforge
# by Chompakorn Chaksangchaichot

source ./path.sh || exit 1;

srcdir=data/local
lmdir=data/local/
tmpdir=data/local/lm_tmp
langdir=data/lang
lexicon=data/local/lang/lexicon.txt
mkdir -p $tmpdir

echo "--- Preparing the grammar transducer (G.fst) ..."
cat $lmdir/lm.arpa |\
	    arpa2fst --disambig-symbol=#0 \
	                 --read-symbol-table=$langdir/words.txt - $langdir/G.fst
fstisstochastic $langdir/G.fst
# The output is like:
# 9.14233e-05 -0.259833
# we do expect the first of these 2 numbers to be close to zero (the second is
# nonzero because the backoff weights make the states sum to >1).
# Because of the <s> fiasco for these particular LMs, the first number is not
# as close to zero as it could be.

# Everything below is only for diagnostic.
# Checking that G has no cycles with empty words on them (e.g. <s>, </s>);
# this might cause determinization failure of CLG.
# #0 is treated as an empty word.
mkdir -p $tmpdir/g
awk '{if(NF==1){ printf("0 0 %s %s\n", $1,$1); }} END{print "0 0 #0 #0"; print "0";}' \
	  < "$lexicon"  >$tmpdir/g/select_empty.fst.txt
fstcompile --isymbols=$langdir/words.txt --osymbols=$langdir/words.txt \
	  $tmpdir/g/select_empty.fst.txt | \
	  fstarcsort --sort_type=olabel | fstcompose - $langdir/G.fst > $tmpdir/g/empty_words.fst
fstinfo $tmpdir/g/empty_words.fst | grep cyclic | grep -w 'y' &&
	  echo "Language model has cycles with empty words" && exit 1
rm -rf $tmpdir

echo "*** Succeeded in formatting data."
