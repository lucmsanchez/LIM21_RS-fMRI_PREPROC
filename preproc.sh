#!/usr/bin/env bash
#set -x
#: PARSE ARGUMENTS ====================================================
usage() {
    echo "ARGUMENTS:"
    echo " $0 --id <id> --vist <visit code> --t1 <imagem t1> --rs <imagem rs> --log <physlog file>>" 
    echo 

}

#startS=1
#stopS=12
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --t1 )
    t1="$2"
    shift # past argument
	;;
	--log )
    log="$2"
    shift # past argument
    ;;
	--rs )
    rs="$2"
    shift # past argument
    ;;
	--id )
    ident="$2"
    shift # past argument
    ;;
	--visit )
    visit="$2"
    shift # past argument
    ;;
    --start )
    startS="$2"
    shift # past argument
    ;;
	--stop )
    stopS="$2"
    shift # past argument
    ;;
    *)
     echo "Syntax error:'$1' unknown'" >&2
     usage
     exit       # unknown option
    ;;
esac
shift # past argument or value
done

#: DECLARE VARIABLES ===========================================================
#fsl5=""
template="MNI152_1mm_uni+tlrc"



#: DECLARE FUNCTIONS ===========================================================
check () {
  if command -v $1 > /dev/null; then
    echo "OK"
  else
    echo "Not found on \$PATH"
fi
}

open.node () {
  local a=0; local b=0; local c=0; local d=0
  local go=1; local ex=0
  #
  for i in ${in[@]}; do
      [ ! -f $i ] && echo "INPUT $i not found" && a=$((a + 1))
	for o in ${out[@]}; do
    	[ ! -f $o ] && b=$((b + 1)) || c=$((c + 1))
        [ $o -ot $i ] && d=$((d + 1))
   	done
  done
  #echo $a $b $c $d
  if [ $a -eq 0 ]; then
    if [ $b -eq 0 ]; then 
      if [ ! $d -eq 0 ]; then
        printf "INPUT MODIFIED. DELETING OUTPUT AND RUNING SCRIPT AGAIN.\n             " 
        for o in ${out[@]}; do 
          rm ${o} 2> /dev/null; 
        done
        go=1
      else
        echo "OUTPUT ALREADY EXISTS. MOVING TO NEXT STEP."; go=0; ex=0
      fi
    else
      if [ ! $c -eq 0 ]; then
        printf "OUTPUT CORRUPTED. DELETING OUTPUT AND RUNING SCRIPT AGAIN. \n             "
        for o in ${out[@]}; do 
        rm ${o}* 2> /dev/null; done
        go=1
      else
        go=1
      fi
    fi
  else
    go=0; ex=1
  fi  

  if [ $go -eq 1 ]; then
    return 0 # run script
  else
	if [ $ex -eq 0 ]; then
    	return 1 # skip step
	else
		return 2 # skip subject
	fi
  fi
}

close.node () {
  local a=0
    for o in ${out[@]}; do
    	[ -f $o ] ||  a=$((a + 1)) 
	done
    if [ ! $a -eq 0 ]; then
      	printf "Error: Could not process subject %s, consult the log. \n" "${id}"
		return 1
    else
      	printf "Processing of subject %s realized with success! \n" "${id}"
		return 0
    fi
}

#: START =======================================================================
fold -s <<-EOF
 

RS-fMRI Preprocessing pipeline
--------------------------------

EOF

# Check if all required softwares are installed on $PATH
fold -s <<-EOF

Required Software and Packages:
GNU bash           ...$(check bash)
AFNI               ...$(check 3dTshift)
FSL                ...$(check "$fsl5"fast)
Python             ...$(check python)
ImageMagick        ...$(check convert)
Xvfb               ...$(check Xvfb)
MATLAB             ...$(check matlab)
  SPM5
  aztec

WARNING: Any missing required software will cause the script to stop!
EOF

co=0
for c in bash 3dTshift "$fsl5"fast python convert avconv Xvfb perl sed; do
[ ! $(command -v $c) ] && co=$((co + 1))
done
if [ ! $co -eq 0 ];then
	exit
fi


# Search for the template in local folder
temp=$(find . -name "$template*")
if [ ! -z "$temp" ];then
  [ ! -d template ] && mkdir template 
  if [ ! -f "template/${temp[0]}" ]; then
  for tp in $temp; do
    mv $tp template 2> /dev/null
  done
  fi
else 
  echo "Template $template not found. Searching on afni folder"
  cp /usr/share/afni/atlases/"$template"* . 2> /dev/null
  temp=$(find . -name "$template*")
  if [ ! -z "$temp" ];then
    [ ! -d template ] && mkdir template 
    for tp in $temp; do
      mv $tp template 2> /dev/null
    done
  else
    echo "Template not found"
    exit
  fi
fi

path=($PWD)

# Create folder for the processing steps
[ -d PREPROC ] || mkdir PREPROC


#: DATA INPUT ====================================================================

id=${ident}
vis=${visit}
ppath=$path/PREPROC/$id
file_t1=${t1}
file_t12=${file_t1%%.nii}
file_rs=${rs}
file_rs2=${file_rs%%.nii}
file_log=${log}
log=preproc_${id}_${vis}.log

# Create folders
[ -d $ppath ] || mkdir $ppath

cd $ppath
	
echo
echo "==================================================================="
echo SUBJECT $id
echo VISIT $vis
echo "==================================================================="
echo 

S=${startS:-0}
until [ "$S" = "${stopS:-20}" ]; do
case $S in
	0 ) #: S0 - PREPARE ==========================================
		# Copy input files to processing folder
		echo "Copying input files to $ppath"
		for ii in $file_t1 $file_rs $file_log; do
			echo "		$ii" 
			[ ! -f $ppath/$ii ] && \
			wp=$(find $path -name $ii 2> /dev/null) && \
			rp=$ppath/$ii && \
			cp $wp $rp 2> /dev/null
	 	done
		echo
		S=1
		;;
	1 ) #: S1 - AZTEC ==========================================
		# Declare inputs (array "in") and outputs (array "out")
		unset in out
		in=$file_rs
		in[1]=$file_log
		out=aztec_${file_rs2}+orig.HEAD
		out[1]=aztec_${file_rs2}+orig.BRIK
		out[2]=aztecX.1D
		# Run modular script
		echo -n "S1 - AZTEC> "
		open.node; 
		case $? in
			0 ) 
			../../lib/aztec.sh ${in[@]} ${out[@]} &>> $log
			close.node && S=2 || exit
			;;
			1 ) S=2 ;;
			2 ) exit ;;
		esac 
		;;
	2 ) #: SLICE TIMING CORRECTION =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=aztec_${file_rs2}+orig.HEAD
		in[1]=aztec_${file_rs2}+orig.BRIK
		out=tshift_${file_rs2}+orig.HEAD
		out[1]=tshift_${file_rs2}+orig.BRIK
		# Run modular script
		echo -n "S2 - STC> "
		open.node; 
		case $? in
			0 ) 
			3dTshift \
				-tpattern seq+z \
			  	-prefix ${out%%.*} \
			  	-Fourier \
			  	${in%%.*} &>> $log
			close.node && S=3 || exit
		;;
			1 ) 
			S=3
		;;
			2 ) exit ;;
		esac
		;;
	3 ) #: MOTION CORRECTION =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=tshift_${file_rs2}+orig.HEAD
		in[1]=tshift_${file_rs2}+orig.BRIK
		out=volreg_${file_rs2}+orig.HEAD
		out[1]=volreg_${file_rs2}+orig.BRIK
		out[2]=volreg_${file_rs2}.1D
		# Run modular script on
		echo -n "S3 - MC> "
		open.node;
		case $? in
			0 ) 
			3dvolreg \
				-prefix ${out%%.*} \
				-base 100 \
				-zpad 2 \
				-twopass \
				-Fourier \
				-1Dfile ${out[2]} \
				${in%%.*}   &>> $log
			close.node && S=QC1 || exit
		;;
			1 ) 
			S=QC1
		;;
			2 ) exit ;;
		esac
		;;
	QC1 ) #: QC1 - MOTION CORRECTION =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=volreg_${file_rs2}.1D
		out=qc1_m1_${file_rs2}.jpg
		# Run modular script
		echo -n "QC1 - MC> "
		open.node; 
		case $? in
			0 ) 
			../../lib/qc-volreg.sh ${in[@]} ${out[@]} &>> $log
			S=4
			close.node || continue 1
			;;
			1 ) S=4 ;;
			2 ) S=4
			continue 1
			;;
		esac
		;;
  	4 ) #: S4 - DEOBLIQUE =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=volreg_${file_rs2}+orig.HEAD
		in[1]=volreg_${file_rs2}+orig.BRIK
		out=warp_${file_rs2}+orig.HEAD
		out[1]=warp_${file_rs2}+orig.BRIK
		# Run modular script
		echo -n "S4 - DEOB> "
		open.node;
		case $? in
			0 ) 
			3dWarp \
				-deoblique \
				-prefix  ${out%%.*} \
				${in%%.*}  &>> $log
			close.node && S=5 || exit
		;;
			1 ) 
			S=5
		;;
			2 ) exit ;;
		esac
		;;
	5 ) #: S4 - HOMOGENIZE RS =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=warp_${file_rs2}+orig.HEAD
		in[1]=warp_${file_rs2}+orig.BRIK		
		out=zeropad_${file_rs2}+orig.HEAD
		out[1]=zeropad_${file_rs2}+orig.BRIK
		# Run modular script
		echo -n "S5 - ZPAD> "
		open.node;
		case $? in
			0 ) 
			3dZeropad \
				-RL 90 \
				-AP 90 \
				-IS 60 \
				-prefix ${out%%.*} \
				${in%%.*} &>> $log
			close.node && S=6 || exit
		;;
			1 ) 
			S=6
		;;
			2 ) exit ;;
		esac
		;;
	6 ) #: S6 - REORIENT RS TO TEMPLATE =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=zeropad_${file_rs2}+orig.HEAD
		in[1]=zeropad_${file_rs2}+orig.BRIK		
		out=resample_${file_rs2}+orig.HEAD
		out[1]=resample_${file_rs2}+orig.BRIK
		# Run modular script
		echo -n "S6 - RESAM> "
		open.node;
		case $? in
			0 ) 
			3dresample \
				-orient "RPI" \
				-prefix ${out%%.*} \
				-inset ${in%%.*} &>> $log
			close.node && S=7 || exit
		;;
			1 ) 
			S=7
		;;
			2 ) exit ;;
		esac
		;;
	7 ) #: S7 - DEOBLIQUE T1 =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=${file_t1}
		out=warp_${file_t12}+orig.HEAD
		out[1]=warp_${file_t12}+orig.BRIK
		# Run modular script
		echo -n "S8 - DEOB> "
		open.node;
		case $? in
			0 ) 
			3dWarp \
				-deoblique \
				-prefix  ${out%%.*} \
				${in}  &>> $log
			close.node && S=8 || exit
		;;
			1 ) 
			S=8
		;;
			2 ) exit ;;
		esac
		;;
	8 ) #: S8 - REORIENT T1 TO TEMPLATE =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=warp_${file_t12}+orig.HEAD
		in[1]=warp_${file_t12}+orig.BRIK
		out=resample_${file_t12}+orig.HEAD
		out[1]=resample_${file_t12}+orig.BRIK
		# Run modular script
		echo -n "S9 - RESAM> "
		open.node;
		case $? in
			0 ) 
			3dresample \
				-orient "RPI" \
				-prefix ${out%%.*} \
				-inset ${in%%.*} &>> $log
			close.node && S=9 || exit
		;;
			1 ) 
			S=9
		;;
			2 ) exit ;;
		esac
		;;
	9 ) #: S9 - Align center T1 TO TEMPLATE =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=resample_${file_t12}+orig.HEAD
		in[1]=resample_${file_t12}+orig.BRIK
		in[2]=../../template/$template.BRIK.gz
		out=resample_${file_t12}_shft+orig.HEAD
		out[1]=resample_${file_t12}_shft+orig.BRIK
		out[2]=resample_${file_t12}_shft.1D
		# Run modular script
		echo -n "S10 - ALT1TEMP> "
		open.node;
		case $? in
			0 ) 
			   @Align_Centers \
					-base ${in[2]} \
					-dset ${in%%.*} &>> $log
			close.node && S=10 || exit
		;;
			1 ) 
			S=10
		;;
			2 ) exit ;;
		esac
		;;
	10 ) #: S10 - Unifize T1 =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=resample_${file_t12}_shft+orig.HEAD
		in[1]=resample_${file_t12}_shft+orig.BRIK
		out=unifize_${file_t12}+orig.HEAD
		out[1]=unifize_${file_t12}+orig.BRIK
		# Run modular script
		echo -n "S11 - UNIFIZE> "
		open.node;
		case $? in
			0 ) 
			   3dUnifize \
					-prefix ${out%%.*} \
					-input ${in%%.*}  &>> $log
			close.node && S=11 || exit
		;;
			1 ) 
			S=11
		;;
			2 ) exit ;;
		esac
		;;
	11 ) #: S11 - ALIGN CENTER fMRI-T1 =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=unifize_${file_t12}+orig.HEAD
		in[1]=unifize_${file_t12}+orig.BRIK
		in[2]=resample_${file_rs2}+orig.HEAD
		in[3]=resample_${file_rs2}+orig.BRIK
		out=resample_${file_rs2}_shft+orig.HEAD
		out[1]=resample_${file_rs2}_shft+orig.HEAD
		# Run modular script
		echo -n "S12 - ALRST1> "
		open.node;
		case $? in
			0 ) 
			     @Align_Centers \
					-cm \
					-base ${in%%.*} \
					-dset ${in[2]%%.*}  &>> $log
			close.node && S=12 || exit
		;;
			1 ) 
			S=12
		;;
			2 ) exit ;;
		esac
		;;
	12 ) #: S12 - COREGISTER fMRI-T1 =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=resample_${file_rs2}_shft+orig.HEAD
		in[1]=resample_${file_rs2}_shft+orig.HEAD
		in[2]=unifize_${file_t12}+orig.HEAD
		in[3]=unifize_${file_t12}+orig.BRIK
		out=unifize_${file_t12}_al+orig.HEAD
		out[1]=unifize_${file_t12}_al+orig.BRIK
		out[2]=unifize_${file_t12}_al_mat.aff12.1D
		# Run modular script
		echo -n "S13 - COREG> "
		open.node;
		case $? in
			0 ) 
		     align_epi_anat.py \
				-anat ${in[2]%%.*} \
				-epi  ${in%%.*} \
				-epi_base 100 \
				-anat_has_skull no \
				-volreg off \
				-tshift off \
				-deoblique off   &>> $log
			close.node && S=QC2 || exit
		;;
			1 ) 
			S=QC2
		;;
			2 ) exit ;;
		esac
		;;
	QC2 ) #: QC2 - COREG QC  =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=resample_${file_rs2}_shft+orig.HEAD
		in[1]=resample_${file_rs2}_shft+orig.BRIK
		in[2]=unifize_${file_t12}_al+orig.HEAD
		in[3]=unifize_${file_t12}_al+orig.BRIK
		out=qc2_m1_${file_t12}.jpg
		out[1]=qc2_m2_${file_t12}.jpg
		# Run modular script
		echo -n "QC2 - COREG> "
		open.node; 
		case $? in
			0 ) 
			../../lib/qc-coreg.sh ${in[@]} ${out[@]} &>> $log
			S=14
			close.node || continue 1
			;;
			1 ) 
			S=13
			;;
			2 )
			S=13
			continue 1
			;;
			esac
		;;
	13 ) #: S13 - NORMALIZE T1 to TEMP =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=unifize_${file_t12}_al+orig.HEAD
		in[1]=unifize_${file_t12}_al+orig.BRIK
		in[2]=../../template/$template.BRIK.gz
		out=MNI_${file_t12}+tlrc.HEAD
		out[1]=MNI_${file_t12}+tlrc.BRIK
		out[2]=MNI_${file_t12}_WARP+tlrc.HEAD
		out[3]=MNI_${file_t12}_WARP+tlrc.BRIK
		out[4]=MNI_${file_t12}_Allin.aff12.1D
		out[5]=MNI_${file_t12}_Allin.nii
		# Run modular script
		echo -n "S14 - NORMT1> "
		open.node;
		case $? in
			0 ) 
		     3dQwarp \
			  -prefix ${out%%+*} \
			  -blur 0 3 \
			  -base ${in[2]} \
			  -allineate \
			  -source ${in%%.*}  &>> $log
			close.node && S=14 || exit
		;;
			1 ) 
			S=14
		;;
			2 ) exit ;;
		esac
		;;
	14 ) #: S14 - NORMALIZE fMRI to T1 WARP =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=resample_${file_rs2}_shft+orig.HEAD
		in[1]=resample_${file_rs2}_shft+orig.BRIK
		in[2]=MNI_${file_t12}_WARP+tlrc.HEAD
		in[3]=MNI_${file_t12}_WARP+tlrc.BRIK
		in[4]=../../template/$template.BRIK.gz
		out=MNI_${file_rs2}+tlrc.HEAD
		out[1]=MNI_${file_rs2}+tlrc.BRIK
		# Run modular script
		echo -n "S15 - NORMRS> "
		open.node;
		case $? in
			0 ) 
		     3dNwarpApply \
				-source ${in%%.*} \
				-nwarp ${in[2]%%.*} \
				-master ${in[4]} \
				-newgrid 3 \
				-prefix ${out%%.*} &>> $log
			close.node && S=QC3 || exit
		;;
			1 ) 
			S=QC3
		;;
			2 ) exit ;;
		esac
		;;
	QC3 ) #: QC3 - NORMALIZATION =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=MNI_${file_rs2}+tlrc.HEAD
		in[1]=MNI_${file_rs2}+tlrc.BRIK
		in[2]=MNI_${file_t12}+tlrc.HEAD
		in[3]=MNI_${file_t12}+tlrc.BRIK
		in[4]=../../template/$template.BRIK.gz
		out=qc3_m1_MNI_${file_t12}.jpg
		out[1]=qc3_m2_MNI_${file_t12}.jpg
		out[2]=qc3_m3_MNI_${file_t12}.jpg
		out[3]=qc3_m4_MNI_${file_t12}.jpg
		out[4]=qc3_m5_MNI_${file_t12}.jpg
		out[5]=qc3_m6_MNI_${file_t12}.jpg
		# Run modular script
		echo -n "QC3 - NORM> "
		open.node; 
		case $? in
			0 ) 
			../../lib/qc-norm.sh ${in[@]} ${out[@]} &>> $log
			S=16
			close.node || continue 1
		;;
			1 ) 
			S=15 ;;
		2 )
			S=15
			continue 1 ;;
		esac
		;;
	15 ) #: S15 - T1 SEGMENTATION =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=unifize_${file_t12}_al+orig.HEAD
		in[1]=unifize_${file_t12}_al+orig.BRIK
		out=CSF_${file_t12}+orig.HEAD
		out[1]=CSF_${file_t12}+orig.BRIK
		out[2]=WM_${file_t12}+orig.HEAD
		out[3]=WM_${file_t12}+orig.BRIK
		# Run modular script
		echo -n "S16 - T1SEG> "
		open.node; 
		case $? in
			0 ) 
			../../lib/seg-t1.sh ${in[@]} ${out[@]} &>> $log
			close.node && S=16 || exit
		;;
			1 ) 
			S=16
		;;
			2 ) exit ;;
		esac
		;;
	16 ) #: S16 - RS SEGMENTATION  =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=resample_${file_rs2}_shft+orig.HEAD
		in[1]=resample_${file_rs2}_shft+orig.BRIK
		in[2]=CSF_${file_t12}+orig.HEAD
		in[3]=CSF_${file_t12}+orig.BRIK
		in[4]=WM_${file_t12}+orig.HEAD
		in[5]=WM_${file_t12}+orig.BRIK
		out=CSF_${file_t12}.signal.1D
		out[1]=WM_${file_t12}.signal.1D
		# Run modular script
		echo -n "S17 - RSSEG> "
		open.node; 
		case $? in
			0 ) 
			../../lib/seg-rs.sh ${in[@]} ${out[@]} &>> $log
			close.node && S=QC4 || exit
		;;
			1 ) 
			S=QC4
		;;
			2 ) exit ;;
		esac
		;;
	QC4 ) #: QC4 - SEGMENTATION  =============================
		unset in out
		in=unifize_${file_t12}_al+orig.HEAD
		in[1]=unifize_${file_t12}_al+orig.BRIK
		in[2]=CSF_${file_t12}+orig.HEAD
		in[3]=CSF_${file_t12}+orig.BRIK
		in[4]=WM_${file_t12}+orig.HEAD
		in[5]=WM_${file_t12}+orig.BRIK
		out=qc4_m1_${file_t12}.jpg
		out[1]=qc4_m2_${file_t12}.jpg
		# Run modular script
		echo -n "QC4 - SEG> "
		open.node; 
		case $? in
			0 ) 
			../../lib/qc-seg.sh ${in[@]} ${out[@]} &>> $log
			S=18
			close.node || continue 1
		;;
			1 ) 
			S=17 ;;
		2 )
			S=17
			continue 1 ;;
		esac
		;;
	17 ) #: S17 - RS FILTERING  =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=MNI_${file_rs2}+tlrc.HEAD
		in[1]=MNI_${file_rs2}+tlrc.BRIK
		in[2]=volreg_${file_rs2}.1D
		in[3]=CSF_${file_t12}.signal.1D
		in[4]=WM_${file_t12}.signal.1D
		out=bandpass_${file_rs2}+tlrc.HEAD
		out[1]=bandpass_${file_rs2}+tlrc.BRIK
		# Run modular script
		echo -n "S18 - BPASS> "
		open.node;
		case $? in
			0 ) 
		    3dBandpass \
			  -band 0.01 0.08 \
			  -despike \
			  -ort ${in[2]} \
			  -ort ${in[3]} \
			  -ort ${in[4]} \
			  -prefix ${out%%.*} \
			  -input ${in%%.*}  &>> $log
			close.node && S=18 || exit
		;;
			1 ) 
			S=18
		;;
			2 ) exit ;;
		esac
		;;
	18 ) #: S18 - RS SMOOTHING =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=bandpass_${file_rs2}+tlrc.HEAD
		in[1]=bandpass_${file_rs2}+tlrc.BRIK
		out=merge_${file_rs2}+tlrc.HEAD
		out[1]=merge_${file_rs2}+tlrc.BRIK
		# Run modular script
		echo -n "S19 - MERGE> "
		open.node;
		case $? in
			0 ) 
		     3dmerge \
				-1blur_fwhm 6 \
				-doall \
				-prefix ${out%%.*} \
				${in%%.*} &>> $log
			close.node && S=19 || exit
		;;
			1 ) 
			S=19
		;;
			2 ) exit ;;
		esac
		;;
	19 ) #: S19 - RS MOTIONCENSOR  =============================
		# Declare inputs (array "in") and outputs (array "out")				
		unset in out
		in=merge_${file_rs2}+tlrc.HEAD
		in[1]=merge_${file_rs2}+tlrc.BRIK
		in[2]=volreg_${file_rs2}.1D
		in[3]=${file_rs}
		out=censor_${file_rs2}+tlrc.HEAD
		out[1]=censor_${file_rs2}+tlrc.BRIK
		# Run modular script
		echo -n "S20 - CENSOR> "
		open.node; 
		case $? in
			0 ) 
			../../lib/motioncensor.sh ${in[@]} ${out[@]} &>> $log
			close.node && S=20 || exit
		;;
			1 ) 
			S=20
		;;
			2 ) exit ;;
		esac
		;;
esac
done  

cd $path

exit


#=================================================================================
#======================================================================================
#======================================================================================
#======================================================================================
#======================================================================================
#======================================================================================
#======================================================================================


