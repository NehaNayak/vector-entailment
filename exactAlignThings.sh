head -n1 sick_data/SICK_train_parsed.txt>sick_data/SICK_train_parsed_exactAlign.txt
awk 'NR>1' sick_data/SICK_train_parsed.txt | python alignmentPreprocessing/exactAlignConstituency.py | tr -s ' ' ' ' >> sick_data/SICK_train_parsed_exactAlign.txt

head -n1 sick_data/SICK_trial_parsed.txt>sick_data/SICK_trial_parsed_exactAlign.txt
awk 'NR>1' sick_data/SICK_trial_parsed.txt | python alignmentPreprocessing/exactAlignConstituency.py | tr -s ' ' ' ' >> sick_data/SICK_trial_parsed_exactAlign.txt

head -n1 sick_data/SICK_trial_parsed_noneg.txt>sick_data/SICK_trial_parsed_noneg_exactAlign.txt
awk 'NR>1' sick_data/SICK_trial_parsed_noneg.txt | python alignmentPreprocessing/exactAlignConstituency.py | tr -s ' ' ' ' >> sick_data/SICK_trial_parsed_noneg_exactAlign.txt

head -n1 sick_data/SICK_trial_parsed_lt18_parens.txt>sick_data/SICK_trial_parsed_lt18_parens_exactAlign.txt
awk 'NR>1' sick_data/SICK_trial_parsed_lt18_parens.txt | python alignmentPreprocessing/exactAlignConstituency.py | tr -s ' ' ' ' >> sick_data/SICK_trial_parsed_lt18_parens_exactAlign.txt

cat sick_data/SICK_trial_parsed_justneg.txt | python alignmentPreprocessing/exactAlignConstituency.py | tr -s ' ' ' ' >> sick_data/SICK_trial_parsed_justneg_exactAlign.txt

cat sick_data/SICK_trial_parsed_18plusparens.txt | python alignmentPreprocessing/exactAlignConstituency.py | tr -s ' ' ' ' >> sick_data/SICK_trial_parsed_18plusparens_exactAlign.txt
