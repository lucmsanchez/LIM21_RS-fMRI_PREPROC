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
fsl5=fsl5.0-
TR=2
template="MNI152_1mm_uni+tlrc"
blur=6
cost="lpc"


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

WARNING: Any missing required software will cause the script to stop
EOF

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
					close.node && S=21 || continue 2
				elif [ $? -eq 1 ]; then
					S=21
				else
					continue 2
				fi
				;;
esac;done;done;exit



#: QC4 ========================================================================
printf "=============================QC 4==================================\n\n"
for j in ${!ID[@]}; do
qc.open -e "QC 4"                                    \
        -i "unifize.T1.${ID[j]}.nii"      \
        -o "m.over.SS.T1.${ID[j]}.png m.overz.T1.${ID[j]}.mp4 m.overy.T1.${ID[j]}.mp4 m.overx.T1.${ID[j]}.mp4"              
if [ $? -eq 0 ]; then
./bin/qc-bet.sh
fi; qc.close
done
input.error


#: ALIGN CENTER fMRI-T1 ======================================================
printf "\n=======================ALIGN CENTER fMRI-T1=====================\n\n"
for j in ${!ID[@]}; do
  fromRS
  inputs "${out[$j]}" "SS.T1.${ID[j]}+orig"
  outputs "resample.RS.${ID[j]}_shft+orig" "resample.RS.${ID[j]}_shft.1D"
  echo -n "${ID[j]}> "
  if open.node "ALIGN CENTER fMRI-T1"; then
  ./bin/align-rst1.sh
  fi; close.node
  toRS
done 
input.error
echo

#: COREGISTER fMRI-T1 ======================================================
printf "\n=======================COREGISTER fMRI-T1=====================\n\n"
for j in ${!ID[@]}; do
  inputs "${out[$j]}" "SS.T1.${ID[j]}+orig"
  outputs "SS.T1.${ID[j]}_al+orig" "SS.T1.${ID[j]}_al_mat.aff12.1D"
  echo -n "${ID[j]}> "
  if open.node "COREGISTER fMRI-T1"; then
./bin/coreg.sh
  fi; close.node
done 
input.error
echo

#: QC5 ========================================================================
printf "=============================QC 5==================================\n\n"
for j in ${!ID[@]}; do
qc.open -e "QC 5"                                    \
        -i "resample.RS.${ID[j]}_shft+orig SS.T1.${ID[j]}_al+orig"      \
        -o "m.over.SS.T1.${ID[j]}_al.jpg m.over2.SS.T1.${ID[j]}_al.jpg"              
if [ $? -eq 0 ]; then

./bin/qc-coreg.sh

fi; qc.close
done
input.error

[ $break -eq 3 ] && echo "Interrompendo script a pedido do usuário" && exit

#: NORMALIZE T1 TO TEMPLATE ======================================================
printf "\n=======================NORMALIZE T1 TO TEMPLATE=====================\n\n"
for j in ${!ID[@]}; do 
  inputs "${out[$j]}"
  outputs "MNI.T1.${ID[j]}" "MNI.T1.${ID[j]}_WARP" 
  cp.inputs "${template}.HEAD" "${template}.BRIK.gz"
  echo -n "${ID[j]}> "
  if open.node "NORMALIZE T1 TO TEMPLATE"; then

./bin/norm-t1.sh

   fi; close.node
  toT1
done 
input.error
echo

#: fMRI SPATIAL NORMALIZATION ======================================================
printf "\n=======================fMRI SPATIAL NORMALIZATION=====================\n\n"
for j in ${!ID[@]}; do
  fromRS
  inputs "${out[$j]}" "${out_2[$j]}+tlrc"
  outputs "MNI.RS.${ID[j]}+tlrc"
  echo -n "${ID[j]}> "
  if open.node "fMRI SPATIAL NORMALIZATION"; then

./bin/norm-rs.sh

  fi; close.node
  toRS
done 
input.error
echo

#: QC6 ========================================================================

printf "=============================QC 6==================================\n\n"
for j in ${!ID[@]}; do
qc.open -e "QC 6"                                    \
        -i "MNI.RS.${ID[j]}+tlrc MNI.T1.${ID[j]}+tlrc"      \
        -o "m.overa.MNI.${ID[j]}.jpg m.overb.MNI.${ID[j]}.jpg m.overc.MNI.${ID[j]}.jpg m.overa2.MNI.${ID[j]}.jpg m.overb2.MNI.${ID[j]}.jpg m.overc2.MNI.${ID[j]}.jpg"              
if [ $? -eq 0 ]; then

./bin/qc-norm.sh

fi; qc.close
done
input.error

[ $break -eq 4 ] && echo "Interrompendo script a pedido do usuário" && exit

#: T1 SEGMENTATION ======================================================
printf "\n=======================T1 SEGMENTATION=====================\n\n"
for j in ${!ID[@]}; do
  fromT1
  inputs "SS.T1.${ID[j]}_al+orig"
  outputs "${ID[j]}.CSF+orig" "${ID[j]}.WM+orig"
  echo -n "${ID[j]}> "
  if open.node "T1 SEGMENTATION"; then
 
./bin/seg-t1.sh

  fi; close.node
done 
input.error
echo

# RS SEGMENTATION ======================================================
printf "\n=======================RS SEGMENTATION=====================\n\n"
for j in ${!ID[@]}; do
  inputs "resample.RS.${ID[j]}_shft+orig" "${out[$j]}" "${out_2[$j]}"
  outputs "${ID[j]}.CSF.signal.1d" "${ID[j]}.WM.signal.1d"
  echo -n "${ID[j]}> "
  if open.node "RS SEGMENTATION"; then
 
./bin/seg-rs.sh

  fi; close.node
done 
input.error
echo

#: QC7 ========================================================================
printf "=============================QC 7==================================\n\n"
for j in ${!ID[@]}; do
qc.open -e "QC 7"                                    \
        -i "${ID[j]}.WM+orig ${ID[j]}.CSF+orig SS.T1.${ID[j]}_al+orig"      \
        -o "m.over.seg.${ID[j]}.jpg m.over2.seg.${ID[j]}.jpg"              
if [ $? -eq 0 ]; then

./bin/qc-seg.sh

fi; qc.close
done
input.error

[ $break -eq 5 ] && echo "Interrompendo script a pedido do usuário" && exit

#: RS FILTERING ======================================================
printf "\n=======================RS FILTERING=====================\n\n"
for j in ${!ID[@]}; do
  fromRS
  inputs "${out[$j]}" "mc.${ID[j]}.1d" "${ID[j]}.CSF.signal.1d" "${ID[j]}.WM.signal.1d"
  outputs "bandpass.RS.${ID[j]}+tlrc" 
  echo -n "${ID[j]}> "
  if open.node "RS FILTERING"; then

./bin/3dbandpass.sh

  fi; close.node
done 
input.error
echo

#: RS SMOOTHING ======================================================
printf "\n=======================RS SMOOTHING=====================\n\n"
for j in ${!ID[@]}; do
  inputs "${out[$j]}" 
  outputs "merge.RS.${ID[j]}+tlrc"
  echo -n "${ID[j]}> "
  if open.node "RS SMOOTHING"; then

./bin/3dmerge.sh

  fi; close.node
done 
input.error
echo

if [ $censor -eq 1 ]; then
#: RS MOTIONCENSOR ======================================================
printf "\n=======================RS MOTIONCENSOR=====================\n\n"
for j in ${!ID[@]}; do
  inputs "${out[$j]}" "mc.${ID[j]}.1d" "RS.${ID[j]}.nii"
  outputs "censor.RS.${ID[j]}+tlrc"
  echo -n "${ID[j]}> "
  if open.node "RS MOTIONCENSOR"; then

./bin/motioncensor.sh

  fi; close.node
done 
input.error
echo
fi

#: QC8 ========================================================================
printf "=============================QC 8==================================\n\n"
for j in ${!ID[@]}; do
qc.open -e "QC 8"                                    \
        -i "${out[$j]}"      \
        -o "m.final.txt"              
if [ $? -eq 0 ]; then

./bin/qc-mc.sh

fi; qc.close
done
input.error
echo 

#: DATA OUTPUT ===================================================================
printf "\n=======================DATA OUTPUT=====================\n\n"
for j in ${!ID[@]}; do
  inputs "${out[$j]}" "SS.T1.${ID[j]}+orig" "preproc.${ID[j]}.log" "report.${ID[j]}.html"
  outputs "preproc.RS.${ID[j]}.nii" "SS.T1.${ID[j]}.nii" 
  echo -n "${ID[j]}> "
  if open.node "DATA OUTPUT"; then
( 3dAFNItoNIFTI -prefix ${out[j]} ${in[j]}
  3dAFNItoNIFTI -prefix ${out_2[j]} ${in_2[j]} ) &>> preproc.${ID[j]}.log
  fi; close.node
( rm -r OUTPUT/${ID[j]}/manual_skullstrip 
  file=$(find . -name "${out[j]}")
  cp -rf $file $pwd/OUTPUT/${ID[j]}/
  file=$(find . -name "${out_2[j]}")
  cp -rf $file $pwd/OUTPUT/${ID[j]}/  
  file=$(find . -name "${in_3[j]}")
  cp -rf $file $pwd/OUTPUT/${ID[j]}/ 
  file=$(find . -name "${in_4[j]}")
  cp -rf $file $pwd/OUTPUT/${ID[j]}/
  file=$(find . -name "m.*${ID[j]}*")
  [ ! -d $pwd/OUTPUT/${ID[j]}/report.media ] && mkdir $pwd/OUTPUT/${ID[j]}/report.media
  cp -rf ${file[@]} $pwd/OUTPUT/${ID[j]}/report.media
  sed -i "s/m\./report.media\/m\./g" $pwd/OUTPUT/${ID[j]}/${in_4[j]}
   ) &> /dev/null
done 
input.error
echo




#=================================================================================
#======================================================================================
#======================================================================================
#======================================================================================
#======================================================================================
#======================================================================================
#======================================================================================


