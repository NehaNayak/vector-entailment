sort -R SICK_train_parsed.txt|head -n100 | tr -s '()' ' ' | cut -f1,2,3 | awk '{print NR"\t"$0}'> handLabel.txt
cut -f1,3,4 handLabel.txt > handLabel_noLabel.txt
