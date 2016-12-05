#!/usr/bin/env bash

# PROCESSANDO OS ARGUMENTOS ====================================================
usage() {
    echo "Argumentos:"
    echo " $0 [ --var <txt com variáveis para análise> | --subs <ID das imagens> ]"
    echo " $0 [ -h | --help ]"
    echo
}



i=$(($# + 1)) # index of the first non-existing argument
declare -A longoptspec
longoptspec=( [config]=1 [subs]=1 )
optspec=":l:h-:"
while getopts "$optspec" opt; do
while true; do
    case "${opt}" in
        -) #OPTARG is name-of-long-option or name-of-long-option=value
            if [[ ${OPTARG} =~ .*=.* ]] # with this --key=value format only one argument is possible
            then
                opt=${OPTARG/=*/}
                ((${#opt} <= 1)) && {
                    echo "Syntax error: Invalid long option '$opt'" >&2
                    exit
                }
                if (($((longoptspec[$opt])) != 1))
                then
                    echo "Syntax error: Option '$opt' does not support this syntax." >&2
                    exit
                fi
                OPTARG=${OPTARG#*=}
            else #with this --key value1 value2 format multiple arguments are possible
                opt="$OPTARG"
                ((${#opt} <= 1)) && {
                    echo "Syntax error: Invalid long option '$opt'" >&2
                    exit
                }
                OPTARG=(${@:OPTIND:$((longoptspec[$opt]))})
                ((OPTIND+=longoptspec[$opt]))
                #echo $OPTIND
                ((OPTIND > i)) && {
                    echo "Syntax error: Not all required arguments for option '$opt' are given." >&2
                    exit
                }
            fi

            continue #now that opt/OPTARG are set we can process them as
            # if getopts would've given us long options
            ;;
        c|config)
          config=$OPTARG
            ;;
        s|subs)
            subs=$OPTARG
            ;;
        h|help)
            usage
            exit 0
            ;;
        ?)
            echo "Erro de sintaxe:'$OPTARG' desconhecida" >&2
            usage
            exit
            ;;
        *)
            echo "Erro de sintaxe:'$opt' desconhecida'" >&2
            usage
            exit
            ;;
    esac
break; done
done

# ==============================================================================

# DECLARANDO FUNÇÕES ===========================================================
check () {
  if command -v $1 > /dev/null; then
    echo "OK"
  else
    echo "Não encontrado em \$PATH"
fi
}

node () {

    [ -d $outpath ] || mkdir $outpath

    local a=0; local b=0; local c=0; local d=0; local e=0

    for i in ${in[@]}; do
        if [ ! -f $inpath$i ]; then
            echo "INPUT $i não encontrado"
            a=$((a + 1))            
        else
            for ii in ${out[@]}; do
                if [ -f $outpath$ii ]; then
                    b=$((b + 1))
                    [ $outpath$ii -ot $inpath$i ] && echo "INPUT $i MODIFICADO." && c=$((c + 1))
                fi
            done
        fi
    done

    echo $a $b $c

    [ $a -eq 0 ] || exit

    if [ $b -eq ${#out[@]} ]; then 
        echo "OUTPUT JÁ EXISTE. PROSSEGUINDO."; d=1
    else
        if [ ! $b -eq 0 ]; then
            echo "OUTPUT CORROMPIDO. REFAZENDO ANÁLISE."
            for ii in ${out[@]}; do rm $outpath$ii; done
    fi

    [ $c -eq 0 ] || for ii in ${out[@]}; do rm $outpath$ii; done

    while d=0; do
    cd $inpath
      $1 &> $prefix$i.log \
        && printf "Processamento da imagem %s realizado com sucesso!\n" "$i" \
        || printf "Houve um erro no processamento da imagem %s, consulte o log %s\n" "$i" "$prefix$i.log" | fold -s
      cd $pwd
      mv $inpath$prefix* $outpath
    done

    for ii in ${out[@]}; do [ -f $outpath$ii ] ||  e=$((e + 1)) done
      
    [ ! $e -eq 0 ] && echo "OUTPUT CORROMPIDO. CONSULTE O LOG." && exit
   
}
# ==============================================================================


# INÍCIO =======================================================================

fold -s <<-EOF

Protocolo de pré-processamento de RS-fMRI
--------------------------------------

RUNTIME: $(date)

GNU bash           ...$(check bash)
AFNI               ...$(check afni)
FSL                ...$(check fsl5.0-fast)

EOF

if ( ! command -v bash || ! command -v afni || ! command -v fsl5.0-fast) > /dev/null ; then
	printf "\nUm ou mais programas necessários para o pré-processamento não estão instalados (acima). Por favor instale o(s) programa(s) faltante(s) ou então verifique se estão configurados na variável de ambiente \$PATH\n\n" | fold -s
	exit
fi

if [ ! -z $config ]; then  
  if [ -f $config ]; then
    source $config
    a=0
    for var in ptn mcbase gRL gAP gIS orient template blur; do
      if [[ -z "${!var:-}" ]]; then
      echo "Variável $var não encontrada"
      a=$(($a + 1))
      fi
    done
    if [ ! $a -eq 0 ]; then
      echo "Erro: Não é possível executar o script sem as variáveis acima estarem definidas no arquivo de configuração. Encerrando"
      exit
    fi
    unset a
  else
  echo "Arquivo de configuração especificado não encontrado"
  exit
  fi
else 
  echo "O arquivo de configuração não foi especificado"
  if [ ! -f preproc.cfg ]; then
    echo "Será criado um arquivo de configuração com valores padrão: preproc.cfg"
    cat > preproc.cfg << EOL
# Variáveis RS-fMRI Preprocessing:

ptn=seq+z
mcbase=100
gRL=90
gAP=90
gIS=60
orient="rpi"
template="MNI152_1mm_uni+tlrc"
blur=6
EOL
exit
  else
    echo "Será usado o arquivo local preproc.cfg"
    source preproc.cfg
  fi
fi  


# informando os usuários das variáveis definidas ou defaults
fold -s <<-EOF
As variáveis que serão usadas como parametros para as análises são:
Slice timing correction - sequência de aquisição => $ptn
Motion correction       - valor base             => $mcbase
Homogenize Grid         - tamanho da grade       => $gRL $gAP $gIS

EOF

# Checando arquivo com nome dos indivíduos
if [ ! -z $subs ]; then  
  if [ ! -f $subs ]; then
    echo "Arquivo com ID dos indivíduos especificado não encontrado"
    exit
  fi
else 
  if [ -f preproc.sbj ]; then
    subs=preproc.sbj
  else
    echo "O arquivo com ID dos indivíduos não foi especificado" 
    exit
  fi
fi  

#mapfile -t ID < $subs
ID=$(cat $subs)
echo "Lista de indivíduos para análise:"
a=0
for i in $ID; do 
  echo -n "$i  ... " 
  if [ $(find . -name "T1_$i.nii") ] && [ $(find . -name "T1_$i.PAR") ]; then
    echo -n "T1" 
  else echo -n "(T1 não encontrado)"; a=$((a + 1))
  fi
  if [ $(find . -name "RS_$i.nii") ] && [ $(find . -name "RS_$i.PAR") ]; then
    echo " RS" 
  else echo " (RS não encontrado)"; a=$((a + 1)) 
  fi
done
echo
if [ ! $a -eq 0 ]; then
    echo "Imagens não foram encontradas ou não estão nomeadas conforme o padrão: RS_<ID>.nii/RS_<ID>.PAR e T1_<ID>.nii/T1_<ID>" | fold -s ; echo
    exit
fi

[ -d DATA ] || mkdir DATA
[ -d OUTPUT ] || mkdir OUTPUT

unset a; a=0
for i in $ID; do
  [ -d DATA/$i ] || mkdir DATA/$i 
  [ -d OUTPUT/$i ] || mkdir OUTPUT/$i 
  for ii in T1_$i.nii T1_$i.PAR RS_$i.nii RS_$i.PAR physlog_$i; do
    [ ! -f DATA/$i/$ii ] && wp=$(find . -name $ii) && rp=DATA/$i/$ii && mv $wp $rp 2> /dev/null && a=$((a + 1))
  done
done
if [ ! $a -eq 0 ]; then 
  echo "O caminho das imagens não está conformado com o padrâo: DATA/<ID>/T1_<ID>.nii"
  echo "Conformando..."
  echo
fi

exit
  

# SLICE TIMING CORRECTION=======================================================
printf "=======================SLICE TIMING CORRECTION====================\n\n"
pwd=($PWD)
for i in $ID; do
  prefix=t_RS_
  in=RS_$i.nii
  out=$prefix$i.nii
  inpath=DATA/$i/
  outpath=DATA/$i/slice_correction/
  echo -n "$i> "
  node "3dTshift \
    -verbose \
    -tpattern $ptn \
    -prefix $out \
    -Fourier \
    $in"
done

# MOTION CORRECTION============================================================
printf "\n=========================MOTION CORRECTION=======================\n\n"
pwd=($PWD)
for i in $ID; do
  prefix=rt_RS_
  in=t_RS_$i.nii
  out=$prefix$i.nii
  out[2]="$prefix"mc_$i.1d
  inpath=DATA/$i/slice_correction/
  outpath=DATA/$i/motion_correction/
  echo -n "$i> "
  node "3dvolreg \
  -prefix $out \
  -base 100 \
  -zpad 2 \
  -twopass \
  -Fourier \
  -verbose \
  -1Dfile ${out[2]} \
  $in"
done
exit # <<=======================================================================

#===============================================================================
#===============================================================================


### MOTION CORRECTION QUALITY CONTROL
cd "$pathpi"
echo
echo "===================================================================="
echo "=========== Aplicando Check Motion Correction às imagens ==========="
echo "===================================================================="
echo
for i in "${lista[@]}"
  do
  echo "Aplicando CMC em $i..."
  1dplot motioncorrection_"$i".1d
  #read -p "Aperte enter para continuar..."
done

## DEOBLIQUE: T1 e RS
cd "$pathpi"
echo
echo "===================================================================="
echo "========= Aplicando estapa Deoblique T1 e fmri às imagens ========"
echo "===================================================================="
echo
### Deoblique T1
for i in "${lista[@]}"
  do
  echo "Aplicando em $i..."
  3dWarp \
  -deoblique \
  -prefix  d_T1_"$i" \
  T1_"$i".nii
done

### Deoblique fMRI
for i in "${lista[@]}"
  do
  echo "Aplicando em $i..."
  3dWarp \
  -deoblique \
  -prefix  drt_RS_"$i" \
  rt_RS_"$i"+orig
done

## HOMOGENIZE GRID
cd "$pathpi"
echo
echo "===================================================================="
echo "=========== Aplicando etapa Homogenize Grid às imagens ============"
echo "===================================================================="
echo
for i in "${lista[@]}"
  do
  echo "Aplicando em $i..."
  3dZeropad \
  -RL "$gRL" \
  -AP "$gAP" \
  -IS "$gIS" \
  -prefix pdrt_RS_"$i" \
  drt_RS_"$i"+orig
done

## REORIENT TO TEMPLATE
cd "$pathpi"
echo
echo "===================================================================="
echo "=========== Aplicando etapa Reorient to templete às imagens =========="
echo "===================================================================="
echo
### Reorient T1
for i in "${lista[@]}"
  do
  echo "Aplicando em $i..."
  3dresample \
  -orient "$orient" \
  -prefix rd_T1_"$i" \
  -inset d_T1_"$i"+orig
done

### Reorient fMRI
for i in "${lista[@]}"
  do
  echo "Aplicando em $i..."
  3dresample \
  -orient "$orient" \
  -prefix rpdrt_RS_"$i" \
  -inset pdrt_RS_"$i"+orig
done

## ALIGN CENTER T1 TO TEMPLATE
cd "$pathpi"
echo
echo "===================================================================="
echo "==== Aplicando etapa Align center of T1 to template às imagens ====="
echo "===================================================================="
echo
for i in "${lista[@]}"
  do
  echo "Aplicando em $i..."
  @Align_Centers \
  -base "$template" \
  -dset rd_T1_"$i"+orig
done

## UNIFORMIZE T1
cd "$pathpi"
echo
echo "===================================================================="
echo "=========== Aplicando etapa Uniformize T1 às imagens =============="
echo "===================================================================="
echo
for i in "${lista[@]}"
  do
  echo "Aplicando em $i..."
  3dUnifize \
  -prefix urd_T1_"$i" \
  -input rd_T1_"$i"_shft+orig
done

## SKULL STRIPPING: Nesse pipeline deve ser realizado manualmente
cd "$pathpi"
echo
echo "===================================================================="
echo "=========== Preparando para realiar o SKULL STRIPPING =============="
echo "===================================================================="
echo
for i in "${lista[@]}"
  do
  echo "Aplicando em $i..."
  3dAFNItoNIFTI urd_T1_"$i"+orig
  done
echo "Para a próxima etapa recomenda-se realizar o SKULL STRIPPING das imagens manualmente no MRIcron. Lembre-se de salvar como Analyze a mascara com o nome: "
echo "lurd_T1_<cod_sub>"
echo "Em seguida use o MRIron para converter a mascara para o formato NIFTI. Salve com o seguinte nome:"
echo "lurd_T1_<cod_sub>.nii.gz"

## =============================================================================
## ====================== ATÉ AQUI JÁ TESTADO ==================================
## =============================================================================

## APPLY SKULL STRIPPING MASK
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
  done
### The command 3dcalc performs the following calculation: 'a*abs(b-1)'. This means that:
### a = T1 image before skull stripping
### b = mask (1 = regions to be deleted; 0 = regions to be preserved)
### b-1 => the regions to be removed are now ‘0’ and the regions to be preserved are now ‘-1’
### abs(b-1) => calculate the absolute value so that the regions to be removed are still ‘0’ and the regions to be preserved are now ‘1’
### a*abs(b-1) => multiply the T1 image to the ‘abs(b-1)’ so that the regions to be deleted are set to zero and the regions to be preserved are unchanged.

## ALIGN CENTER fmri TO T1
cd "$pathpi"
echo
echo "===================================================================="
echo "====== Aplicando etapa Align center of fmri to T1 às imagens ======="
echo "===================================================================="
echo
for i in "${lista[@]}"
  do
  echo "Aplicando em $i..."
  @Align_Centers \
  -cm \
  -base SS_T1_"$i"+orig \
  -dset rpdrt_RS_"$i"+orig
done

## COREGISTER fmri and T1
cd "$pathpi"
echo
echo "===================================================================="
echo "========= Aplicando etapa Coregister fmri e T1 às imagens =========="
echo "===================================================================="
echo
for i in "${lista[@]}"
  do
  echo "Aplicando em $i..."
  align_epi_anat.py \
  -anat SS_T1_"$i"+orig \
  -epi rpdrt_RS_"$i"_shft+orig \
  -epi_base 100 \
  -anat_has_skull no \
  -volreg off \
  -tshift off \
  -deoblique off
done

## NORMALIZE T1 TO TEMPLATE
cd "$pathpi"
echo
echo "===================================================================="
echo "========= Aplicando etapa Normalize T1 to template às imagens ======"
echo "===================================================================="
echo
for i in "${lista[@]}"
  do
  echo "Aplicando em $i..."
  3dQwarp \
  -prefix MNI_T1_"$i" \
  -blur 0 3 \
  -base "$template" \
  -allineate \
  -source SS_T1_"$i"_al+orig
done

## SPATIAL NORMALIZATION
cd "$pathpi"
echo
echo "===================================================================="
echo "========= Aplicando etapa Spatial Normalization fmri às imagens ======"
echo "===================================================================="
echo
for i in "${lista[@]}"
  do
  echo "Aplicando em $i..."
  3drename MNI_T1_"$i"_WARP+tlrc MNI_T1_WARP
  3dNwarpApply \
  -source rpdrt_RS_"$i"_shft+orig \
  -nwarp 'MNI_T1_WARP+tlrc' \
  -master "$template" \
  -newgrid 3 \
  -prefix rpdrt_RS_MNI_"$i"
  3drename MNI_T1_WARP+tlrc MNI_T1_"$i"_WARP
done

## CREATE CSF AND WM MASKS
cd "$pathpi"
echo
echo "===================================================================="
echo "========= Aplicando etapa Create CSF and WM Masks às imagens ======"
echo "===================================================================="
echo
### Segmentando as imagens com FSL-FAST
for i in "${lista[@]}"
  do
  echo "Aplicando em $i..."
  3dAFNItoNIFTI SS_T1_"$i"_al+orig
  echo "Segmentando as imagens usando FSL-FAST"
  echo
  fsl5.0-fast \
  -o seg_"$i" \
  -S 1 \
  -t 1 \
  -n 3 \
  SS_T1_"$i"_al.nii
done
### Explained: -o = output name; -S = number of channels (1, because only T1 image); -t = type of image (1 for T1); -n = number of tissue-type classes
### This gives three output files: seg_"$lista"_pve_0.nii.gz (CSF), seg_"$lista"_pve_1.nii.gz (GM) and seg_"$lista"_pve_3.nii.gz (WM).

### Binarize the segmented images
echo
echo "Binarizando as imagens segmentadas"
echo
for i in "${lista[@]}"
  do
  ### first, the CSF
  3dcalc \
  -a seg_"$i"_pve_0.nii.gz \
  -expr 'equals(a,1)' \
  -prefix "$i"_CSF
  ### now, the WM
  3dcalc \
  -a seg_"$i"_pve_2.nii.gz \
  -expr 'equals(a,1)' \
  -prefix "$i"_WM
done

### Aplicando Resample as imagens
echo
echo "Aplicando Resample às imagens"
echo
for i in "${lista[@]}"
  do
  ### resample CSF mask
  3dresample \
  -master rpdrt_RS_"$i"_shft+orig \
  -inset "$i"_CSF+orig \
  -prefix "$i"_CSF_resampled+orig
  ### resample WM mask
  3dresample \
  -master rpdrt_RS_"$i"_shft+orig \
  -inset "$i"_WM+orig \
  -prefix "$i"_WM_resampled+orig
done

### Calculando CSF and WM mean signal
echo
echo "Calculando CSF e WM mean signal"
echo
for i in "${lista[@]}"
  do
  ### first, mean CSF signal
  3dmaskave \
  -mask "$i"_CSF_resampled+orig \
  -quiet \
  rpdrt_RS_"$i"_shft+orig \
  "$i"_CSF_signal.1d
  ### now, mean WM signal
  3dmaskave \
  -mask "$i"_WM_resampled+orig \
  -quiet \
  rpdrt_RS_"$l"_shft+orig \
  "$i"_WM_signal.1d
done

### 3dBandPass
echo
echo "Aplicando 3dBandpass para correção de movimentos"
echo
for i in "${lista[@]}"
  do
  3dBandpass \
  -band 0.01 0.08 \
  -despike \
  -ort motioncorrection_"$i".1d \
  -ort "$i"_CSF_signal.1d \
  -ort "$i"_WM_signal.1d \
  -prefix frpdrt_RS_MNI_"$i" \
  -input rpdrt_RS_MNI_"$i"+tlrc
done

## SPATIAL Smoothing
cd "$pathpi"
echo
echo "===================================================================="
echo "========= Aplicando etapa Spatial Smoothing às imagens ======"
echo "===================================================================="
echo
for i in "${lista[@]}"
  do
	echo "Aplicando em $i..."
	3dmerge \
	-1blur_fwhm "$blur" \
	-doall \
	-prefix bfrpdrt_RS_MNI_"$i" \
	frpdrt_RS_MNI_"$i"+tlrc
done

## MOTION CENSORING
cd "$pathpi"
echo
echo "===================================================================="
echo "========= Aplicando etapa Motion censoring às imagens ============"
echo "===================================================================="
echo
for i in "${lista[@]}"
  do
	echo "Aplicando em $i..."
	echo
	echo "Create Framewise Displacement (FD) censor"
	echo
	### take the temporal derivative of each vector (done as first backward difference)
	1d_tool.py \
	-infile motioncorrection_"$i".1d \
	-derivative \
	-write "$i"_RS.deltamotion.1D

	### calculate total framewise displacement (sum of six parameters)
	1deval \
	-a "$i"_RS.deltamotion.1D'[0]' \
	-b "$i"_RS.deltamotion.1D'[1]' \
	-c "$i"_RS.deltamotion.1D'[2]' \
	-d "$i"_RS.deltamotion.1D'[3]' \
	-e "$i"_RS.deltamotion.1D'[4]' \
	-f "$i"_RS.deltamotion.1D'[5]' \
	-expr '100*sind(abs(a)/2) + 100*sind(abs(b)/2) + 100*sind(abs(c)/2) + abs(d) + abs(e) + abs(f)' \
	"$i"_RS.deltamotion.FD.1D

	### create temporal mask (1 = extreme motion)
	1d_tool.py \
	-infile "$i"_RS.deltamotion.FD.1D \
	-extreme_mask -1 0.5 \
	-write "$i"_RS.deltamotion.FD.extreme0.5.1D

	### create temporal mask (0 = extreme motion)
	1deval -a "$i"_RS.deltamotion.FD.extreme0.5.1D \
	-expr 'not(a)' \
	"$i"_RS.deltamotion.FD.moderate0.5.1D

	### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
	1deval \
	-a "$i"_RS.deltamotion.FD.moderate0.5.1D \
	-b "$i"_RS.deltamotion.FD.moderate0.5.1D'{1..$,0}' \
	-expr 'ispositive(a + b - 1)' \
	"$i"_RS.deltamotion.FD.moderate0.5.n.1D

	### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
	1deval \
	-a "$i"_RS.deltamotion.FD.moderate0.5.n.1D \
	-b "$i"_RS.deltamotion.FD.moderate0.5.n.1D'{0,0..$}' \
	-expr 'ispositive(a + b - 1)' \
	"$i"_RS.deltamotion.FD.moderate0.5.n.n.1D

	### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
	1deval \
	-a "$i"_RS.deltamotion.FD.moderate0.5.n.n.1D \
	-b "$i"_RS.deltamotion.FD.moderate0.5.n.n.1D'{0,0..$}' \
	-expr 'ispositive(a + b - 1)' \
	"$i"_RS.deltamotion.FD.moderate0.5.n.n.n.1D

	echo "Create DVARS censor"
	echo
	### normalize and scale the BOLD to percent signal change
	### find the mean
	3dTstat \
	-mean \
	-prefix meanBOLD_"$i" \
	RS_"$i".nii
	### scale BOLD signal to percent change
	3dcalc \
	-a RS_"$i".nii \
	-b meanBOLD_"$i"+orig \
	-expr "(a/b) * 100" \
	-prefix "$i"_RS_scaled
	### temporal derivative of the frames
	3dcalc \
	-a "$i"_RS_scaled+orig \
	-b 'a[0,0,0,-1]' \
	-expr '(a - b)^2' \
	-prefix "$i"_RS.backdif2
	### Extract brain mask
	3dAutomask \
	-prefix "$i".auto_mask.brain \
	RS_"$i".nii
	### average data from each frame (inside brain mask)
	3dmaskave \
	-mask "$i".auto_mask.brain+orig \
	-quiet "$i"_RS.backdif2+orig \
	"$i"_RS.backdif2.avg.1D
	### square root to finally get DVARS
	1deval \
	-a "$i"_RS.backdif2.avg.1D \
	-expr 'sqrt(a)' \
	"$i"_RS.backdif2.avg.dvars.1D
	### mask extreme (1 = extreme motion)
	1d_tool.py \
	-infile "$i"_RS.backdif2.avg.dvars.1D \
	-extreme_mask -1 5 \
	-write "$i"_RS.backdif2.avg.dvars.extreme5.1D
	### mask extreme (0 = extreme motion)
	1deval \
	-a "$i"_RS.backdif2.avg.dvars.extreme5.1D \
	-expr 'not(a)' \
	"$i"_RS.backdif2.avg.dvars.moderate5.1D
	### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
	1deval \
	-a "$i"_RS.backdif2.avg.dvars.moderate5.1D \
	-b "$i"_RS.backdif2.avg.dvars.moderate5.1D'{1..$,0}' \
	-expr 'ispositive(a + b - 1)' \
	"$i"_RS.backdif2.avg.dvars.moderate5.n.1D
	### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 2)
	1deval \
	-a "$i"_RS.backdif2.avg.dvars.moderate5.n.1D \
	-b "$i"_RS.backdif2.avg.dvars.moderate5.n.1D'{0,0..$}' \
	-expr 'ispositive(a + b - 1)' \
	"$i"_RS.backdif2.avg.dvars.moderate5.n.n.1D
	### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 3)
	1deval \
	-a "$i"_RS.backdif2.avg.dvars.moderate5.n.n.1D \
	-b "$i"_RS.backdif2.avg.dvars.moderate5.n.n.1D'{0,0..$}' \
	-expr 'ispositive(a + b - 1)' \
	"$i"_RS.backdif2.avg.dvars.moderate5.n.n.n.1D


	### Integrate FD and DVARS censoring
	### (only frames censored on both will be excluded, as in Power et al., 2012)

	### FD censor OR DVARS censor
	1deval \
	-a "$i"_RS.deltamotion.FD.moderate0.5.n.n.n.1D \
	-b "$i"_RS.backdif2.avg.dvars.moderate5.n.n.n.1D \
	-expr 'or(a, b)' \
	"$i"_powerCensorIntersection.1D

	### Apply censor file in the final preprocessed image (after temporal filtering and spatial blurring)
	afni_restproc.py -apply_censor bfrpdrt_RS_MNI_"$i"+tlrc "$i"_powerCensorIntersection.1D cbfrpdrt_RS_MNI_"$i"
done
