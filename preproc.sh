#!/usr/bin/env bash

# TO DO:
# 3 - conformar nomes de arquivos para evitar confusão
# 4 - Usar formato AFNI para evitar problemas?
# 5 - Caso não funcione o 3dbandpass substituir por outro comando


#: PROCESSANDO OS ARGUMENTOS ====================================================
usage() {
    echo "Argumentos:"
    echo " $0 [ Opções ] --config <txt com variáveis para análise>  --subjects <ID das imagens>" 
    echo 
    echo "Opções:"
    echo "-b | --break n interrompe o script no breakpoint de numero indicado"
    echo
    echo "--aztec            realiza a etapa aztec"
    echo "--bet              realiza o skull strip automatizado (Padrão: Manual)"
    echo "--motioncensor_no  NÃO aplica a técnica motion censor"    
    echo
}

aztec=0
bet=0
censor=1
break=0

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -c|--config)
    config="$2"
    shift # past argument
    ;;
    -s|--subjects)
    subs="$2"
    shift # past argument
    ;;
    -b|--break)
    break="$2"
    shift # past argument
    ;;
    --aztec)
    aztec=1
    ;;
    --bet)
    bet=1
    ;;
    --motioncensor_no)
    censor=0
    ;;
    *)
     echo "Erro de sintaxe:'$1' desconhecida'" >&2
     usage
     exit       # unknown option
    ;;
esac
shift # past argument or value
done

# i=$(($# + 1)) # index of the first non-existing argument
# declare -A longoptspec
# longoptspec=( [config]=1 [subs]=1 [break]=1 )
# optspec=":l:h:a:b:c:s:m:p-:"
# while getopts "$optspec" opt; do
# while true; do
#     case "${opt}" in
#         -) #OPTARG is name-of-long-option or name-of-long-option=value
#             if [[ ${OPTARG} =~ .*=.* ]] # with this --key=value format only one argument is possible
#             then
#                 opt=${OPTARG/=*/}
#                 ((${#opt} <= 1)) && {
#                     echo "Syntax error: Invalid long option '$opt'" >&2
#                     exit
#                 }
#                 if (($((longoptspec[$opt])) != 1))
#                 then
#                     echo "Syntax error: Option '$opt' does not support this syntax." >&2
#                     exit
#                 fi
#                 OPTARG=${OPTARG#*=}
#             else #with this --key value1 value2 format multiple arguments are possible
#                 opt="$OPTARG"
#                 ((${#opt} <= 1)) && {
#                     echo "Syntax error: Invalid long option '$opt'" >&2
#                     exit
#                 }
#                 OPTARG=(${@:OPTIND:$((longoptspec[$opt]))})
#                 ((OPTIND+=longoptspec[$opt]))
#                 #echo $OPTIND
#                 ((OPTIND > i)) && {
#                     echo "Syntax error: Not all required arguments for option '$opt' are given." >&2
#                     exit
#                 }
#             fi

#             continue #now that opt/OPTARG are set we can process them as
#             # if getopts would've given us long options
#             ;;
#         m|motioncensor)
#             censor=1
#             ;;
#         a|aztec)
#             aztec=1
#             ;;
#         b|bet)
#             bet=1
#             ;;
#         c|config)
#           config=$OPTARG
#             ;;
#         s|subs)
#             subs=$OPTARG
#             ;;
#         p|break)
#             break=$OPTARG
#             ;;
#         h|help)
#             usage
#             exit 0
#             ;;
#         ?)
#             echo "Erro de sintaxe:'$OPTARG' desconhecida" >&2
#             usage
#             exit
#             ;;
#         *)
#             echo "Erro de sintaxe:'$opt' desconhecida'" >&2
#             usage
#             exit
#             ;;
#     esac
# break; done
# done

#: DECLARANDO VARIÁVEIS ===========================================================
declare -a prefix steppath
declare -a in in_2 in_3 in_4 in_5
declare -a out out_2 out_3 ou_4 out_5
declare -a outrs outt1 prefixrs prefixt1

#: DECLARANDO FUNÇÕES ===========================================================
check () {
  if command -v $1 > /dev/null; then
    echo "OK"
  else
    echo "Não encontrado em \$PATH"
fi
}

input.error () {
[ $ex -eq ${#ID[@]} ] && exit
}

inputs () {
    in[$j]="$1"
    in_2[$j]="$2"
    in_3[$j]="$3"
    in_4[$j]="$4"
}

outputs () {
    out[$j]="$1"
    out_2[$j]="$2"
    out_3[$j]="$3"
    out_4[$j]="$4"
}

open.node () {
  local a=0; local b=0; local c=0; local d=0
  ex=0; go=1
  #
  cd ${steppath[$j]}
  for ii in ${in[$j]} ${in_2[$j]} ${in_3[$j]} ${in_4[$j]} ${in_5[$j]}; do
    for file in ${ii}*; do
      [ ! -f $file ] && echo "INPUT $ii não encontrado" && a=$((a + 1))
      for iii in ${out[$j]} ${out_2[$j]} ${out_3[$j]} ${out_4[$j]} ${out_5[$j]}; do
        for file2 in ${iii}*; do
          [ ! -f $file2 ] && b=$((b + 1)) || c=$((c + 1))
          [ $file2 -ot $file ] && d=$((d + 1))
        done
      done
    done
  done
  #echo $a $b $c $d
  if [ $a -eq 0 ]; then
    if [ $b -eq 0 ]; then 
      if [ ! $d -eq 0 ]; then
        printf "INPUT $ii MODIFICADO. REFAZENDO ANÁLISE. " 
        for iii in ${out[$j]} ${out_2[$j]} ${out_3[$j]} ${out_4[$j]} ${out_5[$j]}; do 
          rm ${iii}* 2> /dev/null; 
        done
        go=1
      else
        echo "OUTPUT JÁ EXISTE. PROSSEGUINDO."; go=0; ex=0
      fi
    else
      if [ ! $c -eq 0 ]; then
        echo "OUTPUT CORROMPIDO. REFAZENDO ANÁLISE."
        for iii in ${out[$j]} ${out_2[$j]} ${out_3[$j]} ${out_4[$j]} ${out_5[$j]}; do 
        rm ${iii}* 2> /dev/null; done
        go=1
      else
        go=1
      fi
    fi
  else
    go=0; ex=$((ex + 1))
  fi  

  if [ $go -eq 1 ]; then
    return 0
  else
    return 1
  fi
}

close.node () {
  local a=0
  if [ $go -eq 1 ]; then  
    for iii in ${out[$j]} ${out_2[$j]} ${out_3[$j]} ${out_4[$j]}; do
      for file2 in ${iii}*; do
        [ -f $file2 ] ||  a=$((a + 1)) 
      done
    done
    if [ ! $a -eq 0 ]; then
      printf "Houve um erro no processamento da imagem %s, consulte o log. \n" "${ID[j]}" && ex=$((ex + 1))
    else
      printf "Processamento da imagem %s realizado com sucesso! \n" "${ID[j]}"
    fi
  fi
  cd $pwd
}

get.info1() {
  local image=$1
  space=$(3dinfo -space $image) 
  is_oblique=$(3dinfo -is_oblique $image) 
  afniprefix=$(3dinfo -prefix $image) 
  tr=$(3dinfo -tr $image) 
  smode=$(3dinfo -smode $image) 
  orient=$(3dinfo -orient $image) 
}

get.info2 () {
  local image1=$1
  local image2=$2
  #comparações
  same_grid=$(3dinfo -same_grid $image1 $image2) 
  same_dim=$(3dinfo -same_dim $image1 $image2) 
  same_delta=$(3dinfo -same_delta $image1 $image2) 
  same_orient=$(3dinfo -same_orient $image1 $image2) 
  same_center=$(3dinfo -same_center $image1 $image2) 
  same_obl=$(3dinfo -same_obl $image1 $image2) 
}

log () {
if [ $go -eq 1 ]; then
( echo 
  echo "================================================================================"
  echo "ETAPA: $1  - RUNTIME: $(date)" 
  echo "================================================================================"
  echo 
  echo "INPUTS: ${in[$j]} ${in_2[$j]} ${in_3[$j]} ${in_4[$j]}" 
  echo "OUTPUTS: ${out[$j]} ${out_2[$j]} ${out_3[$j]} ${out_4[$j]}"
  echo 
  cat DATA/${ID[j]}/${ID[j]}.results/${prefix[$j]}${ID[j]}.log 2> /dev/null ) >> OUTPUT/${ID[j]}/preproc.${ID[j]}.log
fi
}

toRS () {
  outrs[$j]=${out[$j]}
  prefixrs[$j]=${prefix[$j]}
  }

toT1 () {
  outt1[$j]=${out[$j]}
  prefixt1[$j]=${prefix[$j]}
}

fromRS () {
  out[$j]=${outrs[$j]}
  prefix[$j]=${prefixrs[$j]}
}

fromT1 () {
  out[$j]=${outt1[$j]}
  prefix[$j]=${prefixt1[$j]}
}

cp.inputs () {
  files=$(find . -name "$1")
  [ ! -f "${steppath[$j]}$1" ] && cp ${files[0]} ${steppath[$j]} 2> /dev/null
  files=$(find . -name "$2")
  [ ! -f "${steppath[$j]}$2" ] && cp ${files[0]} ${steppath[$j]} 2> /dev/null
  files=$(find . -name "$3")
  [ ! -f "${steppath[$j]}$3" ] && cp ${files[0]} ${steppath[$j]} 2> /dev/null
}

#: INÍCIO =======================================================================
fold -s <<-EOF

Protocolo de pré-processamento de RS-fMRI
--------------------------------------

RUNTIME: $(date)

EOF

# checando arquivo indicado pelo argumento --config
if [ ! -z $config ]; then  
  if [ -f $config ]; then
    source $config
    a=0
    for var in ptn mcbase gRL gAP gIS TR template blur fsl5; do
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
    printf '# Variáveis RS-fMRI Preprocessing:\n\nfsl5=fsl5.0-\nTR=2\nptn=seq+z\nmcbase=100\ngRL=90\ngAP=90\ngIS=60\ntemplate="MNI152_1mm_uni+tlrc"\nbetf=0.1\nblur=6\n' > preproc.cfg
    exit
  else
    echo "Será usado o arquivo local preproc.cfg"
    source preproc.cfg
  fi
fi  

# Checando arquivo com nome dos indivíduos indicado no arg --subs
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

oldIFS="$IFS"
IFS=$'\n' ID=($(<${subs}))
IFS="$oldIFS"
index=${!ID[@]}


# checando se todos os programas necessários estão instalados
fold -s <<-EOF

Programas necessários:
GNU bash           ...$(check bash)
AFNI               ...$(check 3dTshift)
FSL                ...$(check "$fsl5"fast)
Pyhton             ...$(check python)
MATLAB             ...$(check matlab)
  SPM5
  aztec

EOF

if ( ! command -v bash || ! command -v 3dTshift || ! command -v "$fsl5"fast || ! command -v python  ) > /dev/null ; then
	printf "\nUm ou mais programas necessários para o pré-processamento não estão instalados (acima). Por favor instale o(s) programa(s) faltante(s) ou então verifique se estão configurados na variável de ambiente \$PATH\n\n" | fold -s
	exit
fi
[ $aztec -eq 1 ] && [ ! $(command -v matlab) ] && echo "o Matlab e os plugins SPM5 e aztec são necessários para a análise e não foram encontrados. Certifique-se que eles estão instalados e configurados na variável de ambiente $PATH" | fold -s && exit 



# informando os usuários das variáveis definidas ou defaults
fold -s <<-EOF
As variáveis que serão usadas como parametros para as análises são:
Aztec                   - Tempo de repetição(s)   => $TR
Slice timing correction - sequência de aquisição  => $ptn
Motion correction       - valor base              => $mcbase
Homogenize Grid         - tamanho da grade        => $gRL $gAP $gIS
BET                     - bet f                   => $betf
3dMerge	                - filtro gaussiano        => $blur

TEMPLATE: $template

EOF



# Checando imagens com os nomes fornecidos
echo "Lista de indivíduos para análise:"
a=0
for j in ${!ID[@]}; do 
  echo -n "${ID[j]}  ... " 
  file=$(find . -name "T1.${ID[j]}.nii")
  if [ ! -z "$file"  ]; then
    printf "T1" 
    else
    printf "(T1 não encontrado)"; a=$((a + 1))
  fi
  file=$(find . -name "RS.${ID[j]}.nii")
  if [ ! -z "$file" ]; then 
    printf " RS" 
  else
  printf " (RS não encontrado)"; a=$((a + 1))
  fi
  [ $(find . -name "aztec.RS.${ID[j]}*" -print -quit) ] && printf " aztec"
  [ $(find . -name "tshift.RS.${ID[j]}*" -print -quit) ] && printf " stc"
  [ $(find . -name "volreg.RS.${ID[j]}*" -print -quit) ] && printf " mc"
  [ $(find . -name "SS.T1.${ID[j]}*" -print -quit) ] && printf " ss"
  [ $(find . -name "MNI.T1.${ID[j]}*" -print -quit) ] && printf " nm"
  printf "\n"
done
echo
if [ ! $a -eq 0 ]; then
    echo "Imagens não foram encontradas ou não estão nomeadas conforme o padrão: RS.<ID>.nii e T1.<ID>.nii" | fold -s ; echo
    exit
fi

# BUSCANDO O TEMPLATE
temp=$(find . -name "$template*")
if [ ! -z "$temp" ];then
  [ ! -d template ] && mkdir template 
  if [ ! -f "template/${temp[0]}" ]; then
  for tp in $temp; do
    mv $tp template 2> /dev/null
  done
  fi
else
  echo "Template $template não encontrado. Buscando no afni.."
  cp /usr/share/afni/atlases/"$template"* . 2> /dev/null
  temp=$(find . -name "$template*")
  if [ ! -z "$temp" ];then
    [ ! -d template ] && mkdir template 
    for tp in $temp; do
      mv $tp template 2> /dev/null
    done
  else
    echo "Não encontrado"
    exit
  fi
fi

# Preparando para iniciar a análise
[ -d DATA ] || mkdir DATA
[ -d OUTPUT ] || mkdir OUTPUT

unset a; a=0
for j in ${!ID[@]}; do
  [ -d DATA/${ID[j]} ] || mkdir DATA/${ID[j]} 
  [ -d OUTPUT/${ID[j]} ] || mkdir OUTPUT/${ID[j]} 
  for ii in T1.${ID[j]}.nii RS.${ID[j]}.nii RS.${ID[j]}.log; do
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
  prefix[$j]=.RS.
  prefixt1[$j]=.T1.
  out[$j]=RS.${ID[j]}.nii
  steppath[$j]=DATA/${ID[j]}/${ID[j]}.results/
  [ ! -d ${steppath[$j]} ] && mkdir -p ${steppath[$j]} 2> /dev/null
  [ ! -f ${steppath[$j]}RS.${ID[j]}.nii ] && cp DATA/${ID[j]}/RS.${ID[j]}.nii ${steppath[$j]} 2> /dev/null
  [ ! -f ${steppath[$j]}T1.${ID[j]}.nii ] && cp DATA/${ID[j]}/T1.${ID[j]}.nii ${steppath[$j]} 2> /dev/null
done

#: QC1 ========================================================================

#: QC2 ========================================================================

#: AZTEC ========================================================================
if [ $aztec -eq 1 ]; then
  printf "=============================AZTEC==================================\n\n"
  for j in ${!ID[@]}; do
    prefix[$j]=aztec.RS.
    inputs "${out[$j]}" "RS.${ID[j]}.log"
    outputs "${prefix[$j]}${ID[j]}.nii"
    echo -n "${ID[j]}> "
    if open.node; then
      #
   #  if [ ! -d "3d" ]; then  mkdir 3d ; fi && \
   #  fsl5.0-fslsplit ${in[$j]} 3d_"${ID[j]}"_ -t && \
   #  mv 3d_"${ID[j]}"* 3d && \
   #  gunzip 3d/3d_$i_* && \
      echo "try aztec(); catch; end" > azt_script.m && \
   #  echo "try aztec('${in[2]}',files ,500,$((TR * 1000)),1,$hp,'/3d') catch  quit" > azt_script.m
      matlab -nosplash -r "run azt_script.m" \
   #  rm 3d/3d* && \
   #  3dTcat -prefix ${out[$j]} -TR $TR 3d/aztec* && \
   #  rm 3d/aztec* 3d azt* && \ 
     &> ${prefix[$j]}${ID[j]}.log 
      #
    fi; close.node
    log "Aztec"
  done
  input.error
  echo
fi

#: SLICE TIMING CORRECTION =======================================================
printf "=======================SLICE TIMING CORRECTION====================\n\n"
for j in ${!ID[@]}; do
  prefix[$j]=tshift.RS.
  inputs "${out[$j]}"
  outputs "${prefix[$j]}${ID[j]}+orig"
  echo -n "${ID[j]}> "
  if open.node; then
    #
    3dTshift \
      -tpattern $ptn \
      -prefix ${out[$j]} \
      -Fourier \
      ${in[$j]} &> ${prefix[$j]}${ID[j]}.log 
    #
  fi; close.node
  log "Slice Timing Correction"
done
input.error
echo

#: MOTION CORRECTION ============================================================
printf "\n=========================MOTION CORRECTION=======================\n\n"
for j in ${!ID[@]}; do
  prefix[$j]=volreg.RS.
  inputs "${out[$j]}"
  outputs "${prefix[$j]}${ID[j]}+orig" "mc.${ID[j]}.1d" "mcplot.${ID[j]}.jpg"
  echo -n "${ID[j]}> "
  if open.node; then
   ( 3dvolreg \
    -prefix ${out[$j]} \
    -base 100 \
    -zpad 2 \
    -twopass \
    -Fourier \
    -1Dfile ${out_2[$j]} \
    ${in[$j]} && \
    1dplot \
    -jpg ${out_3[$j]} \
    -volreg -dx $TR \
    -xlabel Time \
    -thick \
    ${out_2[$j]} ) &> ${prefix[$j]}${ID[j]}.log 
  fi; close.node
  log "Motion Correction "
done
input.error
echo

#: QC3 ========================================================================

[ $break -eq 1 ] && echo "Interrompendo script a pedido do usuário" && exit

#: DEOBLIQUE RS ============================================================
printf "\n=========================DEOBLIQUE RS=======================\n\n"
for j in ${!ID[@]}; do
  get.info1 "${steppath[$j]}${out[$j]}"; if [ $is_oblique -eq 1 ]; then 
  prefix[$j]=warp.RS.
  inputs "${out[$j]}"
  outputs "${prefix[$j]}${ID[j]}+orig"
  echo -n "${ID[j]}> "
  if open.node; then
    3dWarp \
    -deoblique \
    -prefix  ${out[$j]} \
    ${in[$j]} &> ${prefix[$j]}${ID[j]}.log 
  fi; close.node
  else echo "${ID[j]} não é obliquo"
  log "DEOBLIQUE RS "; fi
  toRS
done
input.error
echo

#: QC4 ========================================================================

#: DEOBLIQUE T1 ============================================================
printf "\n=========================DEOBLIQUE T1=======================\n\n"
pwd=($PWD)
for j in ${!ID[@]}; do
  get.info1 "${steppath[$j]}T1.${ID[j]}.nii"; if [ $is_oblique -eq 1 ]; then 
  prefix[$j]=warp.T1.
  inputs "T1.${ID[j]}.nii"
  outputs "${prefix[$j]}${ID[j]}+orig"
  echo -n "${ID[j]}> "
  if open.node; then
    3dWarp \
    -deoblique \
    -prefix  ${out[$j]} \
    ${in[$j]} &> ${prefix[$j]}${ID[j]}.log 
  fi; close.node
  else echo "${ID[j]} não é obliquo"
  log "DEOBLIQUE T1 "; fi
  toT1
done 
input.error
echo

#: HOMOGENIZE RS ============================================================
printf "\n=========================HOMOGENIZE RS=======================\n\n"
for j in ${!ID[@]}; do 
  fromRS
  prefix[$j]=zeropad.RS.
  inputs "${out[$j]}"
  outputs "${prefix[$j]}${ID[j]}+orig"
  echo -n "${ID[j]}> "
  if open.node; then
    3dZeropad \
    -RL "$gRL" \
    -AP "$gAP" \
    -IS "$gIS" \
    -prefix ${out[$j]} \
    ${in[$j]} &> ${prefix[$j]}${ID[j]}.log 
  fi; close.node
  log "HOMOGENIZE RS ";
  toRS
done
input.error
echo

#: REORIENT T1 TO TEMPLATE ================================================
printf "\n====================REORIENT T1 TO TEMPLATE===================\n\n"
for j in ${!ID[@]}; do
  fromT1
  get.info1 "template/$template"
  prefix[$j]=resample.T1.
  inputs "${out[$j]}"
  outputs "${prefix[$j]}${ID[j]}+orig"
  echo -n "${ID[j]}> "
  if open.node; then
    3dresample \
    -orient "$orient" \
    -prefix ${out[$j]} \
    -inset ${in[$j]} &> ${prefix[$j]}${ID[j]}.log 
  fi; close.node
  log "REORIENT T1 TO TEMP "
  toT1
done 
input.error
echo

#: REORIENT RS TO TEMPLATE ================================================
printf "\n====================REORIENT RS TO TEMPLATE===================\n\n"
for j in ${!ID[@]}; do
  fromRS
  get.info1 "template/$template"
  prefix[$j]=resample.RS.
  inputs "${out[$j]}"
  outputs "${prefix[$j]}${ID[j]}+orig"
  echo -n "${ID[j]}> "
  if open.node; then
    3dresample \
    -orient "$orient" \
    -prefix ${out[$j]} \
    -inset ${in[$j]} &> ${prefix[$j]}${ID[j]}.log 
  fi; close.node
  log "REORIENT RS TO TEMP "
  toRS
done 
input.error
echo

#: Align center T1 TO TEMPLATE ================================================
printf "\n====================Align center T1 TO TEMPLATE===================\n\n"
for j in ${!ID[@]}; do
  fromT1
  prefix[$j]=align.T1
  inputs "${out[$j]}"
  outputs "${prefix[$j]}${ID[j]}_shft+orig" "${prefix[$j]}${ID[j]}_shft.1D"
  echo -n "${ID[j]}> "
  if open.node; then
    @Align_Centers \
    -base "$template" \
    -dset ${in[$j]} &> ${prefix[$j]}${ID[j]}.log 
  fi; close.node
  log "Align center T1 TO TEMP "
done 
input.error
echo

#: Unifaze T1 ===========================================================
printf "\n=========================Unifaze T1========================\n\n"
for j in ${!ID[@]}; do
  prefix[$j]=unifize.T1.
  inputs "${out[$j]}"
  outputs "${prefix[$j]}${ID[j]}+orig"
  echo -n "${ID[j]}> "
  if open.node; then
    3dUnifize \
    -prefix ${out[$j]} \
    -input ${in[$j]} &> ${prefix[$j]}${ID[j]}.log
  fi; close.node
  log "Unifaze T1 "
done 
input.error
echo

#: SKULLSTRIP ===============================================================

if [ $bet -eq 0 ]; then
  echo "O SKULL STRIP DEVE SER FEITO MANUALMENTE. USE COMO BASE O ARQUIVO QUE ESTÁ NA PASTA OUTPUT/${ID[j]}/manual_skullstrip. NOMEIE O ARQUIVO mask_T1_<SUBID>.nii.gz e salve no diretório base." | fold -s
  for j in ${!ID[@]}; do
    prefix[$j]=mask.T1.
    inputs "${out[$j]}"
    outputs "${prefix[$j]}${ID[j]}.nii.gz"
    [ ! -d "$pwd/OUTPUT/${ID[j]}/manual_skullstrip" ] && mkdir -p $pwd/OUTPUT/${ID[j]}/manual_skullstrip
    cp DATA/${ID[j]}/${ID[j]}.results/${in[$j]} OUTPUT/${ID[j]}/manual_skullstrip 2> /dev/null
    ss=$(find . -name "mask.T1.${ID[j]}*")
    mv $ss /DATA/${ID[j]}/${ID[j]}.results 2> /dev/null
  done
else
  FSLDIR=/usr/share/fsl
  #: BET ============================================================
  printf "\n============================BET============================\n\n"
  pwd=($PWD)
  for j in ${!ID[@]}; do
    prefix[$j]=mask.T1.
    inputs "${out[$j]}"
    outputs "${prefix[$j]}${ID[j]}.nii.gz"
    echo -n "${ID[j]}> "
    if open.node; then
    ( "$fsl5"bet ${in[$j]} ${ID[j]}_step1 -B -f $betf && \
      "$fsl5"flirt -ref ${FSLDIR}/data/standard/MNI152_T1_2mm_brain -in ${ID[j]}_step1.nii.gz -omat ${ID[j]}_step2.mat -out ${ID[j]}_step2 -searchrx -30 30 -searchry -30 30 -searchrz -30 30 && \
      "$fsl5"fnirt --in=${in[$j]} --aff=${ID[j]}_step2.mat --cout=${ID[j]}_step3 --config=T1_2_MNI152_2mm && \
      "$fsl5"applywarp --ref=${FSLDIR}/data/standard/MNI152_T1_2mm --in=${in[$j]} --warp=${ID[j]}_step3 --out=${ID[j]}_step4 && \
      "$fsl5"invwarp -w ${ID[j]}_step3.nii.gz -o ${ID[j]}_step5.nii.gz -r ${ID[j]}_step1.nii.gz && \
      "$fsl5"applywarp --ref=${in[$j]} --in=${FSLDIR}/data/standard/MNI152_T1_1mm_brain_mask.nii.gz --warp=${ID[j]}_step5.nii.gz --out=${ID[j]}_step6 --interp=nn && \
      "$fsl5"fslmaths ${ID[j]}_step6.nii.gz -bin invmask_${ID[j]}.nii.gz && \
      "$fsl5"fslmaths invmask_${ID[j]}.nii.gz -mul -1 -add 1 ${out[$j]} ) &> ${prefix[$j]}${ID[j]}.log
       rm invmask_${ID[j]}.nii.gz ${ID[j]}_step1.nii.gz ${ID[j]}_step1_mask.nii.gz ${ID[j]}_step2.nii.gz ${ID[j]}_step2.mat ${ID[j]}_step3.nii.gz ${ID[j]}_step4.nii.gz ${ID[j]}_step5.nii.gz ${ID[j]}_step6.nii.gz *_to_MNI152_T1_2mm.log 2> /dev/null
    fi; close.node
    log "BET "
  done 
  input.error
  echo
fi 

#: QC5 ========================================================================

[ $break -eq 2 ] && echo "Interrompendo script a pedido do usuário" && exit

#: APPLY MASK TO T1 ===========================================================
printf "\n=========================APPLY MASK T1========================\n\n"
for j in ${!ID[@]}; do
  prefix[$j]=SS.T1.
  inputs "${out[$j]}" "unifize.T1.${ID[j]}+orig"
  outputs "${prefix[$j]}${ID[j]}+orig"
  echo -n "${ID[j]}> "
  if open.node; then
    3dcalc \
    -a        ${in_2[$j]} \
    -b        ${in[$j]} \
    -expr     'a*abs(b-1)' \
    -prefix   ${out[$j]} &> ${prefix[$j]}${ID[j]}.log
  fi; close.node
  log "Apply mask T1 "
  toT1
done 
input.error
echo

#: ALIGN CENTER fMRI-T1 ======================================================
printf "\n=======================ALIGN CENTER fMRI-T1=====================\n\n"
for j in ${!ID[@]}; do
  fromRS
  prefix[$j]=align.RS.
  inputs "${out[$j]}" "SS.T1.${ID[j]}+orig"
  outputs "${prefix[$j]}${ID[j]}_shft+orig" "${prefix[$j]}${ID[j]}_shft.1D"
  echo -n "${ID[j]}> "
  if open.node; then
    @Align_Centers \
    -cm \
    -base ${in_2[$j]} \
    -dset ${in[$j]} &> ${prefix[$j]}${ID[j]}.log
  fi; close.node
  log "Apply mask T1 "
  toRS
done 
input.error
echo

#: COREGISTER fMRI-T1 ======================================================
printf "\n=======================COREGISTER fMRI-T1=====================\n\n"
for j in ${!ID[@]}; do
  fromT1
  prefix[$j]=SS.T1.
  inputs "${out[$j]}" "${prefixrs[$j]}${ID[j]}.nii"
  outputs "${prefix[$j]}${ID[j]}_al+orig" "${prefix[$j]}${ID[j]}_al_mat.1D"
  echo -n "${ID[j]}> "
  if open.node; then
    align_epi_anat.py \
    -anat ${in[$j]} \
    -epi  ${in_2[$j]} \
    -epi_base 100 \
    -anat_has_skull no \
    -volreg off \
    -tshift off \
    -deoblique off &> ${prefix[$j]}${ID[j]}_al.log
  fi; close.node
  log "COREGISTER fMRI-T1 "
done 
input.error
echo

#: QC6 ========================================================================

[ $break -eq 3 ] && echo "Interrompendo script a pedido do usuário" && exit

#: NORMALIZE T1 TO TEMPLATE ======================================================
printf "\n=======================NORMALIZE T1 TO TEMPLATE=====================\n\n"
for j in ${!ID[@]}; do 
  prefix[$j]=MNI.T1.
  inputs "${out[$j]}"
  outputs "${prefix[$j]}${ID[j]}+trlc" "${prefix[$j]}${ID[j]}_WARP+trlc" 
  cp.inputs "$template.HEAD" "$template.BRIK.gz"
  echo -n "${ID[j]}> "
  if open.node; then
    3dQwarp \
      -prefix ${out[$j]} \
      -blur 0 3 \
      -base $template \
      -allineate \
      -source ${in[$j]} &> ${prefix[$j]}${ID[j]}.log
    rm MNI_T1_${ID[j]}_Allin* &>> ${prefix[$j]}${ID[j]}.log
   fi; close.node
  log "NORMALIZE T1 TO TEMPLATE "
  toT1
done 
input.error
echo

#: QC7 ========================================================================

#: fMRI SPATIAL NORMALIZATION ======================================================
printf "\n=======================fMRI SPATIAL NORMALIZATION=====================\n\n"
for j in ${!ID[@]}; do
  fromRS
  prefix[$j]=MNI.RS.
  inputs "${out[$j]}" "${out_2[$j]}"
  outputs "${prefix[$j]}${ID[j]}+tlrc"
  echo -n "${ID[j]}> "
  if open.node; then
    3dNwarpApply \
    -source ${in[$j]} \
    -nwarp ${in_2[$j]} \
    -master "$template" \
    -newgrid 3 \
    -prefix ${out[$j]} &> ${prefix[$j]}${ID[j]}.log
  fi; close.node
  log "fMRI SPATIAL NORMALIZATION "
  toRS
done 
input.error
echo
#: QC8 ========================================================================

[ $break -eq 4 ] && echo "Interrompendo script a pedido do usuário" && exit

#: T1 SEGMENTATION ======================================================
printf "\n=======================T1 SEGMENTATION=====================\n\n"
for j in ${!ID[@]}; do
  fromT1
  prefix[$j]=seg.
  inputs "SS.T1.${ID[j]}_al+orig"
  outputs "${ID[j]}.CSF+orig" "${ID[j]}.WM+orig"
  echo -n "${ID[j]}> "
  if open.node; then
    3dAFNItoNIFTI -prefix SS.T1.${ID[j]}_al.nii ${in[j]}
    ${fsl5}fast \
    -o seg.${ID[j]} \
    -S 1 \
    -t 1 \
    -n 3 \
    SS.T1.${ID[j]}_al.nii &> ${prefix[$j]}${ID[j]}.log
    3dcalc \
    -a seg.${ID[j]}.pve_0.nii.gz \
    -expr 'equals(a,1)' \
    -prefix ${out[$j]} &>> ${prefix[$j]}${ID[j]}.log
    ### now, the WM
    3dcalc \
    -a seg.${ID[j]}.pve_2.nii.gz \
    -expr 'equals(a,1)' \
    -prefix ${out_2[$j]} &>> ${prefix[$j]}${ID[j]}.log
    rm seg.${ID[j]}.* &>> ${prefix[$j]}${ID[j]}.log
  fi; close.node
  log "T1 SEGMENTATION "
done 
input.error
echo

# RS SEGMENTATION ======================================================
printf "\n=======================RS SEGMENTATION=====================\n\n"
for j in ${!ID[@]}; do
  prefix[$j]=segrs.
  inputs "align.RS.${ID[j]}_shift+orig" "${out[$j]}" "${out_2[$j]}"
  outputs "${ID[j]}.CSF.signal.1d" "${ID[j]}.WM.signal.1d"
  echo -n "${ID[j]}> "
  if open.node; then
    ### resample CSF mask
   ( 3dresample \
    -master ${in[$j]} \
    -inset ${in_2[$j]} \
    -prefix "${ID[j]}"_CSF_resampled+orig 
    ### resample WM mask
    3dresample \
    -master ${in[$j]} \
    -inset ${in_3[$j]} \
    -prefix "${ID[j]}"_WM_resampled+orig 
    ### first, mean CSF signal
    3dmaskave \
    -quiet \
    -mask "${ID[j]}"_CSF_resampled+orig \
    ${in[$j]} \
    > ${out[$j]} 
    ### now, mean WM signal
    3dmaskave \
    -quiet \
    -mask "${ID[j]}"_WM_resampled+orig \
    ${in[$j]} \
    > ${out_2[$j]} ) &>> ${prefix[$j]}${ID[j]}.log
    rm "${ID[j]}"_CSF_resampled* "${ID[j]}"_WM_resampled* &>> ${prefix[$j]}${ID[j]}.log
  fi; close.node
  log "RS SEGMENTATION "
done 
input.error
echo

#: QC9 ========================================================================

[ $break -eq 5 ] && echo "Interrompendo script a pedido do usuário" && exit

#: RS FILTERING ======================================================
printf "\n=======================RS FILTERING=====================\n\n"
for j in ${!ID[@]}; do
  fromRS
  prefix[$j]=bandpass.RS.
  inputs "${out[$j]}" "mc.${ID[j]}.1d" "${ID[j]}.CSF.signal.1d" "${ID[j]}.WM.signal.1d"
  outputs "${prefix[$j]}${ID[j]}+trlc" 
  echo -n "${ID[j]}> "
  if open.node; then
   3dBandpass \
  -band 0.01 0.08 \
  -despike \
  -ort ${in_2[$j]} \
  -ort ${in_3[$j]} \
  -ort ${in_4[$j]} \
  -prefix ${out[$j]} \
  -input ${in[$j]} &> ${prefix[$j]}${ID[j]}.log
  fi; close.node
  log "RS FILTERING "
done 
input.error
echo

#: RS SMOOTHING ======================================================
printf "\n=======================RS SMOOTHING=====================\n\n"
for j in ${!ID[@]}; do
  prefix[$j]=merge.RS.
  inputs "${out[$j]}" 
  outputs "${prefix[$j]}${ID[j]}+tlrc"
  echo -n "${ID[j]}> "
  if open.node; then
    3dmerge \
    -1blur_fwhm "$blur" \
    -doall \
    -prefix ${out[$j]} \
    ${in[$j]} &> ${prefix[$j]}${ID[j]}.log
  fi; close.node
  log "RS SMOOTHING "
done 
input.error
echo

if [ $censor -eq 1 ]; then
#: RS MOTIONCENSOR ======================================================
printf "\n=======================RS MOTIONCENSOR=====================\n\n"
for j in ${!ID[@]}; do
  prefix[$j]=censor.RS.
  inputs "${out[$j]}" "mc.${ID[j]}.1d" "RS.${ID[j]}.nii"
  outputs "${prefix[$j]}${ID[j]}+tlrc"
  echo -n "${ID[j]}> "
  if open.node; then
    ### take the temporal derivative of each vector (done as first backward difference)
    1d_tool.py \
    -infile ${in_2[$j]} \
    -derivative \
    -write "${ID[j]}"_RS.deltamotion.1D &>> ${prefix[$j]}${ID[j]}.log

    ### calculate total framewise displacement (sum of six parameters)
    1deval \
    -a "${ID[j]}"_RS.deltamotion.1D'[0]' \
    -b "${ID[j]}"_RS.deltamotion.1D'[1]' \
    -c "${ID[j]}"_RS.deltamotion.1D'[2]' \
    -d "${ID[j]}"_RS.deltamotion.1D'[3]' \
    -e "${ID[j]}"_RS.deltamotion.1D'[4]' \
    -f "${ID[j]}"_RS.deltamotion.1D'[5]' \
    -expr '100*sind(abs(a)/2) + 100*sind(abs(b)/2) + 100*sind(abs(c)/2) + abs(d) + abs(e) + abs(f)' \
    > "${ID[j]}"_RS.deltamotion.FD.1D

    ### create temporal mask (1 = extreme motion)
    1d_tool.py \
    -infile "${ID[j]}"_RS.deltamotion.FD.1D \
    -extreme_mask -1 0.5 \
    -write "${ID[j]}"_RS.deltamotion.FD.extreme0.5.1D &>> ${prefix[$j]}${ID[j]}.log

    ### create temporal mask (0 = extreme motion)
    1deval -a "${ID[j]}"_RS.deltamotion.FD.extreme0.5.1D \
    -expr 'not(a)' \
    > "${ID[j]}"_RS.deltamotion.FD.moderate0.5.1D

    ### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
    1deval \
    -a "${ID[j]}"_RS.deltamotion.FD.moderate0.5.1D \
    -b "${ID[j]}"_RS.deltamotion.FD.moderate0.5.1D'{1..$,0}' \
    -expr 'ispositive(a + b - 1)' \
    > "${ID[j]}"_RS.deltamotion.FD.moderate0.5.n.1D

    ### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
    1deval \
    -a "${ID[j]}"_RS.deltamotion.FD.moderate0.5.n.1D \
    -b "${ID[j]}"_RS.deltamotion.FD.moderate0.5.n.1D'{0,0..$}' \
    -expr 'ispositive(a + b - 1)' \
    > "${ID[j]}"_RS.deltamotion.FD.moderate0.5.n.n.1D

    ### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
    1deval \
    -a "${ID[j]}"_RS.deltamotion.FD.moderate0.5.n.n.1D \
    -b "${ID[j]}"_RS.deltamotion.FD.moderate0.5.n.n.1D'{0,0..$}' \
    -expr 'ispositive(a + b - 1)' \
    > "${ID[j]}"_RS.deltamotion.FD.moderate0.5.n.n.n.1D

    ### normalize and scale the BOLD to percent signal change
    ### find the mean
    3dTstat \
    -mean \
    -prefix meanBOLD_"${ID[j]}" \
    ${in_3[$j]} &>> ${prefix[$j]}${ID[j]}.log
    ### scale BOLD signal to percent change
    3dcalc \
    -a ${in_3[$j]} \
    -b meanBOLD_"${ID[j]}"+orig \
    -expr "(a/b) * 100" \
    -prefix "${ID[j]}"_RS_scaled &>> ${prefix[$j]}${ID[j]}.log
    ### temporal derivative of the frames
    3dcalc \
    -a "${ID[j]}"_RS_scaled+orig \
    -b 'a[0,0,0,-1]' \
    -expr '(a - b)^2' \
    -prefix "${ID[j]}"_RS.backdif2 &>> ${prefix[$j]}${ID[j]}.log
    ### Extract brain mask
    3dAutomask \
    -prefix "${ID[j]}".auto_mask.brain \
    ${in_3[$j]} &>> ${prefix[$j]}${ID[j]}.log
    ### average data from each frame (inside brain mask)
    3dmaskave \
    -mask "${ID[j]}".auto_mask.brain+orig \
    -quiet "${ID[j]}"_RS.backdif2+orig \
    > "${ID[j]}"_RS.backdif2.avg.1D
    ### square root to finally get DVARS
    1deval \
    -a "${ID[j]}"_RS.backdif2.avg.1D \
    -expr 'sqrt(a)' \
    > "${ID[j]}"_RS.backdif2.avg.dvars.1D
    ### mask extreme (1 = extreme motion)
    1d_tool.py \
    -infile "${ID[j]}"_RS.backdif2.avg.dvars.1D \
    -extreme_mask -1 5 \
    -write "${ID[j]}"_RS.backdif2.avg.dvars.extreme5.1D &>> ${prefix[$j]}${ID[j]}.log
    ### mask extreme (0 = extreme motion)
    1deval \
    -a "${ID[j]}"_RS.backdif2.avg.dvars.extreme5.1D \
    -expr 'not(a)' \
    > "${ID[j]}"_RS.backdif2.avg.dvars.moderate5.1D
    ### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
    1deval \
    -a "${ID[j]}"_RS.backdif2.avg.dvars.moderate5.1D \
    -b "${ID[j]}"_RS.backdif2.avg.dvars.moderate5.1D'{1..$,0}' \
    -expr 'ispositive(a + b - 1)' \
    > "${ID[j]}"_RS.backdif2.avg.dvars.moderate5.n.1D
    ### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 2)
    1deval \
    -a "${ID[j]}"_RS.backdif2.avg.dvars.moderate5.n.1D \
    -b "${ID[j]}"_RS.backdif2.avg.dvars.moderate5.n.1D'{0,0..$}' \
    -expr 'ispositive(a + b - 1)' \
    > "${ID[j]}"_RS.backdif2.avg.dvars.moderate5.n.n.1D
    ### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 3)
    1deval \
    -a "${ID[j]}"_RS.backdif2.avg.dvars.moderate5.n.n.1D \
    -b "${ID[j]}"_RS.backdif2.avg.dvars.moderate5.n.n.1D'{0,0..$}' \
    -expr 'ispositive(a + b - 1)' \
    > "${ID[j]}"_RS.backdif2.avg.dvars.moderate5.n.n.n.1D


    ### Integrate FD and DVARS censoring
    ### (only frames censored on both will be excluded, as in Power et al., 2012)

    ### FD censor OR DVARS censor
    1deval \
    -a "${ID[j]}"_RS.deltamotion.FD.moderate0.5.n.n.n.1D \
    -b "${ID[j]}"_RS.backdif2.avg.dvars.moderate5.n.n.n.1D \
    -expr 'or(a, b)' \
    > "${ID[j]}".powerCensorIntersection.1D

    ### Apply censor file in the final preprocessed image (after temporal filtering and spatial blurring)
    afni_restproc.py -apply_censor ${in[$j]} ${ID[j]}.powerCensorIntersection.1D ${out[$j]} &>> ${prefix[$j]}${ID[j]}.log
  fi; close.node
  log "RS MOTIONCENSOR "
done 
input.error
echo

#: QC10 ========================================================================

fi

#: QC11 ========================================================================

#: DATA OUTPUT ===================================================================
printf "\n=======================DATA OUTPUT=====================\n\n"
for j in ${!ID[@]}; do
  prefix[$j]=censor.RS.
  inputs "${out[$j]}" "SS.T1.${ID[j]}+trlc"
  outputs "preproc.RS.${ID[j]}.nii" "SS.T1.${ID[j]}.nii"
  echo -n "${ID[j]}> "
  if open.node; then
  #rm -r OUTPUT/${ID[j]}/manual_skullstrip 2> /dev/null
  3dAFNItoNIFTI -prefix ${out[j]} ${in[j]}
  3dAFNItoNIFTI -prefix ${out_2[j]} ${in_2[j]}
  file=$(find . -name "${out[j]}")
  cp -n $file OUTPUT/${ID[j]}/
  file=$(find . -name "${out_2[j]}")
  cp -n $file OUTPUT/${ID[j]}/
  # incluir quality report aqui tbm
  #file=$(find . -name "report.${ID[j]}.html")
  #cp -n $file OUTPUT/${ID[j]}/
  fi; close.node
  log "DATA OUTPUT "
done 
input.error
echo




exit #=================================================================================
#======================================================================================
#======================================================================================
#======================================================================================
#======================================================================================
#======================================================================================
#======================================================================================


