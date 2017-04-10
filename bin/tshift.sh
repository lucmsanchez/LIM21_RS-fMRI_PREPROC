#!/usr/bin/env bash

3dTshift \
	-tpattern $ptn \
      	-prefix ${out[$j]} \
      	-Fourier \
      	${in[$j]} &>> preproc.${ID[j]}.log
