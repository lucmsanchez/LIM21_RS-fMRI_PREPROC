#!bin/bash

source config
lista=(`cat "$pathpi"/subs.txt`)	

cd "$pathpi"
echo
echo "===================================================================="
echo "========= Aplicando etapa Motion censoring às imagens ============"
echo "===================================================================="
echo
for i in "${lista[@]}"
do
	echo "Aplicando em $i..."

	echo
	echo "Create Framewise Displacement (FD) censor"
	echo
	# take the temporal derivative of each vector (done as first backward difference)
	1d_tool.py \
	-infile motioncorrection_"$i".1d \
	-derivative \
	-write "$i"_RS.deltamotion.1D

	# calculate total framewise displacement (sum of six parameters)
	1deval \
	-a "$i"_RS.deltamotion.1D'[0]' \
	-b "$i"_RS.deltamotion.1D'[1]' \
	-c "$i"_RS.deltamotion.1D'[2]' \
	-d "$i"_RS.deltamotion.1D'[3]' \
	-e "$i"_RS.deltamotion.1D'[4]' \
	-f "$i"_RS.deltamotion.1D'[5]' \
	-expr '100*sind(abs(a)/2) + 100*sind(abs(b)/2) + 100*sind(abs(c)/2) + abs(d) + abs(e) + abs(f)' \
	> "$i"_RS.deltamotion.FD.1D

	# create temporal mask (1 = extreme motion)
	1d_tool.py \
	-infile "$i"_RS.deltamotion.FD.1D \
	-extreme_mask -1 0.5 \
	-write "$i"_RS.deltamotion.FD.extreme0.5.1D

	# create temporal mask (0 = extreme motion)
	1deval -a "$i"_RS.deltamotion.FD.extreme0.5.1D \
	-expr 'not(a)' \
	> "$i"_RS.deltamotion.FD.moderate0.5.1D

	# temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
	1deval \
	-a "$i"_RS.deltamotion.FD.moderate0.5.1D \
	-b "$i"_RS.deltamotion.FD.moderate0.5.1D'{1..$,0}' \
	-expr 'ispositive(a + b - 1)' \
	> "$i"_RS.deltamotion.FD.moderate0.5.n.1D

	# temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
	1deval \
	-a "$i"_RS.deltamotion.FD.moderate0.5.n.1D \
	-b "$i"_RS.deltamotion.FD.moderate0.5.n.1D'{0,0..$}' \
	-expr 'ispositive(a + b - 1)' \
	> "$i"_RS.deltamotion.FD.moderate0.5.n.n.1D

	# temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
	1deval \
	-a "$i"_RS.deltamotion.FD.moderate0.5.n.n.1D \
	-b "$i"_RS.deltamotion.FD.moderate0.5.n.n.1D'{0,0..$}' \
	-expr 'ispositive(a + b - 1)' \
	> "$i"_RS.deltamotion.FD.moderate0.5.n.n.n.1D


	echo "Create DVARS censor"
	echo
	# normalize and scale the BOLD to percent signal change
	# find the mean
	3dTstat \
	-mean \
	-prefix meanBOLD_"$i" \
	RS_"$i".nii
	# scale BOLD signal to percent change
	3dcalc \
	-a RS_"$i".nii \
	-b meanBOLD_"$i"+orig \
	-expr "(a/b) * 100" \
	-prefix "$i"_RS_scaled
	# temporal derivative of the frames
	3dcalc \
	-a "$i"_RS_scaled+orig \
	-b 'a[0,0,0,-1]' \
	-expr '(a - b)^2' \
	-prefix "$i"_RS.backdif2
	#Extract brain mask
	3dAutomask \
	-prefix "$i".auto_mask.brain \
	RS_"$i".nii
	# average data from each frame (inside brain mask)
	3dmaskave \
	-mask "$i".auto_mask.brain+orig \
	-quiet "$i"_RS.backdif2+orig \
	> "$i"_RS.backdif2.avg.1D
	# square root to finally get DVARS
	1deval \
	-a "$i"_RS.backdif2.avg.1D \
	-expr 'sqrt(a)' \
	> "$i"_RS.backdif2.avg.dvars.1D
	# mask extreme (1 = extreme motion)
	1d_tool.py \
	-infile "$i"_RS.backdif2.avg.dvars.1D \
	-extreme_mask -1 5 \
	-write "$i"_RS.backdif2.avg.dvars.extreme5.1D
	# mask extreme (0 = extreme motion)
	1deval \
	-a "$i"_RS.backdif2.avg.dvars.extreme5.1D \
	-expr 'not(a)' \
	> "$i"_RS.backdif2.avg.dvars.moderate5.1D
	# temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
	1deval \
	-a "$i"_RS.backdif2.avg.dvars.moderate5.1D \
	-b "$i"_RS.backdif2.avg.dvars.moderate5.1D'{1..$,0}' \
	-expr 'ispositive(a + b - 1)' \
	> "$i"_RS.backdif2.avg.dvars.moderate5.n.1D
	# temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 2)
	1deval \
	-a "$i"_RS.backdif2.avg.dvars.moderate5.n.1D \
	-b "$i"_RS.backdif2.avg.dvars.moderate5.n.1D'{0,0..$}' \
	-expr 'ispositive(a + b - 1)' \
	> "$i"_RS.backdif2.avg.dvars.moderate5.n.n.1D
	# temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 3)
	1deval \
	-a "$i"_RS.backdif2.avg.dvars.moderate5.n.n.1D \
	-b "$i"_RS.backdif2.avg.dvars.moderate5.n.n.1D'{0,0..$}' \
	-expr 'ispositive(a + b - 1)' \
	> "$i"_RS.backdif2.avg.dvars.moderate5.n.n.n.1D

	##########
	# Integrate FD and DVARS censoring
	# (only frames censored on both will be excluded, as in Power et al., 2012)

	# FD censor OR DVARS censor
	1deval \
	-a "$i"_RS.deltamotion.FD.moderate0.5.n.n.n.1D \
	-b "$i"_RS.backdif2.avg.dvars.moderate5.n.n.n.1D \
	-expr 'or(a, b)' \
	> "$i"_powerCensorIntersection.1D

	#############
	#Apply censor file in the final preprocessed image (after temporal filtering and spatial blurring)
	afni_restproc.py -apply_censor bfrpdrt_RS_MNI_"$i"+tlrc "$i"_powerCensorIntersection.1D cbfrpdrt_RS_MNI_"$i"


	echo
	echo
done 
