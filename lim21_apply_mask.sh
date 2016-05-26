#!bin/bash

source config
lista=(`cat "$pathpi"/subs.txt`)

cd "$pathpi"
echo
echo "===================================================================="
echo "=========== Aplicando a mascara do SKULL STRIPPING ================="
echo "===================================================================="
echo
for i in "${lista[@]}"
  do
  echo "Aplicando em $i..."

  3dcalc \
    -a        urd_T1_"$i".nii \
    -b        lurd_T1_"$i".nii.gz \
    -expr     'a*abs(b-1)' \
    -prefix   SS_T1_"$i"

  echo
  echo
done

# The command 3dcalc performs the following calculation: 'a*abs(b-1)'. This means that:
# a = T1 image before skull stripping
# b = mask (1 = regions to be deleted; 0 = regions to be preserved)
# b-1 => the regions to be removed are now ‘0’ and the regions to be preserved are now ‘-1’
# abs(b-1) => calculate the absolute value so that the regions to be removed are still ‘0’ and the regions to be preserved are now ‘1’
# a*abs(b-1) => multiply the T1 image to the ‘abs(b-1)’ so that the regions to be deleted are set to zero and the regions to be preserved are unchanged.
