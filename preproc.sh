#!/usr/bin/env bash

# PROCESSANDO OS ARGUMENTOS ====================================================
usage() {
    echo "Argumentos:"
    echo " $0 [ Opções ] --config <txt com variáveis para análise>  --subs <ID das imagens>" 
    echo 
    echo "Opções:"
    echo
    echo "-a | --aztec  realiza a etapa aztec"
    echo "-b | --bet    realiza o skull strip automatizado (Padrão: Manual)"
    echo
}

aztec=0
bet=0

i=$(($# + 1)) # index of the first non-existing argument
declare -A longoptspec
longoptspec=( [config]=1 [subs]=1 )
optspec=":l:h:a:b:c:s-:"
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
        a|aztec)
            aztec=1
            ;;
        b|bet)
            bet=1
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

# DECLARANDO VARIÁVEIS ===========================================================
declare -A prefix
declare -A in in_2 in_3 in_4 in_5
declare -A inpath
declare -A out out_2 out_3 ou_4 out_5
declare -A outpath
declare -A outrs outt1 outpathrs outpatht1 prefixrs prefixt1
# ==============================================================================

# DECLARANDO FUNÇÕES ===========================================================
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
    in[$i]="$1"
    in_2[$i]="$2"
    in_3[$i]="$3"
    in_4[$i]="$4"
}

outputs () {
    out[$i]="$1"
    out_2[$i]="$2"
    out_3[$i]="$3"
    out_4[$i]="$4"
}

open.node () {
  [ -d ${outpath[$i]} ] || mkdir ${outpath[$i]} 2> /dev/null
  #
  local a=0; local b=0; local c=0; local d=0; local v=0
  ex=0; go=1
  #
  for ii in ${in[$i]} ${in_2[$i]} ${in_3[$i]} ${in_4[$i]}; do
      if [ ! -f ${inpath[$i]}$ii ]; then
          echo "INPUT $ii não encontrado"
          a=$((a + 1))            
      else
          for iii in ${out[$i]} ${out_2[$i]} ${out_3[$i]} ${out_4[$i]}; do
              if [ ! -f ${outpath[$i]}$iii ]; then
                  b=$((b + 1))
                else
                  d=$((d + 1))
                  [ ${outpath[$i]}$iii -ot ${inpath[$i]}$ii ] && c=$((c + 1))
              fi
          done
          [ ! $c -eq 0 ] && echo -n "INPUT $ii MODIFICADO. REFAZENDO ANÁLISE. "
      fi
  done
  #
  if [ $a -eq 0 ]; then
  #
    if [ $b -eq 0 ]; then 
      if [ ! $c -eq 0 ]; then
        for iii in ${out[$i]} ${out_2[$i]} ${out_3[$i]} ${out_4[$i]}; do rm ${outpath[$i]}$iii 2> /dev/null; done
      else
          echo "OUTPUT JÁ EXISTE. PROSSEGUINDO."; go=0; ex=0
      fi
    else
        if [ ! $d -eq 0 ]; then
            echo "OUTPUT CORROMPIDO. REFAZENDO ANÁLISE."
            for ii in ${out[@]}; do rm ${outpath[$i]}$ii 2> /dev/null; done
        fi
    fi
    #
    if [ $go -eq 1 ]; then
      cd ${inpath[$i]}
    fi
  else
  go=0
  fi
  
}

close.node () {
  local e=0
  if [ $go -eq 1 ]; then  
    cd $pwd
    mv ${inpath[$i]}${prefix[$i]}* ${outpath[$i]} 2> /dev/null
     for iii in ${out[$i]} ${out_2[$i]} ${out_3[$i]} ${out_4[$i]}; do 
      [ -f ${outpath[$i]}$iii ] ||  e=$((e + 1)) 
    done
    # 
    if [ ! $e -eq 0 ]; then
     printf "Houve um erro no processamento da imagem %s, consulte o log. \n" "$i" && ex=$((ex + 1))
    else
      printf "Processamento da imagem %s realizado com sucesso! \n" "$i"
    fi
  fi
 cd $pwd
 files=$( find "${inpath[$i]}" -name "${prefix[$i]}*" )
  for f in $files; do
    mv $f ${outpath[$i]} 2> /dev/null
  done
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
  echo >> DATA/preproc_$i.log
  echo "ETAPA: $1  - RUNTIME: $(date)" >> DATA/preproc_$i.log
  echo >> DATA/preproc_$i.log
  echo "PREFIX: ${prefix[$i]}" >> DATA/preproc_$i.log
  echo "INPUT PATH: ${inpath[$i]} "  >> DATA/preproc_$i.log
  echo "INPUTS: ${in[$i]} ${in_2[$i]} ${in_3[$i]} ${in_4[$i]}" >>DATA/preproc_$i.log
  echo "OUTPUT PATH: ${outpath[$i]}" >> DATA/preproc_$i.log
  echo "OUTPUTS: ${out[$i]} ${out_2[$i]} ${out_3[$i]} ${out_4[$i]}" >> DATA/preproc_$i.log
  echo >> DATA/preproc_$i.log
  cat ${outpath[$i]}${prefix[$i]}$i.log >> DATA/preproc_$i.log 2> /dev/null
fi
}

toRS () {
  outrs[$i]=${out[$i]}
  outpathrs[$i]=${outpath[$i]}
  prefixrs[$i]=${prefix[$i]}
  }

toT1 () {
  outt1[$i]=${out[$i]}
  outpatht1[$i]=${outpath[$i]}
  prefixt1[$i]=${prefix[$i]}
}

fromRS () {
  out[$i]=${outrs[$i]}
  outpath[$i]=${outpathrs[$i]}
  prefix[$i]=${prefixrs[$i]}
}

fromT1 () {
  out[$i]=${outt1[$i]}
  outpath[$i]=${outpatht1[$i]}
  prefix[$i]=${prefixt1[$i]}
}

cp.inputs () {
  files=$(find . -name "${in_2[$i]}")
  cp -n ${files[0]} ${inpath[$i]} 2> /dev/null
  files=$(find . -name "${in_3[$i]}")
  cp -n ${files[0]} ${inpath[$i]} 2> /dev/null
  files=$(find . -name "${in_4[$i]}")
  cp -n ${files[0]} ${inpath[$i]} 2> /dev/null
}

# ==============================================================================
 

# INÍCIO =======================================================================

fold -s <<-EOF

Protocolo de pré-processamento de RS-fMRI
--------------------------------------

RUNTIME: $(date)

Programas necessários:
GNU bash           ...$(check bash)
AFNI               ...$(check afni)
FSL                ...$(check fsl5.0-fast)
MATLAB             ...$(check matlab)
  SPM5
  aztec

EOF

if ( ! command -v bash || ! command -v afni || ! command -v fsl5.0-fast  ) > /dev/null ; then
	printf "\nUm ou mais programas necessários para o pré-processamento não estão instalados (acima). Por favor instale o(s) programa(s) faltante(s) ou então verifique se estão configurados na variável de ambiente \$PATH\n\n" | fold -s
	exit
fi
[ $aztec -eq 1 ] && [ ! $(command -v matlab) ] && echo "o Matlab e os plugins SPM5 e aztec são necessários para a análise e não foram encontrados. Certifique-se que eles estão instalados e configurados na variável de ambiente $PATH" | fold -s && exit 

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
    cat > preproc.cfg << EOL
# Variáveis RS-fMRI Preprocessing:

fsl5=fsl5.0-
TR=2
hp=0
ptn=seq+z
mcbase=100
gRL=90
gAP=90
gIS=60
template="MNI152_1mm_uni+tlrc"
betf=0.1
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
Aztec                   - Tempo de repetição(s)   => $TR
Slice timing correction - sequência de aquisição  => $ptn
Motion correction       - valor base              => $mcbase
Homogenize Grid         - tamanho da grade        => $gRL $gAP $gIS

TEMPLATE: $template

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
    printf " RS" 
  else echo " (RS não encontrado)"; a=$((a + 1)) 
  fi
  [ $(find . -name "z_RS_$i.nii") ] && printf " aztec"
  [ $(find . -name "t*_RS_$i.nii") ] && printf " stc"
  [ $(find . -name "rt*_RS_$i.nii") ] && printf " mc"
  printf "\n"
done
echo
if [ ! $a -eq 0 ]; then
    echo "Imagens não foram encontradas ou não estão nomeadas conforme o padrão: RS_<ID>.nii/RS_<ID>.PAR e T1_<ID>.nii/T1_<ID>" | fold -s ; echo
    exit
fi

# BUSCANDO O TEMPLATE
cp /usr/share/afni/atlases/"$template"* . 2> /dev/null
temp=$(find . -name "$template*")
if [ ! -z "$temp" ];then
  [ ! -d template ] && mkdir template 
  for tp in $temp; do
    mv -f $tp template 2> /dev/null
  done
else
  echo "Template $template não encontrado." && exit
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


for i in $ID; do
prefix[$i]=_RS_
prefixt1[$i]=_T1_
out[$i]=RS_$i.nii
outpath[$i]=DATA/$i/
done


# AZTEC========================================================================
if [ $aztec -eq 1 ]; then
  printf "=============================AZTEC==================================\n\n"
  pwd=($PWD)
  for i in $ID; do
    prefix[$i]=z${prefix[$i]}
    inputs "${out[$i]}" "RS_$i.log"
    inpath[$i]=${outpath[$i]}
    outputs "${prefix[$i]}$i.nii"
    outpath[$i]=DATA/$i/aztec/
    echo -n "$i> "
    open.node; if [ $go -eq 1 ]; then
      #
   #  if [ ! -d "3d" ]; then  mkdir 3d ; fi && \
   #  fsl5.0-fslsplit ${in[$i]} 3d_"$i"_ -t && \
   #  mv 3d_"$i"* 3d && \
   #  gunzip 3d/3d_$i_* && \
      echo "try aztec(); catch; end" > azt_script.m && \
   #  echo "try aztec('${in[2]}',files ,500,$((TR * 1000)),1,$hp,'/3d') catch  quit" > azt_script.m
      matlab -nosplash -r "run azt_script.m" \
   #  rm 3d/3d* && \
   #  3dTcat -prefix ${out[$i]} -TR $TR 3d/aztec* && \
   #  rm 3d/aztec* 3d azt* && \ 
     &> ${prefix[$i]}$i.log 
      #
    fi; close.node
    log "Aztec"
  done
  input.error
  echo
fi

# SLICE TIMING CORRECTION=======================================================
printf "=======================SLICE TIMING CORRECTION====================\n\n"
pwd=($PWD)
for i in $ID; do
  prefix[$i]=t${prefix[$i]}
  inputs "${out[$i]}"
  inpath[$i]=${outpath[$i]}
  outputs "${prefix[$i]}$i.nii"
  outpath[$i]=DATA/$i/slice_correction/
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
    #
    3dTshift \
      -verbose \
      -tpattern $ptn \
      -prefix ${out[$i]} \
      -Fourier \
      ${in[$i]} &> ${prefix[$i]}$i.log 
    #
  fi; close.node
  log "Slice Timing Correction"
done
input.error
echo

# MOTION CORRECTION============================================================
printf "\n=========================MOTION CORRECTION=======================\n\n"
pwd=($PWD)
for i in $ID; do
  prefix[$i]=r${prefix[$i]}
  inputs "${out[$i]}"
  inpath[$i]=${outpath[$i]}
  outputs "${prefix[$i]}$i.nii" "${prefix[$i]}mc_$i.1d" "${prefix[$i]}mcplot_$i.jpg"
  outpath[$i]=DATA/$i/motion_correction/
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
    3dvolreg \
    -prefix ${out[$i]} \
    -base 100 \
    -zpad 2 \
    -twopass \
    -Fourier \
    -verbose \
    -1Dfile ${out_2[$i]} \
    ${in[$i]} &>> ${prefix[$i]}$i.log && \
    1dplot \
    -jpg ${out_3[$i]} \
    -volreg -dx $TR \
    -xlabel Time \
    -thick \
    ${out_2[$i]} &>> ${prefix[$i]}$i.log 
  fi; close.node
  log "Motion Correction "
done
input.error
echo

# DEOBLIQUE RS============================================================
printf "\n=========================DEOBLIQUE RS=======================\n\n"
pwd=($PWD)
for i in $ID; do
  get.info1 "${outpath[$i]}${out[$i]}"; if [ $is_oblique -eq 1 ]; then 
  prefix[$i]=d${prefix[$i]}
  inputs "${out[$i]}"
  inpath[$i]=${outpath[$i]}
  outputs "${prefix[$i]}$i.nii"
  outpath[$i]=DATA/$i/deoblique/
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
    3dWarp \
    -verb \
    -deoblique \
    -prefix  ${out[$i]} \
    ${in[$i]} &> ${prefix[$i]}$i.log 
  fi; close.node
  else echo "$i não é obliquo"
  log "DEOBLIQUE RS "; fi
  toRS
done
input.error
echo

# DEOBLIQUE T1============================================================
printf "\n=========================DEOBLIQUE T1=======================\n\n"
pwd=($PWD)
for i in $ID; do
  get.info1 "DATA/$i/T1_$i.nii"; if [ $is_oblique -eq 1 ]; then 
  prefix[$i]=d_T1_
  inputs "T1_$i.nii"
  inpath[$i]=DATA/$i/
  outputs "${prefix[$i]}$i.nii"
  outpath[$i]=DATA/$i/deoblique/
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
    3dWarp \
    -verb \
    -deoblique \
    -prefix  ${out[$i]} \
    ${in[$i]} &> ${prefix[$i]}$i.log 
  fi; close.node
  else echo "$i não é obliquo"
  log "DEOBLIQUE T1 "; fi
  toT1
done 
input.error
echo
 # LEMBAR DE PRINTAR OS DADOS DO GRID NO RELATORIO DO CONTROLE DE QUALIDADE

# HOMOGENIZE RS============================================================
printf "\n=========================HOMOGENIZE RS=======================\n\n"
pwd=($PWD)
for i in $ID; do 
  fromRS
  prefix[$i]=p${prefix[$i]}
  inputs "${out[$i]}"
  inpath[$i]=${outpath[$i]}
  outputs "${prefix[$i]}$i.nii"
  outpath[$i]=DATA/$i/homogenize/
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
    3dZeropad \
    -RL "$gRL" \
    -AP "$gAP" \
    -IS "$gIS" \
    -prefix ${out[$i]} \
    ${in[$i]} &> ${prefix[$i]}$i.log 
  fi; close.node
  log "HOMOGENIZE RS ";
  toRS
done
input.error
echo


# REORIENT T1 TO TEMPLATE================================================
printf "\n====================REORIENT T1 TO TEMPLATE===================\n\n"
pwd=($PWD)
for i in $ID; do
  fromT1
  get.info1 "template/MNI152_1mm_uni+tlrc"
  prefix[$i]=r${prefix[$i]}
  inputs "${out[$i]}"
  inpath[$i]=${outpath[$i]}
  outputs "${prefix[$i]}$i.nii"
  outpath[$i]=DATA/$i/reorient_template/
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
    3dresample \
    -orient "$orient" \
    -prefix ${out[$i]} \
    -inset ${in[$i]} &> ${prefix[$i]}$i.log 
  fi; close.node
  log "REORIENT T1 TO TEMP "
  toT1
done 
input.error
echo

# REORIENT RS TO TEMPLATE================================================
printf "\n====================REORIENT RS TO TEMPLATE===================\n\n"
pwd=($PWD)
for i in $ID; do
  fromRS
  get.info1 "template/MNI152_1mm_uni+tlrc"
  prefix[$i]=r${prefix[$i]}
  inputs "${out[$i]}"
  inpath[$i]=${outpath[$i]}
  outputs "${prefix[$i]}$i.nii"
  outpath[$i]=DATA/$i/reorient_template/
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
    3dresample \
    -orient "$orient" \
    -prefix ${out[$i]} \
    -inset ${in[$i]} &> ${prefix[$i]}$i.log 
  fi; close.node
  log "REORIENT RS TO TEMP "
  toRS
done 
input.error
echo


# Align center T1 TO TEMPLATE================================================
printf "\n====================Align center T1 TO TEMPLATE===================\n\n"
pwd=($PWD)
for i in $ID; do
  fromT1
  prefix[$i]=a${prefix[$i]}
  inputs "${out[$i]}"
  inpath[$i]=${outpath[$i]}
  outputs "${prefix[$i]}$i.nii"
  outpath[$i]=DATA/$i/align_center/
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
    @Align_Centers \
    -base "$template" \
    -dset ${in[$i]} &> ${prefix[$i]}$i.log 
    mv *_shft.nii ${prefix[$i]}$i.nii &>> ${prefix[$i]}$i.log 
    mv *_shft.1D ${prefix[$i]}$i.1D &>> ${prefix[$i]}$i.log 
  fi; close.node
  log "Align center T1 TO TEMP "
done 
input.error
echo

# Unifaze T1 ===========================================================
printf "\n=========================Unifaze T1========================\n\n"
for i in $ID; do
  prefix[$i]=u${prefix[$i]}
  inputs "${out[$i]}"
  inpath[$i]=${outpath[$i]}
  outputs "${prefix[$i]}$i.nii"
  outpath[$i]=DATA/$i/unifaze/
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
    3dUnifize \
    -prefix ${out[$i]} \
    -input ${in[$i]} &> ${prefix[$i]}$i.log
  fi; close.node
  log "Unifaze T1 "
done 
input.error
echo

## =============================================================================
## ====================== SKULLSTRIP MANUAL=====================================
## =============================================================================

if [ $bet -eq 0 ]; then
  echo "O SKULL STRIP DEVE SER FEITO MANUALMENTE. USE COMO BASE O ARQUIVO QUE ESTÁ NA PASTA DATA/manual_skullstrip. NOMEIE O ARQUIVO mask_T1_<SUBID>.nii.gz e salve no diretório base." | fold -s
  for i in $ID; do
    prefix[$i]=mask_T1_
    inputs "${out[$i]}"
    inpath[$i]=${outpath[$i]}
    outputs "${prefix[$i]}$i.nii.gz"
    outpath[$i]=DATA/$i/skullstrip/
    [ ! -d "$pwd/OUTPUT/$i/manual_skullstrip" ] && mkdir -p $pwd/OUTPUT/$i/manual_skullstrip 
    [ ! -d "$pwd/DATA/$i/skullstrip" ] && mkdir -p $pwd/DATA/$i/skullstrip
    cp ${inpath[$i]}${in[$i]} OUTPUT/$i/manual_skullstrip 2> /dev/null
    ss=$(find . -name "mask_T1_$i*")
    mv $ss /DATA/$i/skullstrip 2> /dev/null
  done
  else
  FSLDIR=/usr/share/fsl
  # BET ============================================================
  printf "\n============================BET============================\n\n"
  pwd=($PWD)
  for i in $ID; do
    prefix[$i]=mask_T1_
    inputs "${out[$i]}"
    inpath[$i]=${outpath[$i]}
    outputs "${prefix[$i]}$i.nii.gz"
    outpath[$i]=DATA/$i/skullstrip/
    echo -n "$i> "
    open.node; if [ $go -eq 1 ]; then
      "$fsl5"bet ${in[$i]} ${i}_step1 -B -f $betf && \
      "$fsl5"flirt -ref ${FSLDIR}/data/standard/MNI152_T1_2mm_brain -in ${i}_step1.nii.gz -omat ${i}_step2.mat -out ${i}_step2 -search rx -30 30 -searchry -30 30 -searchrz -30 30 && \
      "$fsl5"fnirt --in=${in[$i]} --aff=${i}_step2.mat --cout=${i}_step3 --config=T1_2_MNI152_2mm && \
      "$fsl5"applywarp --ref=${FSLDIR}/data/standard/MNI152_T1_2mm --in=${in[$i]} --warp=${i}_step3 --out=${i}_step4 && \
      "$fsl5"invwarp -w ${i}_step3.nii.gz -o ${i}_step5.nii.gz -r ${i}_step1.nii.gz && \
      "$fsl5"applywarp --ref=${in[$i]} --in=${FSLDIR}/data/standard/MNI152_T1_1mm_brain_mask.nii.gz --warp=${i}_step5.nii.gz --out=${i}_step6 --interp=nn && \
      "$fsl5"fslmaths ${i}_step6.nii.gz -bin invmask_$i.nii.gz && \
      "$fsl5"fslmaths invmask_$i.nii.gz -mul -1 -add 1 ${out[$i]} &> ${prefix[$i]}$i.log
       rm invmask_$i.nii.gz ${i}_step1.nii.gz ${i}_step1_mask.nii.gz ${i}_step2.nii.gz ${i}_step2.mat ${i}_step3.nii.gz ${i}_step4.nii.gz ${i}_step5.nii.gz ${i}_step6.nii.gz ${i}_to_MNI152_T1_2mm.log 2> /dev/null
    fi; close.node
    log "BET "
  done 
  input.error
  echo
fi 



# APPLY MASK TO T1 ===========================================================
printf "\n=========================APPLY MASK T1========================\n\n"
for i in $ID; do
  prefix[$i]=SS_T1_
  inputs "${out[$i]}" "uard_T1_$i.nii"
  inpath[$i]=${outpath[$i]}
  outputs "${prefix[$i]}$i.nii"
  outpath[$i]=DATA/$i/apply_mask/
  cp.inputs
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
    3dcalc \
    -a        ${in_2[$i]} \
    -b        ${in[$i]} \
    -expr     'a*abs(b-1)' \
    -prefix   ${out[$i]} &> ${prefix[$i]}$i.log
  fi; close.node
  log "Apply mask T1 "
  toT1
done 
input.error
echo

rm -r OUTPUT/$i/manual_skullstrip 2> /dev/null

# ALIGN CENTER fMRI-T1 ======================================================
printf "\n=======================ALIGN CENTER fMRI-T1=====================\n\n"
for i in $ID; do
  fromRS
  prefix[$i]=a${prefix[$i]}
  inputs "${out[$i]}" "SS_T1_$i.nii"
  inpath[$i]=${outpath[$i]}
  outputs "${prefix[$i]}$i.nii" "${prefix[$i]}$i.1D"
  outpath[$i]=DATA/$i/align_center2/
  cp.inputs
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
    @Align_Centers \
    -cm \
    -base ${in_2[$i]} \
    -dset ${in[$i]} &> ${prefix[$i]}$i.log
    mv *_shft.nii ${prefix[$i]}$i.nii &>> ${prefix[$i]}$i.log 
    mv *_shft.1D ${prefix[$i]}$i.1D &>> ${prefix[$i]}$i.log 
  fi; close.node
  log "Apply mask T1 "
  toRS
done 
input.error
echo


# COREGISTER fMRI-T1 ======================================================
printf "\n=======================COREGISTER fMRI-T1=====================\n\n"
for i in $ID; do
  fromT1
  prefix[$i]=c${prefix[$i]}
  inputs "${out[$i]}" "${prefixrs[$i]}$i.nii"
  inpath[$i]=${outpath[$i]}
  outputs "${prefix[$i]}$i.nii"
  outpath[$i]=DATA/$i/coregistration/
  cp.inputs
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
    #align_epi_anat.py \
    #-anat ${in[$i]} \
    #-epi  ${in_2[$i]} \
    #-epi_base 100 \
    #-anat_has_skull no \
    #-volreg off \
    #-tshift off \
    #-deoblique off &> ${prefix[$i]}$i.log
    3dAFNItoNIFTI -prefix ${out[$i]} SS_T1_${i}_al+orig
   # mv *_shft.nii ${prefix[$i]}$i.nii &>> ${prefix[$i]}$i.log 
   # mv *_shft.1D ${prefix[$i]}$i.1D &>> ${prefix[$i]}$i.log 
  fi; close.node
  log "COREGISTER fMRI-T1 "
done 
input.error
echo


exit




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
