#!/usr/bin/env bash

#: OLD CODE =============================================================

## Iniciar Relatório de qualidade
#for j in ${!ID[@]}; do
#cd ${steppath[$j]}
#if [ ! -f "report.${ID[j]}.html" ]; then
#cat << EOF > report.${ID[j]}.html
#<HTML>
#<HEAD>
#<TITLE>Relatório de Qualidade de ${ID[j]}</TITLE>
#<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
#</HEAD> 
#<body>
#<h1>Relatório de Controle de Qualidade -- ${ID[j]}</h1>
#<p>&nbsp;</p>
#<!--index-->
#<h3>Conteúdo:</h3>
#<ul>
#<li><h3><a href="#qc1">QC1 - Imagem RS raw</a></h3></li>
#<li><h3><a href="#qc2">QC2 - Imagem T1 raw</a></h3></li>
#<li><h3><a href="#qc3">QC3 - RS Motion Correction</a></h3></li>
#<li><h3><a href="#qc4">QC4 - T1 vc. SS mask</a></h3></li>
#<li><h3><a href="#qc5">QC5 - Checagem de alinhamento T1 vs. RS</a></h3></li>
#<li><h3><a href="#qc6">QC6 - Checagem de normalização T1 e RS vs. MNI</a></h3></li>
#<li><h3><a href="#qc7">QC7 - Checagem de segmentação</a></h3></li>
#<li><h3><a href="#qc8">QC8 - Imagem RS final</a></h3></li>
#</ul>
#<!--index-->
#<p>&nbsp;</p>
#<center>
#<!--QC1-->
#<!--QC2-->
#<!--QC3-->
#<!--QC4-->
#<!--QC5-->
#<!--QC6-->
#<!--QC7-->
#<!--QC8-->
#<!--QC9-->
#<!--QC10-->
#<!--QC11-->
#<!--QC12-->
#</center>
#</body>
#</HTML>
#EOF
#fi
#cd $pwd
#done


#: PROCESS ARGUMENTS ====================================================
usage() {
    echo "ARGUMENTS:"
    echo " $0 --subjects <Subject ID>" 
    echo 

}

#startS=1
#stopS=12
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -s|--subjects)
    subs="$2"
    shift # past argument
    ;;
    -a|--start)
    startS="$2"
    shift # past argument
    ;;
	-o|--stop)
    arg="$2"
	stopS=$((arg + 1))
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
export fsl5=fsl5.0-
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
  cd ${ppath}
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
        printf "INPUT $i MODIFIED. DELETING OUTPUT AND RUNING SCRIPT AGAIN. \n" 
        for o in ${out[@]}; do 
          rm ${o}* 2> /dev/null; 
        done
        go=1
      else
        echo "OUTPUT ALREADY EXISTS. MOVING TO NEXT STEP."; go=0; ex=0
      fi
    else
      if [ ! $c -eq 0 ]; then
        printf "OUTPUT CORRUPTED. DELETING OUTPUT AND RUNING SCRIPT AGAIN. \n"
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
	cd $path
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
  cd $pwd
}

#: START =======================================================================
fold -s <<-EOF

RS-fMRI Preprocessing pipeline
--------------------------------------

RUNTIME: $(date)

EOF


# Check existence of the --subjects argument
# Next step: check for consistency
if [ ! -z $subs ]; then  
  if [ ! -f $subs ]; then
    echo "Subjects ID file not found"
    exit
  fi
else 
  if [ -f preproc.sbj ]; then
    echo "Subjects ID file not specified. Local file preproc.sbj will be used."
    subs=preproc.sbj
  else
    echo "Subjects ID file not specified" 
	usage
    exit
  fi
fi  

# Create the variables ID and index using Subjects ID file
# ID;visit;t1_file;rs_file;log_file;mask_file
subs=preproc.sbj
oldIFS="$IFS"
IFS=$'\n' pID=($(<${subs}))
IFS="$oldIFS"
for j in ${!pID[@]}; do
	VID[$j]=$(echo ${pID[$j]} | cut -d ";" -f-2)
done
#echo ${VID[@]}

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

# Check of nifti files of the indicated Subjects
echo
echo "Searching for neuroimaging files:"
a=0
for v in ${VID[@]}; do 
	echo -n "${v%%;*} V${v##*;}  ... " 
	file=$(grep "${v}" $subs | cut -d ";" -f 3 | xargs find . -name)
	if [ ! -z "$file"  ]; then
		printf "T1" 
	else
		printf "(T1 not found)"; a=$((a + 1))
	fi
	file=$(grep "${v}" $subs | cut -d ";" -f 4 | xargs find . -name)
	if [ ! -z "$file" ]; then 
		printf " RS" 
	else
		printf " (RS not found)"; a=$((a + 1))
	fi
	file=$(grep "${v}" $subs | cut -d ";" -f 5 | xargs find . -name)
	if [ ! -z "$file" ]; then 
		printf " log" 
	else
		printf " (log not found)"; a=$((a + 1))
	fi
	file=$(grep "${v}" $subs | cut -d ";" -f 6 | xargs find . -name)
	if [ ! -z "$file"  ]; then
		printf " mask" 
	else
		printf " (mask not found)"; a=$((a + 1))
	fi
	printf "\n"
done
echo

if [ ! $a -eq 0 ]; then
    echo "Some images were not found. Aborting..." | fold -s ; echo
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

# Start big loop
for v in ${VID[@]}; do
	# Create loop variables
	cd $path
	id=${v%%;*}
	vis=V${v##*;}
	ppath=$path/PREPROC/$id
	file_t1=$(grep "${v}" $subs | cut -d ";" -f 3 2> /dev/null)
	file_t12=${file_t1%%.nii}
	file_rs=$(grep "${v}" $subs | cut -d ";" -f 4 2>  /dev/null)
	file_rs2=${file_rs%%.nii}
	file_log=$(grep "${v}" $subs | cut -d ";" -f 5 2>  /dev/null)
	file_mask=$(grep "${v}" $subs | cut -d ";" -f 6 2> /dev/null)
	log=preproc_${id}_${vis}.log

	# Create folders
  	[ -d $ppath ] || mkdir $ppath

	# Copy input files to processing folder
	echo
	echo "==================================================================="
	echo SUBJECT $id
	echo VISIT $vis
	echo "==================================================================="
	echo 
	echo "Copying input files to $ppath"
	for ii in $file_t1 $file_rs $file_log $file_mask; do
		echo "		$ii" # | tee &> $log
		[ ! -f $ppath/$ii ] && \
		wp=$(find . -name $ii 2> /dev/null) && \
		rp=$ppath/$ii && \
		cp $wp $rp 2> /dev/null
 	done
	echo

	S=${startS:-1}
	until [ "$S" = "${stopS:-21}" ]; do
		case $S in
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
				#echo $? 
				if [ $? -eq 0 ]; then
		  			../../bin/aztec.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=2 || continue 2
				elif [ $? -eq 1 ]; then
					S=2
				else
					continue 2
				fi
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
				if [ $? -eq 0 ]; then
		  			../../bin/tshift.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=3 || continue 2
				elif [ $? -eq 1 ]; then
					S=3
				else
					continue 2
				fi
				;;
			3 ) #: MOTION CORRECTION =============================
				# Declare inputs (array "in") and outputs (array "out")				
				unset in out
				in=tshift_${file_rs2}+orig.HEAD
				in[1]=tshift_${file_rs2}+orig.BRIK
				out=volreg_${file_rs2}+orig.HEAD
				out[1]=volreg_${file_rs2}+orig.BRIK
				out[2]=volreg_${file_rs2}.1D
				# Run modular script
				echo -n "S3 - MC> "
				open.node;
				if [ $? -eq 0 ]; then
		  			../../bin/volreg.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=QC1 || continue 2
				elif [ $? -eq 1 ]; then
					S=QC1
				else
					continue 2
				fi
				;;
			QC1 ) #: QC1 - MOTION CORRECTION =============================
				# Declare inputs (array "in") and outputs (array "out")				
				unset in out
				in=volreg_${file_rs2}.1D
				out=m_qc1_${file_rs2}.jpg
				# Run modular script
				echo -n "QC1 - MC> "
				open.node;
				if [ $? -eq 0 ]; then
		  			../../bin/qc-volreg.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=4 || continue 2
				elif [ $? -eq 1 ]; then
					S=4
				else
					continue 2
				fi
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
				if [ $? -eq 0 ]; then
		  			../../bin/3dwarp.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=5 || continue 2
				elif [ $? -eq 1 ]; then
					S=5
				else
					continue 2
				fi
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
				if [ $? -eq 0 ]; then
		  			../../bin/3dzeropad.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=6 || continue 2
				elif [ $? -eq 1 ]; then
					S=6
				else
					continue 2
				fi
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
				if [ $? -eq 0 ]; then
		  			../../bin/3dresample.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=7 || continue 2
				elif [ $? -eq 1 ]; then
					S=7
				else
					continue 2
				fi
				;;
			7 ) #: S7 - SSMASK =============================
				# Declare inputs (array "in") and outputs (array "out")				
				unset in out
				in=${file_t1}
				in[1]=${file_mask}
				out=SS_${file_t12}+orig.HEAD
				out[1]=SS_${file_t12}+orig.BRIK
				# Run modular script
				echo -n "S7 - SSMASK> "
				open.node;
				if [ $? -eq 0 ]; then
		  			../../bin/ssmask.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=8 || continue 2
				elif [ $? -eq 1 ]; then
					S=8
				else
					continue 2
				fi
				;;
			8 ) #: S8 - DEOBLIQUE T1 =============================
				# Declare inputs (array "in") and outputs (array "out")				
				unset in out
				in=SS_${file_t12}+orig.HEAD
				in[1]=SS_${file_t12}+orig.BRIK
				out=warp_${file_t12}+orig.HEAD
				out[1]=warp_${file_t12}+orig.BRIK
				# Run modular script
				echo -n "S8 - DEOB> "
				open.node;
				if [ $? -eq 0 ]; then
		  			../../bin/3dwarp.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=9 || continue 2
				elif [ $? -eq 1 ]; then
					S=9
				else
					continue 2
				fi
				;;
			9 ) #: S9 - REORIENT T1 TO TEMPLATE =============================
				# Declare inputs (array "in") and outputs (array "out")				
				unset in out
				in=warp_${file_t12}+orig.HEAD
				in[1]=warp_${file_t12}+orig.BRIK
				out=resample_${file_t12}+orig.HEAD
				out[1]=resample_${file_t12}+orig.BRIK
				# Run modular script
				echo -n "S9 - RESAM> "
				open.node;
				if [ $? -eq 0 ]; then
		  			../../bin/3dresample.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=10 || continue 2
				elif [ $? -eq 1 ]; then
					S=10
				else
					continue 2
				fi
				;;
			10 ) #: S10 - Align center T1 TO TEMPLATE =============================
				# Declare inputs (array "in") and outputs (array "out")				
				unset in out
				in=resample_${file_t12}+orig.HEAD
				in[1]=resample_${file_t12}+orig.BRIK
				in[3]=../../template/$template.BRIK.gz
				out=resample_${file_t12}_shft+orig.HEAD
				out[1]=resample_${file_t12}_shft+orig.BRIK
				out[2]=resample_${file_t12}_shft.1D
				# Run modular script
				echo -n "S10 - ALT1TEMP> "
				open.node;
				if [ $? -eq 0 ]; then
		  			../../bin/align-t1temp.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=11 || continue 2
				elif [ $? -eq 1 ]; then
					S=11
				else
					continue 2
				fi
				;;
			11 ) #: S11 - Unifize T1 =============================
				# Declare inputs (array "in") and outputs (array "out")				
				unset in out
				in=resample_${file_t12}_shft+orig.HEAD
				in[1]=resample_${file_t12}_shft+orig.BRIK
				out=unifize_${file_t12}+orig.HEAD
				out[1]=unifize_${file_t12}+orig.BRIK
				# Run modular script
				echo -n "S11 - UNIFIZE> "
				open.node;
				if [ $? -eq 0 ]; then
		  			../../bin/3dunifize.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=12 || continue 2
				elif [ $? -eq 1 ]; then
					S=12
				else
					continue 2
				fi
				;;
			12 ) #: S12 - ALIGN CENTER fMRI-T1 =============================
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
				if [ $? -eq 0 ]; then
		  			../../bin/align-rst1.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=13 || continue 2
				elif [ $? -eq 1 ]; then
					S=13
				else
					continue 2
				fi
				;;
			13 ) #: S13 - COREGISTER fMRI-T1 =============================
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
				if [ $? -eq 0 ]; then
		  			../../bin/coreg.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=QC2 || continue 2
				elif [ $? -eq 1 ]; then
					S=QC2
				else
					continue 2
				fi
				;;
			QC2 ) #: QC2 - COREG QC  =============================
				# Declare inputs (array "in") and outputs (array "out")				
				unset in out
				in=resample_${file_rs2}_shft+orig.HEAD
				in[1]=resample_${file_rs2}_shft+orig.BRIK
				in[2]=unifize_${file_t12}_al+orig.HEAD
				in[3]=unifize_${file_t12}_al+orig.BRIK
				out=m1_qc2_${file_t12}.jpg
				out[1]=m2_qc2_${file_t12}.jpg
				# Run modular script
				echo -n "QC2 - COREG> "
				open.node;
				if [ $? -eq 0 ]; then
		  			../../bin/qc-coreg.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=14 || continue 2
				elif [ $? -eq 1 ]; then
					S=14
				else
					continue 2
				fi
				;;
			14 ) #: S14 - NORMALIZE T1 to TEMP =============================
				# Declare inputs (array "in") and outputs (array "out")				
				unset in out
				in=unifize_${file_t12}_al+orig.HEAD
				in[1]=unifize_${file_t12}_al+orig.BRIK
				in[2]=../../template/$template.BRIK.gz
				out=MNI_${file_t12}+tlrc.HEAD
				out[1]=MNI_${file_t12}+tlrc.BRIK
				out[2]=MNI_${file_t12}_WARP*
				out[3]=MNI_${file_t12}_Allin.aff12.1D
				out[4]=MNI_${file_t12}_Allin.nii
				# Run modular script
				echo -n "S14 - NORMT1> "
				open.node;
				if [ $? -eq 0 ]; then
		  			../../bin/norm-t1.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=15 || continue 2
				elif [ $? -eq 1 ]; then
					S=15
				else
					continue 2
				fi
				;;
			15 ) #: S15 - NORMALIZE fMRI to T1 WARP =============================
				# Declare inputs (array "in") and outputs (array "out")				
				unset in out
				in=resample_${file_rs2}_shft+orig.HEAD
				in[1]=resample_${file_rs2}_shft+orig.BRIK
				in[2]=MNI_${file_t12}_WARP*
				in[3]=MNI_${file_t12}_WARP*
				in[4]=../../template/$template.BRIK.gz
				out=MNI_${file_rs2}+tlrc.HEAD
				out[1]=MNI_${file_rs2}+tlrc.BRIK
				# Run modular script
				echo -n "S15 - NORMRS> "
				open.node;
				if [ $? -eq 0 ]; then
		  			../../bin/norm-rs.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=QC3 || continue 2
				elif [ $? -eq 1 ]; then
					S=QC3
				else
					continue 2
				fi
				;;
			QC3 ) #: QC3 - NORMALIZATION =============================
				# Declare inputs (array "in") and outputs (array "out")				
				unset in out
				in=MNI_${file_rs2}+tlrc.HEAD
				in[1]=MNI_${file_rs2}+tlrc.BRIK
				in[2]=MNI_${file_t12}+tlrc.HEAD
				in[3]=MNI_${file_t12}+tlrc.BRIK
				in[4]=../../template/$template.BRIK.gz
				out=m1_qc3_MNI_${file_t12}.jpg
				out[1]=m2_qc3_MNI_${file_t12}.jpg
				out[2]=m3_qc3_MNI_${file_t12}.jpg
				out[3]=m4_qc3_MNI_${file_t12}.jpg
				out[4]=m5_qc3_MNI_${file_t12}.jpg
				out[5]=m6_qc3_MNI_${file_t12}.jpg
				out[6]=m7_qc3_MNI_${file_t12}.jpg
				# Run modular script
				echo -n "S15 - NORMRS> "
				open.node;
				if [ $? -eq 0 ]; then
		  			../../bin/qc-norm.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=16 || continue 2
				elif [ $? -eq 1 ]; then
					S=16
				else
					continue 2
				fi
				;;
			16 ) #: S16 - T1 SEGMENTATION =============================
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
				if [ $? -eq 0 ]; then
		  			../../bin/seg-t1.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=17 || continue 2
				elif [ $? -eq 1 ]; then
					S=17
				else
					continue 2
				fi
				;;
			17 ) #: S17 - RS SEGMENTATION  =============================
				# Declare inputs (array "in") and outputs (array "out")				
				unset in out
				in=resample_${file_rs2}_shft+orig.HEAD
				in[1]=resample_${file_rs2}_shft+orig.BRIK
				in[2]= CSF_${file_t12}+orig.HEAD
				in[3]= CSF_${file_t12}+orig.BRIK
				in[4]= WM_${file_t12}+orig.HEAD
				in[5]= WM_${file_t12}+orig.BRIK
				out=CSF_${file_t12}.signal.1D
				out[1]=WM_${file_t12}.signal.1D
				# Run modular script
				echo -n "S17 - RSSEG> "
				open.node;
				if [ $? -eq 0 ]; then
		  			../../bin/seg-rs.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=21 || continue 2
				elif [ $? -eq 1 ]; then
					S=21
				else
					continue 2
				fi
				;;
			QC4 ) #: QC4 - SEGMENTATION  =============================
				unset in out
				in=unifize_${file_t12}_al+orig.HEAD
				in[1]=unifize_${file_t12}_al+orig.BRIK
				in[2]= CSF_${file_t12}+orig.HEAD
				in[3]= CSF_${file_t12}+orig.BRIK
				in[4]= WM_${file_t12}+orig.HEAD
				in[5]= WM_${file_t12}+orig.BRIK
				out=m1_qc4_${file_t12}.jpg
				out[1]=m2_qc4_${file_t12}.jpg
				# Run modular script
				echo -n "QC4 - SEG> "
				open.node;
				if [ $? -eq 0 ]; then
		  			../../bin/qc-seg.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=18 || continue 2
				elif [ $? -eq 1 ]; then
					S=18
				else
					continue 2
				fi
				;;
			18 ) #: S18 - RS FILTERING  =============================
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
				if [ $? -eq 0 ]; then
		  			../../bin/3dbandpass.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=19 || continue 2
				elif [ $? -eq 1 ]; then
					S=19
				else
					continue 2
				fi
				;;
			19 ) #: S19 - RS SMOOTHING =============================
				# Declare inputs (array "in") and outputs (array "out")				
				unset in out
				in=bandpass_${file_rs2}+tlrc.HEAD
				in[1]=bandpass_${file_rs2}+tlrc.BRIK
				out=merge_${file_rs2}+tlrc.HEAD
				out[1]=merge_${file_rs2}+tlrc.BRIK
				# Run modular script
				echo -n "S19 - MERGE> "
				open.node;
				if [ $? -eq 0 ]; then
		  			../../bin/3dmerge.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=20 || continue 2
				elif [ $? -eq 1 ]; then
					S=20
				else
					continue 2
				fi
				;;
			20 ) #: S20 - RS MOTIONCENSOR  =============================
				# Declare inputs (array "in") and outputs (array "out")				
				unset in out
				in=merge_${file_rs2}+tlrc.HEAD
				in[1]=merge_${file_rs2}+tlrc.BRIK
				in[2]=volreg_${file_rs2}.1D
				in[3]=${file_rs}
				out=censor_${file_rs2}+tlrc.HEAD
				out[1]=censor_${file_rs2}+tlrc.HEAD
				# Run modular script
				echo -n "S20 - CENSOR> "
				open.node;
				if [ $? -eq 0 ]; then
		  			../../bin/motioncensor.sh ${in[@]} ${out[@]} &>> $log
					close.node && S=21 || continue 2
				elif [ $? -eq 1 ]; then
					S=21
				else
					continue 2
				fi
				;;
			esac
		done
	done
exit


#=================================================================================
#======================================================================================
#======================================================================================
#======================================================================================
#======================================================================================
#======================================================================================
#======================================================================================


