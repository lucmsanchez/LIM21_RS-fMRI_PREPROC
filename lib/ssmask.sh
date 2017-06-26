#!/usr/bin/env bash

set -x
printf "\n\n==============================================\n\n"
echo $0

in=$1     #t1
in[1]=$2  #t1
in[2]=$3  #mask
out=$4    #t1-masked
out[1]=$5 #t1-masked


3dcalc \
	-verbose \
	-a        ${in%%.*} \
	-b        ${in[2]} \
	-expr     'a*abs(b-1)' \
	-prefix   ${out%%.*} 

