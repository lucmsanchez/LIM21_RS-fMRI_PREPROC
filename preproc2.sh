#!/usr/bin/env bash

#: PROCESS ARGUMENTS ====================================================
usage() {
    echo "ARGUMENTS:"
    echo " $0 --subjects <Subject ID>" 
    echo 

}

break=0
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -s|--subjects)
    subs="$2"
    shift # past argument
    ;;
    -b|--break)
    break="$2"
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
ptn=seq+z
mcbase=100
gRL=90
gAP=90
gIS=60
template="MNI152_1mm_uni+tlrc"
betf=0.15
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
oldIFS="$IFS"
IFS=$'\n' ID=($(<${subs}))
IFS="$oldIFS"
index=${!ID[@]}


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

WARNING: There will be a problem during the execution of the script if any of the previus software are missing 
EOF

# Check of nifti files of the indicated Subjects
echo "Searching for neuroimaging files:"
a=0
for j in ${!ID[@]}; do 
	echo -n "${ID[j]}  ... " 
	file=$(find . -name "*_${ID[j]}_*_1.nii")
	if [ ! -z "$file"  ]; then
		printf "T1" 
	else
		printf "(T1 not found)"; a=$((a + 1))
	fi
	file=$(find . -name "*_${ID[j]}_*_2.nii")
	if [ ! -z "$file" ]; then 
		printf " RS" 
	else
		printf " (RS not found)"; a=$((a + 1))
	fi
	file=$(find . -name "*_${ID[j]}_*_2.log")
	if [ ! -z "$file" ]; then 
		printf " log" 
	else
		printf " (log not found)"; a=$((a + 1))
	fi
	file=$(find . -name "*_${ID[j]}_*_1.nii")
	if [ ! -z "$file"  ]; then
		printf "mask" 
	else
		printf "(mask not found)"; a=$((a + 1))
	fi
	printf "\n"
done
echo
if [ ! $a -eq 0 ]; then
    echo "Some images were not found or are not named following our standard: <site>_<project>_<ID>_<visit>_<type>.nii. Type: 1 = T1, 2 = RS" | fold -s ; echo
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

# Create folder for the processing steps
[ -d PREPROC ] || mkdir PREPROC
unset a; a=0
for j in ${!ID[@]}; do
  [ -d PREPROC/${ID[j]} ] || mkdir PREPROC/${ID[j]} 
  for ii in *_${ID[j]}_*_1.nii RS.${ID[j]}.nii RS.${ID[j]}.log; do
    [ ! -f DATA/${ID[j]}/$ii ] && wp=$(find . -name $ii) && rp=DATA/${ID[j]}/$ii && mv $wp $rp 2> /dev/null && a=$((a + 1))
  done
done
if [ ! $a -eq 0 ]; then 
  echo "O caminho das imagens não está conformado com o padrâo: DATA/<ID>/T1.<ID>.nii"
  echo "Conformando..."
  echo
fi

pwd=($PWD)

#: DATA INPUT ====================================================================
for j in ${!ID[@]}; do
  out[$j]=RS.${ID[j]}.nii
  steppath[$j]=DATA/${ID[j]}/preproc.results/
  [ ! -d ${steppath[$j]} ] && mkdir -p ${steppath[$j]} 2> /dev/null
  [ ! -f ${steppath[$j]}RS.${ID[j]}.nii ] && cp DATA/${ID[j]}/RS.${ID[j]}.nii ${steppath[$j]} 2> /dev/null
  [ ! -f ${steppath[$j]}T1.${ID[j]}.nii ] && cp DATA/${ID[j]}/T1.${ID[j]}.nii ${steppath[$j]} 2> /dev/null
  [ ! -f ${steppath[$j]}RS.${ID[j]}.log ] && cp DATA/${ID[j]}/RS.${ID[j]}.log ${steppath[$j]} 2> /dev/null
done

# Iniciar Relatório de qualidade
for j in ${!ID[@]}; do
cd ${steppath[$j]}
if [ ! -f "report.${ID[j]}.html" ]; then
cat << EOF > report.${ID[j]}.html
<HTML>
<HEAD>
<TITLE>Relatório de Qualidade de ${ID[j]}</TITLE>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
</HEAD> 
<body>
<h1>Relatório de Controle de Qualidade -- ${ID[j]}</h1>
<p>&nbsp;</p>
<!--index-->
<h3>Conteúdo:</h3>
<ul>
<li><h3><a href="#qc1">QC1 - Imagem RS raw</a></h3></li>
<li><h3><a href="#qc2">QC2 - Imagem T1 raw</a></h3></li>
<li><h3><a href="#qc3">QC3 - RS Motion Correction</a></h3></li>
<li><h3><a href="#qc4">QC4 - T1 vc. SS mask</a></h3></li>
<li><h3><a href="#qc5">QC5 - Checagem de alinhamento T1 vs. RS</a></h3></li>
<li><h3><a href="#qc6">QC6 - Checagem de normalização T1 e RS vs. MNI</a></h3></li>
<li><h3><a href="#qc7">QC7 - Checagem de segmentação</a></h3></li>
<li><h3><a href="#qc8">QC8 - Imagem RS final</a></h3></li>
</ul>
<!--index-->
<p>&nbsp;</p>
<center>
<!--QC1-->
<!--QC2-->
<!--QC3-->
<!--QC4-->
<!--QC5-->
<!--QC6-->
<!--QC7-->
<!--QC8-->
<!--QC9-->
<!--QC10-->
<!--QC11-->
<!--QC12-->
</center>
</body>
</HTML>
EOF
fi
cd $pwd
done


#: QC1 ========================================================================
printf "=============================QC 1==================================\n\n"
for j in ${!ID[@]}; do
qc.open -e "QC 1"                                    \
        -i "${out[$j]}"      \
        -o "m.outcount.${ID[j]}.jpg outcount.${ID[j]}.1D m.axial.RS.${ID[j]}.png m.slices.RS.${ID[j]}.png m.3d.${ID[j]}.mp4"              
if [ $? -eq 0 ]; then

./bin/qc1.sh

fi; qc.close
done
input.error
echo

#: QC2 ========================================================================
printf "=============================QC 2==================================\n\n"
for j in ${!ID[@]}; do
qc.open -e "QC 2"                                    \
        -i "T1.${ID[j]}.nii"      \
        -o "m.slices.T1.${ID[j]}.mp4  m.slices.T1.${ID[j]}.png"              
if [ $? -eq 0 ]; then

./bin/qc2.sh
 
fi; qc.close
done
input.error
echo 

#: AZTEC ========================================================================
if [ $aztec -eq 1 ]; then
  printf "=============================AZTEC==================================\n\n"
  for j in ${!ID[@]}; do
    inputs "${out[$j]}" "RS.${ID[j]}.log"
    outputs "aztec.RS.${ID[j]}+orig" "aztecX.1D"
    echo -n "${ID[j]}> "
    if open.node "AZTEC"; then
  
./bin/aztec.sh

  fi; close.node
  done
  input.error
  echo
fi

#: SLICE TIMING CORRECTION =======================================================
printf "=======================SLICE TIMING CORRECTION====================\n\n"
for j in ${!ID[@]}; do
  inputs "${out[$j]}"
  outputs "tshift.RS.${ID[j]}+orig"
  echo -n "${ID[j]}> "
  if open.node "SLICE TIMING CORRECTION"; then
   ./bin/tshift.sh
  fi; close.node
done
input.error
echo

#: MOTION CORRECTION ============================================================
printf "\n=========================MOTION CORRECTION=======================\n\n"
for j in ${!ID[@]}; do
  inputs "${out[$j]}"
  outputs "volreg.RS.${ID[j]}+orig" "mc.${ID[j]}.1d"
  echo -n "${ID[j]}> "
  if open.node "MOTION CORRECTION"; then
   
./bin/volreg.sh

  fi; close.node
done
input.error
echo

#: QC3 ========================================================================
printf "=============================QC 3==================================\n\n"
for j in ${!ID[@]}; do
qc.open -e "QC 3"                                    \
        -i "T1.${ID[j]}.nii"      \
        -o "m.mcplot.${ID[j]}.jpg"              
if [ $? -eq 0 ]; then

./bin/qc-volreg.sh

fi; qc.close
done
input.error
echo

[ $break -eq 1 ] && echo "Interrompendo script a pedido do usuário" && exit

#: DEOBLIQUE RS ============================================================
printf "\n=========================DEOBLIQUE RS=======================\n\n"
for j in ${!ID[@]}; do
  inputs "${out[$j]}"
  outputs "warp.RS.${ID[j]}+orig"
  echo -n "${ID[j]}> "
  if open.node "DEOBLIQUE RS"; then

./bin/3dwarp-rs.sh

  fi; close.node
  toRS
done
input.error
echo

#: DEOBLIQUE T1 ============================================================
printf "\n=========================DEOBLIQUE T1=======================\n\n"
pwd=($PWD)
for j in ${!ID[@]}; do
  inputs "T1.${ID[j]}.nii"
  outputs "warp.T1.${ID[j]}+orig"
  echo -n "${ID[j]}> "
  if open.node "DEOBLIQUE T1"; then

./bin/3dwarp-t1.sh

  fi; close.node
  toT1
done 
input.error
echo

#: HOMOGENIZE RS ============================================================
printf "\n=========================HOMOGENIZE RS=======================\n\n"
for j in ${!ID[@]}; do 
  fromRS
  inputs "${out[$j]}"
  outputs "zeropad.RS.${ID[j]}+orig"
  echo -n "${ID[j]}> "
  if open.node "HOMOGENIZE RS"; then
./bin/3dzeropad.sh
  fi; close.node
  toRS
done
input.error
echo

#: REORIENT T1 TO TEMPLATE ================================================
printf "\n====================REORIENT T1 TO TEMPLATE===================\n\n"
for j in ${!ID[@]}; do
  fromT1
  get.info1 "template/$template"
  inputs "${out[$j]}"
  outputs "resample.T1.${ID[j]}+orig"
  echo -n "${ID[j]}> "
  if open.node "REORIENT T1 TO TEMPLATE"; then
    3dresample \
./bin/3dresample.sh
  fi; close.node
  toT1
done 
input.error
echo

#: REORIENT RS TO TEMPLATE ================================================
printf "\n====================REORIENT RS TO TEMPLATE===================\n\n"
for j in ${!ID[@]}; do
  fromRS
  get.info1 "template/$template"
  inputs "${out[$j]}"
  outputs "resample.RS.${ID[j]}+orig"
  echo -n "${ID[j]}> "
  if open.node "REORIENT RS TO TEMPLATE"; then
./bin/3dresample.sh
  fi; close.node
  toRS
done 
input.error
echo

#: Align center T1 TO TEMPLATE ================================================
printf "\n====================Align center T1 TO TEMPLATE===================\n\n"
for j in ${!ID[@]}; do
  fromT1
  inputs "${out[$j]}"
  outputs "resample.T1.${ID[j]}_shft+orig" "resample.T1.${ID[j]}_shft.1D"
  echo -n "${ID[j]}> "
  if open.node "Align center T1 TO TEMPLATE"; then
./bin/align-t1temp.sh
  fi; close.node
done 
input.error
echo

#: Unifize T1 ===========================================================
printf "\n=========================Unifize T1========================\n\n"
for j in ${!ID[@]}; do
  inputs "${out[$j]}"
  outputs "unifize.T1.${ID[j]}+orig"
  echo -n "${ID[j]}> "
  if open.node "Unifize T1"; then
./bin/3dunifize.sh
  fi; close.node
done 
input.error
echo

#: SKULLSTRIP ===============================================================
if [ $bet -eq 0 ]; then
  echo "O SKULL STRIP DEVE SER FEITO MANUALMENTE. USE COMO BASE O ARQUIVO QUE ESTÁ NA PASTA OUTPUT/${ID[j]}/manual_skullstrip. NOMEIE O ARQUIVO mask.T1.<SUBID>.nii.gz e salve no diretório base." | fold -s
  for j in ${!ID[@]}; do
    inputs "${out[$j]}"
    outputs "mask.T1.${ID[j]}.nii.gz"
    3dAFNItoNIFTI ${in[$j]} unifize.T1.${ID[j]}.nii
    [ ! -d "$pwd/OUTPUT/${ID[j]}/manual_skullstrip" ] && mkdir -p $pwd/OUTPUT/${ID[j]}/manual_skullstrip
    cp DATA/${ID[j]}/${ID[j]}.results/unifize.T1.${ID[j]}.nii OUTPUT/${ID[j]}/manual_skullstrip 2> /dev/null
    ss=$(find . -name "mask.T1.${ID[j]}*")
    mv $ss ./DATA/${ID[j]}/${ID[j]}.results 2> /dev/null
  done
else
  FSLDIR=/usr/share/fsl
  #: BET ============================================================
  printf "\n============================BET============================\n\n"
  pwd=($PWD)
  for j in ${!ID[@]}; do
    inputs "${out[$j]}"
    outputs "mask.T1.${ID[j]}.nii.gz"
    echo -n "${ID[j]}> "
    if open.node "BET"; then

./bin/optibet.sh

    fi; close.node
  done 
  input.error
  echo
fi 

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



[ $break -eq 2 ] && echo "Interrompendo script a pedido do usuário" && exit

#: APPLY MASK TO T1 ===========================================================
printf "\n=========================APPLY MASK T1========================\n\n"
for j in ${!ID[@]}; do
  inputs "${out[$j]}" "unifize.T1.${ID[j]}+orig"
  outputs "SS.T1.${ID[j]}+orig"
  echo -n "${ID[j]}> "
  if open.node "APPLY MASK T1"; then
./bin/ssmask.sh
  fi; close.node
  toT1
done 
input.error
echo

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


