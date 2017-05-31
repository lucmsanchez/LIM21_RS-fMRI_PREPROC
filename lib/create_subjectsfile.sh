#!/usr/bin/env bash

dirs=`find "$1" -maxdepth 1 | grep -E '[0-9]{6}'`
subs=(`find "$1" -maxdepth 1 | grep -E '[0-9]{6}' | cut -d "/" -f 2`)

c=0
for d in ${dirs[@]}; do
	t1=`find $d -name "*-corr.nii" | cut -d "/" -f 3`
	rs=`find $d -name "*RS*.nii" | cut -d "/" -f 3`
	log=`find $d -name "*.log" | cut -d "/" -f 3`
	echo "CRAC_${subs[$c]}_1;$t1;$rs;$log" >> subjects.csv
	c=$((c+1))
done


