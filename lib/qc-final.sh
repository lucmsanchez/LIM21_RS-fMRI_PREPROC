#!/usr/bin/env bash

# $1 - volreg 1d
# $2 - power censor

# Censored TRs percent
cen=`cat $2 | awk '$1 != 1 {print}' | wc -l`
tt=`cat $2 | wc -l`
rcen=`echo "scale=3; $cen / $tt * 100" | bc`
echo $rcen
echo
ntr_censor=`cat $2 | grep 0 | wc -l`
tt=`cat $2 | wc -l`
frac=`ccalc $ntr_censor/$tt*100`
echo "TRs censored              : $ntr_censor"
echo "censor fraction           : $frac"

# average motion (per TR)
mmean=`3dTstat -prefix - -nzmean enorm_$1\\' 2> /dev/null | tail -n 1 `
echo "average motion (per TR)   : $mmean"

1deval -a enorm_$1 -b $2 -expr 'a*b' > rm.ec.1D
cmean=`3dTstat -prefix - -nzmean rm.ec.1D\\' 2> /dev/null | tail -n 1`
rm -f rm.ec*
echo "average censored motion   : $cmean"

disp=`1d_tool.py -infile $1 -show_max_displace -verb 0`
echo "max motion displacement   : $disp"

# compute the maximum motion displacement over all TR pairs
cdisp=`1d_tool.py -infile $1 -show_max_displace -censor_infile $2 -verb 0`
echo "max censored displacement : $cdisp"

exit

1d_tool.py -infile $1 -derivative  -collapse_cols euclidean_norm -write enorm_$1

1dplot -one '1D: 200@0.3' enorm_$1
# num TRs above mot limit
mcount=`1deval -a enorm_$1 -expr "step(a-0.3)"| awk '$1 != 0 {print}' | wc -l`

echo $mcount

1dplot -volreg -censor $2 $1
1dplot -censor $2 enorm_$1



3dToutcount -automask -fraction -polort 3 -legendre                     \
                pb00.$subj.r$run.tcat+orig > outcount.r$run.1D

    # censor outlier TRs per run, ignoring the first 0 TRs
    # - censor when more than 0.1 of automask voxels are outliers
    # - step() defines which TRs to remove via censoring
    1deval -a outcount.r$run.1D -expr "1-step(a-0.1)" > rm.out.cen.r$run.1D

1dplot -one '1D: 450@0.07' outcount.rall.1D
1deval -a outcount.rall.1D -expr 't*step(a-0.05)' | grep -v ' 0'

set mmean = `3dTstat -prefix - -mean $outlier_dset\\' | & tail -n 1`
echo "average outlier frac (TR) : $mmean"

set mcount = `1deval -a $outlier_dset -expr "step(a-$out_limit)"      \\
                        | awk '$1 != 0 {print}' | wc -l`
echo "num TRs above out limit   : $mcount"


3dAutomask -dilate 1 -prefix rm.mask_r$run pb04.$subj.r$run.blur+tlrc

# --------------------------------------------------
# create a temporal signal to noise ratio dataset 
#    signal: if 'scale' block, mean should be 100
#    noise : compute standard deviation of errts
3dTstat -mean -prefix rm.signal.all all_runs.$subj+tlrc"[$ktrs]"
3dTstat -stdev -prefix rm.noise.all errts.$subj.fanaticor+tlrc"[$ktrs]"
3dcalc -a rm.signal.all+tlrc                                               \
       -b rm.noise.all+tlrc                                                \
       -c full_mask.$subj+tlrc                                             \
       -expr 'c*a/b' -prefix TSNR.$subj 

eval 'set tsnr_ave = `3dmaskave -quiet -mask $mask_dset $tsnr_dset`' \
         >& /dev/null
    echo "TSNR average              : $tsnr_ave"

# ---------------------------------------------------
# compute and store GCOR (global correlation average)
# (sum of squares of global mean of unit errts)
3dTnorm -norm2 -prefix rm.errts.unit errts.$subj.fanaticor+tlrc
3dmaskave -quiet -mask full_mask.$subj+tlrc rm.errts.unit+tlrc             \
          > gmean.errts.unit.1D
3dTstat -sos -prefix - gmean.errts.unit.1D\' > out.gcor.1D
echo "-- GCOR = `cat out.gcor.1D`"

    set gcor_val = `cat $gcor_dset`
    echo "global correlation (GCOR) : $gcor_val"




 # check that dsets are okay before using them
      errs = 0
      emesg = 'cannot drive view_stats, skipping...'
      if self.check_for_dset('stats_dset', emesg): errs += 1
      if self.check_for_dset('mask_dset', emesg): errs += 1
      if errs: return 0

      sset = self.dsets.val('stats_dset')
      mset = self.dsets.val('mask_dset')

      txt = 'echo ' + UTIL.section_divider('view stats results',
                                           maxlen=60, hchar='-') + '\n\n'

      s1   = 'set pp = ( `3dBrickStat -slow -percentile 90 1 90 \\\n' \
             '            -mask %s %s"[0]"` )\n' % (mset.pv(), sset.pv())

      s2   = 'set thresh = $pp[2]\n'                                    \
             'echo -- thresholding F-stat at $thresh\n'

      aset = self.dsets.val('final_anat')
      if not self.check_for_dset('final_anat', ''):
         s3 = '     -com "SWITCH_UNDERLAY %s" \\\n'%aset.prefix
      else: s3 = ''

      s4  = \
       '# locate peak coords of biggest masked cluster and jump there\n'  \
       '3dcalc -a %s"[0]" -b %s -expr "a*b" \\\n'                         \
       '       -overwrite -prefix .tmp.F\n'  \
       'set maxcoords = ( `3dclust -1thresh $thresh -dxyz=1 1 2 .tmp.F+%s \\\n'\
       '       | & awk \'/^ / {print $14, $15, $16}\' | head -n 1` )\n'\
       'echo -- jumping to max coords: $maxcoords\n'                      \
       % (sset.pv(), mset.pv(), self.uvars.final_view)

      txt += '# get 90 percentile for thresholding in afni GUI\n'       \
             '%s'                                                       \
             '%s'                                                       \
             '\n'                                                       \
             '%s\n' % (s1, s2, s4)

      ac   = 'afni -com "OPEN_WINDOW A.axialimage"     \\\n'            \
             '     -com "OPEN_WINDOW A.sagittalimage"  \\\n'            \
             '%s'                                                       \
             '     -com "SWITCH_OVERLAY %s"   \\\n'                     \
             '     -com "SET_SUBBRICKS A 0 0 0"        \\\n'            \
             '     -com "SET_THRESHNEW A $thresh"      \\\n'            \
             '     -com "SET_DICOM_XYZ A $maxcoords"\n'                 \
             '\n' % (s3, sset.prefix)
      
      txt += '# start afni with stats thresholding at peak location\n'  \
             + ac

      txt += '\n'                                                      \
             'prompt_user -pause "                                 \\\n' \
             '   review: peruse statistical retsults               \\\n' \
             '      - thresholding Full-F at masked 90 percentile  \\\n' \
             '        (thresh = $thresh)                           \\\n' \
             '                                                     \\\n' \
             '   --- close afni and click OK when finished ---     \\\n' \
             '   "\n'                                                  \

      self.commands_drive += s1 + s2 + s4 + ac

      self.text_drive += txt + '\n\n'

      return 0
