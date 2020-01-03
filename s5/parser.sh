
#cd ~/libsimplewebm/libwebm/mkvparser/
#./mkvbuild.sh
#
#cd ../../
#c++ -c *.cpp
#ar rcs libsimplewebm.a *.o
#
#sudo cp libsimplewebm.a /usr/lib/x86_64-linux-gnu/libsimplewebm.a
testflag=2
cd ~/kaldi/src/
make -j 12


cd ~/kaldi/egs/zeroth/s5/
rm core
if [ $testflag -eq 1 ];then
    echo "test mode is doing"
    ./web_decode_testmode.sh
else
    echo "online decoding is doing"
    ./web_decode.sh
fi


#gdb ../../../src/online2bin/beom-test core

