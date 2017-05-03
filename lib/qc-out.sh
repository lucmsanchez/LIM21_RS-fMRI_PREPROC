#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1 		# raw RS nii
out=$4		# out raw 1D		
out[1]=$6		# jpg - out raw
out[2]=$7		# 1D out 

## OUTLIERS
# raw ouliers
3dToutcount -automask -fraction -polort 3 -legendre ${in} > ${out}

rmean=`3dTstat -prefix - -mean ${out}\\' | & tail -n 1`
echo "average outlier frac (TR) : $rmean"
rcount=`1deval -a ${out} -expr "step(a-0.1)" | awk '$1 != 0 {print}' | wc -l`
echo "num TRs above out limit   : $rcount"


1dplot -jpg ${out[2]} -one '1D: 200@0.07' ${out}
1dplot -jpg ${out[3]} -one '1D: 200@0.07' ${out[1]}

echo "$rmean;$fmean;$rcount;$fcount" > ${out[2]}

exit

3dAutomask -dilate 1 -prefix rm.mask_${in[2]%%.*} ${in[2]%%.*}

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
