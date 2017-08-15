#!/usr/bin/env bash

#set -x
#: PARSE ARGUMENTS ====================================================
usage() {
    echo "ARGUMENTS:"
    echo " $0 --id <id> --finalrs <HEAD> <BRIK>" 
    echo 

}

#startS=1
#stopS=12
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --finalh )
    frs1="$2"
    shift # past argument
	;;
	--finalb )
    frs2="$2"
    shift # past argument
	;;
	--id )
    ident="$2"
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
atlas="AAL_ROI_MNI_V4.nii"
atlas[1]="shen_fconn_atlas_150_1mm.nii"
atlas[2]="shenfinn_1mm_268_parcellation.nii"
atlas[3]="power_PP264_all_ROIs_combined.nii"
atlas[4]="gordon_Parcels_MNI_111.nii"
atlas[5]="CC200.nii"
atlas[6]="BN_Atlas_246_1mm.nii"
atlas[7]="AICHA.nii"

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
co=0
for c in bash 3dTshift; do
[ ! $(command -v $c) ] && co=$((co + 1))
done
if [ ! $co -eq 0 ];then

# Check if all required softwares are installed on $PATH
fold -s <<-EOF

Required Software and Packages:
GNU bash           ...$(check bash)
AFNI               ...$(check 3dTshift)

WARNING: Any missing required software will cause the script to stop!
EOF

	exit
fi

path=($PWD)

# Search for the Atlas
echo
echo
for t in ${atlas[@]}; do
	cd $path
	temp=$(find $path -name $t)
	if [ ! -z "$temp" ];then
	  	if [ ! -f "${temp}" ]; then
		mv $temp template 2> /dev/null
  		fi
	else 
		echo
    	echo "Atlas $t not found"
    	exit
	fi

	echo Subject $ident Atlas $t

	# Resample the atlas to preproc images
	# Create loop variables

	
	id=${ident}
	ppath=$path/PREPROC/$id
	file_finalrs1=${frs1}
	file_finalrs2=${frs2}
	file_log=${log}
	log=preproc_${id}.log


	[ -d template/resam ] || mkdir template/resam
	
	cd $ppath

	S=${startS:-0}

	r=0
	[ -f "../../template/resam/resampled_${t%%.*}+tlrc.HEAD" ] && r=$((r+1))
	[ -f "../../template/resam/resampled_${t%%.*}+tlrc.BRIK" ] && r=$((r+1))
	case $r in 
		0 ) S=0 ;;
		1 ) rm ../../template/resam/resampled_${t%%.*}*; S=0 ;;
		2 ) S=1 ;;
	esac				
		
	until [ "$S" = "${stopS:-2}" ]; do
	case $S in
		0 ) 
		unset in out
		in=${file_finalrs1}
		in[1]=${file_finalrs2}
		in[2]=../../template/${t}
		out=../../template/resam/resampled_${t%%.*}+tlrc.HEAD
		out[1]=../../template/resam/resampled_${t%%.*}+tlrc.BRIK
		# Run modular script
		echo -n "RESAMPLE>  "
		open.node; 
		case $? in
				0 ) 
					3dresample \
						-master ${in%%.*} \
						-prefix ${out%%*.} \
						-inset ${in[2]} &>> $log
					close.node && S=1 || exit ;;
				1 ) S=1 ;;
				2 ) exit ;;
		esac
		;;
		1 )
		unset in out
		in=${file_finalrs1}
		in[1]=${file_finalrs2}
		in[2]=../../template/resam/resampled_${t%%.*}+tlrc.HEAD
		in[3]=../../template/resam/resampled_${t%%.*}+tlrc.BRIK
		out=TS_${t%%_*}_${file_finalrs1%%+*}.txt
		# Run modular script
		echo -n "EXT TS> "
		open.node; 
		case $? in
				0 )
				(3dROIstats \
					-quiet \
					-mask ${in[2]%.*} \
					${in%%.*} > ${out}) &>> $log
				close.node && S=2|| exit
				;;
				1 ) break ;;
				2 )	exit ;;
		esac
		;;
	esac
	done
done


