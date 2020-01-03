zerodir=kaldi/egs/zeroth/s5/
homedir=/home/beomgon/
lmdir=data/local/lm
graphdir=exp/chain_rvb/tdnn1n_rvb_online/graph_tgsmall
testdir=test/models/korean/zeroth/

cd $graphdir
cp words.txt phones.txt HCLG.fst ~/$zerodir
wait
#scp words.txt phones.txt HCLG.fst beomgon@172.26.70.81:$homedir$zerodir$testdir
cd phones
cp word_boundary.int ~/$zerodir
#scp word_boundary.int beomgon@172.26.70.81:$homedir$zerodir$testdir
wait

cd ~/$zerodir
cd data/lang_nosp_test_tgsmall
cp G.fst ~/$zerodir
#scp G.fst beomgon@172.26.70.81:$homedir$zerodir$testdir

cd ~/$zerodir
scp words.txt phones.txt HCLG.fst word_boundary.int G.fst beomgon@172.26.70.81:$homedir$zerodir$testdir


