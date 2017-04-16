#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

in=$1
in[1]=$2
in[2]=$3
in[3]=$4
out=$5
out[1]=$6

### take the temporal derivative of each vector (done as first backward difference)
1d_tool.py \
    -infile ${in[2]} \
    -derivative \
    -write c."${in%%+*}"_RS.deltamotion.1D 

    ### calculate total framewise displacement (sum of six parameters)
    1deval \
    -a c."${in%%+*}"_RS.deltamotion.1D'[0]' \
    -b c."${in%%+*}"_RS.deltamotion.1D'[1]' \
    -c c."${in%%+*}"_RS.deltamotion.1D'[2]' \
    -d c."${in%%+*}"_RS.deltamotion.1D'[3]' \
    -e c."${in%%+*}"_RS.deltamotion.1D'[4]' \
    -f c."${in%%+*}"_RS.deltamotion.1D'[5]' \
    -expr '100*sind(abs(a)/2) + 100*sind(abs(b)/2) + 100*sind(abs(c)/2) + abs(d) + abs(e) + abs(f)' \
    > c."${in%%+*}"_RS.deltamotion.FD.1D

    ### create temporal mask (1 = extreme motion)
    1d_tool.py \
    -infile c."${in%%+*}"_RS.deltamotion.FD.1D \
    -extreme_mask -1 0.5 \
    -write c."${in%%+*}"_RS.deltamotion.FD.extreme0.5.1D

    ### create temporal mask (0 = extreme motion)
    1deval -a c."${in%%+*}"_RS.deltamotion.FD.extreme0.5.1D \
    -expr 'not(a)' \
    > c."${in%%+*}"_RS.deltamotion.FD.moderate0.5.1D

    ### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
    1deval \
    -a c."${in%%+*}"_RS.deltamotion.FD.moderate0.5.1D \
    -b c."${in%%+*}"_RS.deltamotion.FD.moderate0.5.1D'{1..$,0}' \
    -expr 'ispositive(a + b - 1)' \
    > c."${in%%+*}"_RS.deltamotion.FD.moderate0.5.n.1D

    ### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
    1deval \
    -a c."${in%%+*}"_RS.deltamotion.FD.moderate0.5.n.1D \
    -b c."${in%%+*}"_RS.deltamotion.FD.moderate0.5.n.1D'{0,0..$}' \
    -expr 'ispositive(a + b - 1)' \
    > c."${in%%+*}"_RS.deltamotion.FD.moderate0.5.n.n.1D

    ### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
    1deval \
    -a c."${in%%+*}"_RS.deltamotion.FD.moderate0.5.n.n.1D \
    -b c."${in%%+*}"_RS.deltamotion.FD.moderate0.5.n.n.1D'{0,0..$}' \
    -expr 'ispositive(a + b - 1)' \
    > c."${in%%+*}"_RS.deltamotion.FD.moderate0.5.n.n.n.1D

    ### normalize and scale the BOLD to percent signal change
    ### find the mean
    3dTstat \
    -mean \
    -prefix c.meanBOLD_"${in%%+*}" \
    ${in[3]}
    ### scale BOLD signal to percent change
    3dcalc \
    -a ${in[3]} \
    -b c.meanBOLD_"${in%%+*}"+orig \
    -expr "(a/b) * 100" \
    -prefix c."${in%%+*}"_RS_scaled
    ### temporal derivative of the frames--------------------------------------
    3dcalc \
    -a c."${in%%+*}"_RS_scaled+orig \
    -b 'a[0,0,0,-1]' \
    -expr '(a - b)^2' \
    -prefix c."${in%%+*}"_RS.backdif2
    ### Extract brain mask
    3dAutomask \
    -prefix c."${in%%+*}".auto_mask.brain \
    ${in[3]}
    ### average data from each frame (inside brain mask)------------------------
    3dmaskave \
    -mask c."${in%%+*}".auto_mask.brain+orig \
    -quiet c."${in%%+*}"_RS.backdif2+orig \
    > c."${in%%+*}"_RS.backdif2.avg.1D
    ### square root to finally get DVARS
    1deval \
    -a c."${in%%+*}"_RS.backdif2.avg.1D \
    -expr 'sqrt(a)' \
    > c."${in%%+*}"_RS.backdif2.avg.dvars.1D
    ### mask extreme (1 = extreme motion)
    1d_tool.py \
    -infile c."${in%%+*}"_RS.backdif2.avg.dvars.1D \
    -extreme_mask -1 5 \
    -write c."${in%%+*}"_RS.backdif2.avg.dvars.extreme5.1D
    ### mask extreme (0 = extreme motion)
    1deval \
    -a c."${in%%+*}"_RS.backdif2.avg.dvars.extreme5.1D \
    -expr 'not(a)' \
    > c."${in%%+*}"_RS.backdif2.avg.dvars.moderate5.1D
    ### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
    1deval \
    -a c."${in%%+*}"_RS.backdif2.avg.dvars.moderate5.1D \
    -b c."${in%%+*}"_RS.backdif2.avg.dvars.moderate5.1D'{1..$,0}' \
    -expr 'ispositive(a + b - 1)' \
    > c."${in%%+*}"_RS.backdif2.avg.dvars.moderate5.n.1D
    ### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 2)
    1deval \
    -a c."${in%%+*}"_RS.backdif2.avg.dvars.moderate5.n.1D \
    -b c."${in%%+*}"_RS.backdif2.avg.dvars.moderate5.n.1D'{0,0..$}' \
    -expr 'ispositive(a + b - 1)' \
    > c."${in%%+*}"_RS.backdif2.avg.dvars.moderate5.n.n.1D
    ### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 3)
    1deval \
    -a c."${in%%+*}"_RS.backdif2.avg.dvars.moderate5.n.n.1D \
    -b c."${in%%+*}"_RS.backdif2.avg.dvars.moderate5.n.n.1D'{0,0..$}' \
    -expr 'ispositive(a + b - 1)' \
    > c."${in%%+*}"_RS.backdif2.avg.dvars.moderate5.n.n.n.1D


    ### Integrate FD and DVARS censoring
    ### (only frames censored on both will be excluded, as in Power et al., 2012)

    ### FD censor OR DVARS censor
    1deval \
    -a c."${in%%+*}"_RS.deltamotion.FD.moderate0.5.n.n.n.1D \
    -b c."${in%%+*}"_RS.backdif2.avg.dvars.moderate5.n.n.n.1D \
    -expr 'or(a, b)' \
    > "${in%%+*}".powerCensorIntersection.1D 

### Apply censor file in the final preprocessed image (after temporal filtering and spatial blurring)
afni_restproc.py -apply_censor ${in%%.*} ${in%%+*}.powerCensorIntersection.1D ${out%%.*}  
    
rm c.*
