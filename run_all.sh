#!/usr/bin/env bash

#set -x

#: PARSE ARGUMENTS ====================================================
usage() {
    echo "ARGUMENTS:"
    echo " $0 --subjects <subs csv> --parallel <num de cores> --no_aztec" 
    echo 

}

aztec=1

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --no_aztec )
    aztec=0
    shift # past argument
	;;
    --subjects )
    subs="$2"
    shift # past argument
	;;
	--parallel )
    par="$2"
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

node () {
	open.node; 
	#echo $? 
	if [ $? -eq 0 ]; then
		"$1" ${in[@]} ${out[@]} &>> $log
		close.node && S=${2} || break
	elif [ $? -eq 1 ]; then
		S=${2}
	else
		break
	fi
}

#: START =======================================================================
fold -s <<-EOF

RS-fMRI Preprocessing pipeline
--------------------------------------

RUNTIME: $(date)

EOF


co=0
for c in bash 3dTshift "$fsl5"fast python convert Xvfb perl sed; do
[ ! $(command -v $c) ] && co=$((co + 1))
done
if [ ! $co -eq 0 ];then

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

	exit
fi

echo $subs
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


# Check of nifti files of the indicated Subjects
echo
echo "Searching for neuroimaging:"
a=0
for v in ${VID[@]}; do 
	echo -n "${v}  ... " 
	file=$(grep "${v}" $subs | cut -d ";" -f 2 | xargs find . -name 2> /dev/null)
	if [ ! -z "$file"  ]; then
		printf "T1" 
	else
		printf "(T1 not found)"; a=$((a + 1))
	fi
	file=$(grep "${v}" $subs | cut -d ";" -f 3 | xargs find . -name 2> /dev/null)
	if [ ! -z "$file" ]; then 
		printf " RS" 
	else
		printf " (RS not found)"; a=$((a + 1))
	fi
	file=$(grep "${v}" $subs | cut -d ";" -f 4 | xargs find . -name 2> /dev/null)
	if [ ! -z "$file" ]; then 
		printf " log" 
	else
		printf " (log not found)"; a=$((a + 1))
	fi
	printf "\n"
done
echo

if [ ! $a -eq 0 ]; then
    echo "Some images were not found...." | fold -s ; echo
fi

if [ $aztec -eq 1 ]; then
	no_aztec=""
else
	no_aztec="--no_aztec"
fi

path=($PWD)

N=${par:-1}

#: =============================================================================================================
#: =============================================================================================================

if [ ! $N -eq 1 ]; then
	# Start big loop
	for v in ${VID[@]}; do
		echo
		echo "Running subject ${v} in parallel(background), see the output with cat PREPROC/out.${v}.log" | fold -s
		echo
		((i=i%N)); ((i++==0)) && wait
		./lib/preproc.sh 													\
			--id ${v}												\
			--t1 $(grep "${v}" $subs | cut -d ";" -f 2 2> /dev/null)	\
			--rs $(grep "${v}" $subs | cut -d ";" -f 3 2>  /dev/null)	\
			--log $(grep "${v}" $subs | cut -d ";" -f 4 2>  /dev/null) \
			$no_aztec > $path/PREPROC/out.${v}.log	& 
	done
	wait
else
	# Start big loop
	for v in ${VID[@]}; do
		./lib/preproc.sh 													\
			--id ${v}												\
			--t1 $(grep "${v}" $subs | cut -d ";" -f 2 2> /dev/null)	\
			--rs $(grep "${v}" $subs | cut -d ";" -f 3 2>  /dev/null)	\
			--log $(grep "${v}" $subs | cut -d ";" -f 4 2>  /dev/null) \
			$no_aztec | tee $path/PREPROC/out.${v}.log 
	done
fi


#: ============================================================================================================
#: ============================================================================================================
echo
nruns=`grep -c . $subs`
ts=`find PREPROC -name TS* | wc -l`
ndone=$((ts/8))
[ ! $ndone -ge $nruns ] && echo "Preprocessing not completed" && exit
[ $ndone -ge $nruns ] && echo "Preprocessing completed !"




