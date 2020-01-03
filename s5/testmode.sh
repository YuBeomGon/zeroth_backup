
#cd ~/libsimplewebm/libwebm/mkvparser/
#./mkvbuild.sh
#
#cd ../../
#c++ -c *.cpp
#ar rcs libsimplewebm.a *.o
#
#sudo cp libsimplewebm.a /usr/lib/x86_64-linux-gnu/libsimplewebm.a
cd ~/kaldi/src/
make -j 8

date=$(date +'%F-%H-%M')
echo start at $date

zdir=~/kaldi/egs/zeroth/s5
testflag=1

if [ ! -d testmode ];then
    mkdir testmode
fi
#test data prepare, 
cd ~/data/test/
#user.list and addr.list for pcm audio file
./data_prep_test.sh
#trans.txt for transcript text file
./data_prep_test1.sh $zdir

#cp $zidr/testmode/trans.txt

#trans.txt -> rawCorpus.1
#original transcription text normalization/tokenization, input : rawCorpus.1 output: normedCorpus.1
cd $zdir/data/local/lm
./data_normalize.sh $zdir

#using morfessor, input : normedCorpus.1 -> morfessor -> normedCorpus.1
cd $zdir
local/test_seg.sh

#get decoded text data using kaldi test mode
cd $zdir
if [ $testflag -eq 1 ];then
    echo "test mode is doing"
    ./web_decode_testmode.sh
else
    echo "online decoding is doing"
    ./web_decode.sh
fi

#compute wer between normedCorpus.1 and decoded.txt
cd ~/kaldi/src
tdir=~/data/test
#cp $zdir/testmode/normedCorpus.1 $zdir/testmode/normedCorpus.txt
bin/compute-wer-test --text --mode=present ark:$zdir/testmode/normedCorpus.1 ark:$tdir/decoded.txt

date=$(date +'%F-%H-%M')
echo ends at $date

exit 1
#gdb ../../../src/online2bin/beom-test core

