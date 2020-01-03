#!/bin/bash
# for kaldi nnet3 decoding process check
# 
# Copyright  2017  Atlas Guide (Author : Lucas Jo)
# 
# Apache 2.0
#
#
. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh
curdir=`pwd`
echo $curdir
echo "$0 $@"  # Print the command line for logging

#cd $rfaddr
#file_num=[ls -l | grep .pcm$ | wc -l]
#echo "$file_num"

cd ~/data/test
datadir=`pwd`
./data_prep_test.sh
./data_prep_test1.sh

cd $curdir

#decoder=/home/haruband/kaldi/src/online2bin/online2-web-nnet3-decode-testmode
decoder=~/kaldi/src/online2bin/online2-web-testmode
echo "$0 $@"

filename=audio.flac
#srcdir=transcriptions/zeroth/
#srcdir=transcriptions/zeroth_numbertest/
srcdir=test/models/korean/zeroth/
dir=transcriptions/online2_decode/

if [ ! -d $dir ]; then
    mkdir -p $dir
fi

do_endpointing=false
frames_per_chunk=20
extra_left_context_initial=0
online=true
online_config=$srcdir/conf/online.conf;
min_active=200
max_active=7000
beam=15.0
lattice_beam=6.0
acwt=0.5
post_decode_acwt=10.0  # can be used in 'chain' systems to scale acoustics by 10 so the
                       # regular scoring script works.

#str="000 flac -c -d -s $filename |"
#echo $str > wav.scp
wav_rspecifier="ark,s,cs:wav-copy scp,p:wav.scp ark:- |"
#wav_rspecifier="/home/haruband/data/test/wav.scp"

echo "000 000" > spk2utt
spk2utt_rspecifier="ark:spk2utt"

frame_subsampling_opt=
if [ -f $srcdir/frame_subsampling_factor ]; then
  # e.g. for 'chain' systems
  frame_subsampling_opt="--frame-subsampling-factor=$(cat $srcdir/frame_subsampling_factor)"
fi

lat_wspecifier="ark:|gzip -c >$dir/lat.1.gz"
if [ "$post_decode_acwt" == 1.0 ]; then
  lat_wspecifier="ark:|gzip -c >$dir/lat.1.gz"
else
  lat_wspecifier="ark:|lattice-scale --acoustic-scale=$post_decode_acwt ark:- ark:- | gzip -c >$dir/lat.1.gz"
fi

web_stage=3
echo "#### Decoding ####"
echo $silence_weighting_opts
echo "#### Decoding ####"

if [ "$web_stage" -eq 1 ]; then
    echo "web docoding"
    $decoder $silence_weighting_opts \
          --verbose=2 \
	  $srcdir/final.mdl $srcdir/HCLG.fst $srcdir/words.txt
    exit 1
fi    
if [ "$web_stage" -eq 2 ]; then
    echo "web docoding"
    $decoder $silence_weighting_opts \
          --config=$online_config \
          --verbose=2 \
	   --frames-per-chunk=$frames_per_chunk \
          --min-active=$min_active --max-active=$max_active --beam=$beam --lattice-beam=$lattice_beam \
          $srcdir/final.mdl $srcdir/HCLG.fst $srcdir/words.txt
    exit 1
fi    

if [ "$web_stage" -eq 3 ]; then
    echo "web docoding"
    $decoder $silence_weighting_opts \
          --frames-per-chunk=$frames_per_chunk \
          --extra-left-context-initial=$extra_left_context_initial \
          $frame_subsampling_opt \
          --config=$online_config \
          --verbose=2 \
          --min-active=$min_active --max-active=$max_active --beam=$beam --lattice-beam=$lattice_beam \
          --acoustic-scale=$acwt $srcdir/final.mdl $srcdir/HCLG.fst $srcdir/words.txt \
          $datadir
    exit 1
fi    

if [ "$web_stage" -eq 4 ]; then
    echo "web docoding"
    $decoder $silence_weighting_opts --do-endpointing=$do_endpointing \
          --frames-per-chunk=$frames_per_chunk \
          --extra-left-context-initial=$extra_left_context_initial \
          --online=$online \
          $frame_subsampling_opt \
          --config=$online_config \
          --verbose=2 \
          --min-active=$min_active --max-active=$max_active --beam=$beam --lattice-beam=$lattice_beam \
          --acoustic-scale=$acwt --word-symbol-table=$srcdir/words.txt \
          $srcdir/final.mdl $srcdir/HCLG.fst $spk2utt_rspecifier "$wav_rspecifier" \
          "$lat_wspecifier"   
    exit 1
fi    


if [ "$#" -ne 1 ]; then
  echo "just Decoding without options"
  $decoder 
else
  echo "decoding with options"
  $decoder $silence_weighting_opts --do-endpointing=$do_endpointing \
	--frames-per-chunk=$frames_per_chunk \
	--extra-left-context-initial=$extra_left_context_initial \
	--online=$online \
	$frame_subsampling_opt \
	--config=$online_config \
	--verbose=2 \
	--min-active=$min_active --max-active=$max_active --beam=$beam --lattice-beam=$lattice_beam \
	--acoustic-scale=$acwt --word-symbol-table=$srcdir/words.txt \
	$srcdir/final.mdl $srcdir/HCLG.fst $spk2utt_rspecifier "$wav_rspecifier" \
	"$lat_wspecifier"
fi

	
LMWT=11.0
wip=0.0
#rescore=true
rescore=false
if $rescore ; then
	echo "##### LM rescore ####"
	
	oldlm=$srcdir/G.fst
	newlm=$srcdir/G.carpa
	oldlmcommand="fstproject --project_output=true $oldlm |"

	utils=/home/lucasjo/_tools_/kaldi/egs/wsj/s5/utils
	symtab=$srcdir/words.txt
	lattice-lmrescore --lm-scale=-1.0 \
		"ark:gunzip -c $dir/lat.1.gz|" "$oldlmcommand" ark:- |\
		lattice-lmrescore-const-arpa --lm-scale=1.0 ark:- "$newlm" ark:- |\
		lattice-scale --inv-acoustic-scale=$LMWT ark:- ark:- |\
		lattice-add-penalty --word-ins-penalty=$wip ark:- ark:- |\
		lattice-1best ark:- "ark:|gzip -c > $dir/lmre_lat.1.gz"

	# below is to show best-path decoding result in text
	lattice-copy "ark:gunzip -c $dir/lmre_lat.1.gz|" ark:- |\
		lattice-best-path --word-symbol-table=$symtab ark:- ark,t:-
fi
# rm -f wav.scp spk2utt

