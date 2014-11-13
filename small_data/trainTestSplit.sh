head -n27 smallContradiction.txt |tail -n11 | awk '{print "CONTRADICTION\t"$0}'> smallContradiction_trial.txt
head -n27 smallEntailment.txt |tail -n11 | awk '{print "ENTAILMENT\t"$0}'> smallEntailment_trial.txt
head -n77 smallNeutral.txt |tail -n32 | awk '{print "NEUTRAL\t"$0}'> smallNeutral_trial.txt

tail -n11 smallContradiction.txt | awk '{print "CONTRADICTION\t"$0}'> smallContradiction_test.txt 
tail -n11 smallEntailment.txt | awk '{print "ENTAILMENT\t"$0}'> smallEntailment_test.txt
tail -n32 smallNeutral.txt | awk '{print "NEUTRAL\t"$0}'> smallNeutral_test.txt

head -n16 smallEntailment.txt | awk '{print "ENTAILMENT\t"$0}'> smallEntailment_train.txt 
head -n16 smallContradiction.txt | awk '{print "CONTRADICTION\t"$0}'> smallContradiction_train.txt 
head -n45 smallNeutral.txt | awk '{print "NEUTRAL\t"$0}'> smallNeutral_train.txt 

rm small_train.txt
rm small_trial.txt
rm small_test.txt

cat ./*_train* > small_train.txt
cat ./*_test* > small_test.txt
cat ./*_trial* > small_trial.txt

cd /user/sbowman/parser-install/stanford-parser-full-2014-01-04

#javac ParseImageFlickr.java -cp ./stanford-parser.jar:./stanford-parser-sources.jar:/u/nlp/data/StanfordCoreNLPModels/stanford-lexparser-models-current.jar:stanford-corenlp-3.3.1.jar:stanford-corenlp-3.3.1-sources.jar:/u/nlp/data/StanfordCoreNLPModels/stanford-corenlp-models-current.jar:guava-18.0.jar

#java -cp ./stanford-parser.jar:./stanford-parser-sources.jar:/u/nlp/data/StanfordCoreNLPModels/stanford-lexparser-models-current.jar:stanford-corenlp-3.3.1.jar:stanford-corenlp-3.3.1-sources.jar:/u/nlp/data/StanfordCoreNLPModels/stanford-corenlp-models-current.jar:guava-18.0.jar:. ParseImageFlickr ~/scr/vector-entailment/small_data/small_train.txt  > ~/scr/vector-entailment/small_data/small_train_parsed.txt 

#java -cp ./stanford-parser.jar:./stanford-parser-sources.jar:/u/nlp/data/StanfordCoreNLPModels/stanford-lexparser-models-current.jar:stanford-corenlp-3.3.1.jar:stanford-corenlp-3.3.1-sources.jar:/u/nlp/data/StanfordCoreNLPModels/stanford-corenlp-models-current.jar:guava-18.0.jar:. ParseImageFlickr ~/scr/vector-entailment/small_data/small_trial.txt  > ~/scr/vector-entailment/small_data/small_trial_parsed.txt 

java -cp ./stanford-parser.jar:./stanford-parser-sources.jar:/u/nlp/data/StanfordCoreNLPModels/stanford-lexparser-models-current.jar:stanford-corenlp-3.3.1.jar:stanford-corenlp-3.3.1-sources.jar:/u/nlp/data/StanfordCoreNLPModels/stanford-corenlp-models-current.jar:guava-18.0.jar:. ParseImageFlickr ~/scr/vector-entailment/small_data/small_test.txt  > ~/scr/vector-entailment/small_data/small_test_parsed.txt 

