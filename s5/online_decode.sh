#!/bin/bash


. ./cmd.sh
. ./path.sh
. utils/parse_options.sh

#copy graph, dml and configuration
#local/export.sh  # do just once at first time
#decode

srcdir=transcriptions/zeroth/
decodedir=transcriptions/online_decode/
local/decode.sh audio.flac $srcdir $decodedir
