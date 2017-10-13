#!/usr/bin/env bash


#: PARSE ARGUMENTS ====================================================
usage() {
    echo "ARGUMENTS:"
    echo " $0 --subjects <subs csv> " 
    echo 

}


while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --subjects )
    subs="$2"
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
atlas="AAL_ROI_MNI_V4.nii"
atlas[1]="shen_fconn_atlas_150_1mm.nii"
atlas[2]="shenfinn_1mm_268_parcellation.nii"
atlas[3]="power_PP264_all_ROIs_combined.nii"
atlas[4]="gordon_Parcels_MNI_111.nii"
atlas[5]="CC200.nii"
atlas[6]="BN_Atlas_246_1mm.nii"
atlas[7]="AICHA.nii"


#: DECLARE FUNCTIONS ===========================================================


#: START =======================================================================

#echo $subs
# Check existence of the --subjects argument
# Next step: check for consistency
if [ ! -z $subs ]; then  
  if [ ! -f $subs ]; then
    echo "Subjects ID file not found"
    exit
  fi
else 
  if [ -f subjects.csv ]; then
    echo "Subjects ID file not specified. Local file subjects.csv will be used."
    subs=subjects.csv
  else
    echo "Subjects ID file not specified" 
	usage
    exit
  fi
fi  

# Create the variables ID and index using Subjects ID file
# ID;t1_file;rs_file;log_file;mask_file
oldIFS="$IFS"
IFS=$'\n' pID=($(<${subs}))
IFS="$oldIFS"
for j in ${!pID[@]}; do
	VID[$j]=$(echo ${pID[$j]} | cut -d ";" -f 1)
done
# echo ${VID[@]}

echo "id;final;mask;at1;at2;at3;at4;at5;at6;at7;at8" > preproc_files.csv

for v in ${VID[@]}; do
	id=${v}												
	t1=$(grep "${v}" $subs | cut -d ";" -f 2 2> /dev/null)	
	rs=$(grep "${v}" $subs | cut -d ";" -f 3 2>  /dev/null)
	file_t1=${t1}
	file_t12=${file_t1%%.nii}
	file_rs=${rs}
	file_rs2=${file_rs%%.nii}

final=$(find $PWD -name "final_${file_rs2}.nii" 2> /dev/null)
mask=$(find $PWD -name "automask_mni_${file_rs2}.nii" 2> /dev/null)
at1=$(find $PWD -name "resampled_${atlas[0]%%_*}_${file_rs2}.nii" 2> /dev/null)
at2=$(find $PWD -name "resampled_${atlas[1]%%_*}_${file_rs2}.nii" 2> /dev/null)
at3=$(find $PWD -name "resampled_${atlas[2]%%_*}_${file_rs2}.nii" 2> /dev/null)
at4=$(find $PWD -name "resampled_${atlas[3]%%_*}_${file_rs2}.nii" 2> /dev/null)
at5=$(find $PWD -name "resampled_${atlas[4]%%_*}_${file_rs2}.nii" 2> /dev/null)
at6=$(find $PWD -name "resampled_${atlas[5]%%_*}_${file_rs2}.nii" 2> /dev/null)
at7=$(find $PWD -name "resampled_${atlas[6]%%_*}_${file_rs2}.nii" 2> /dev/null)
at8=$(find $PWD -name "resampled_${atlas[7]%%_*}_${file_rs2}.nii" 2> /dev/null)

echo "$v;$final;$mask;$at1;$at2;$at3;$at4;$at5;$at6;$at7;$at8" >> preproc_files.csv
done



