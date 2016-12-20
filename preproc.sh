#!/usr/bin/env bash

#: PROCESSANDO OS ARGUMENTOS ====================================================
usage() {
    echo "Argumentos:"
    echo " $0 [ Opções ] --config <txt com variáveis para análise>  --subs <ID das imagens>" 
    echo 
    echo "Opções:"
    echo
    echo "-a | --aztec  realiza a etapa aztec"
    echo "-b | --bet    realiza o skull strip automatizado (Padrão: Manual)"
    echo "-m | --motioncensor  aplica a técnica motion censor"    
    echo "-p | --break  interrompe o script no breakpoint de numero indicado"
    echo
}

aztec=0
bet=0
censor=0
break=0

i=$(($# + 1)) # index of the first non-existing argument
declare -A longoptspec
longoptspec=( [config]=1 [subs]=1 [break]=1 )
optspec=":l:h:a:b:c:s:m:p-:"
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
        m|motioncensor)
            censor=1
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
        p|break)
            break=$OPTARG
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

#: DECLARANDO VARIÁVEIS ===========================================================
declare -A prefix
declare -A in in_2 in_3 in_4 in_5
declare -A out out_2 out_3 ou_4 out_5
declare -A outrs outt1 prefixrs prefixt1

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
  local a=0; local b=0; local c=0; local d=0
  ex=0; go=1
  #
  cd ${steppath[$i]}
  for ii in ${in[$i]} ${in_2[$i]} ${in_3[$i]} ${in_4[$i]} ${in_5[$i]}; do
    [ ! -f $ii ] && echo "INPUT $ii não encontrado" && a=$((a + 1))
    for iii in ${out[$i]} ${out_2[$i]} ${out_3[$i]} ${out_4[$i]} ${out_5[$i]}; do
      [ ! -f $iii ] && b=$((b + 1)) || c=$((c + 1))
      [ $iii -ot $ii ] && printf "INPUT $ii MODIFICADO. REFAZENDO ANÁLISE. " && d=$((d + 1))
    done
  done
  #
  if [ $a -eq 0 ]; then
    if [ $b -eq 0 ]; then 
      if [ ! $d -eq 0 ]; then
        for iii in ${out[$i]} ${out_2[$i]} ${out_3[$i]} ${out_4[$i]} ${out_5[$i]}; do rm $iii 2> /dev/null; done
        go=1
      else
        echo "OUTPUT JÁ EXISTE. PROSSEGUINDO."; go=0; ex=0
      fi
    else
      if [ ! $c -eq 0 ]; then
        echo "OUTPUT CORROMPIDO. REFAZENDO ANÁLISE."
        for iii in ${out[$i]} ${out_2[$i]} ${out_3[$i]} ${out_4[$i]} ${out_5[$i]}; do rm $iii 2> /dev/null; done
        go=1
      else
        go=0
      fi
    fi
  else
    go=0
  fi  
}

close.node () {
  local a=0
  if [ $go -eq 1 ]; then  
    for iii in ${out[$i]} ${out_2[$i]} ${out_3[$i]} ${out_4[$i]}; do 
      [ -f $iii ] ||  a=$((a + 1)) 
    done
    if [ ! $a -eq 0 ]; then
      printf "Houve um erro no processamento da imagem %s, consulte o log. \n" "$i" && ex=$((ex + 1))
    else
      printf "Processamento da imagem %s realizado com sucesso! \n" "$i"
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
{echo 
  echo "ETAPA: $1  - RUNTIME: $(date)" 
  echo 
  echo "PREFIX: ${prefix[$i]}"  
  echo "INPUTS: ${in[$i]} ${in_2[$i]} ${in_3[$i]} ${in_4[$i]}" 
  echo "OUTPUTS: ${out[$i]} ${out_2[$i]} ${out_3[$i]} ${out_4[$i]}"
  echo 
  cat DATA/$i/STEPS/${prefix[$i]}$i.log} >> OUTPUT/$i/preproc_$i.log
fi
}

toRS () {
  outrs[$i]=${out[$i]}
  prefixrs[$i]=${prefix[$i]}
  }

toT1 () {
  outt1[$i]=${out[$i]}
  prefixt1[$i]=${prefix[$i]}
}

fromRS () {
  out[$i]=${outrs[$i]}
  prefix[$i]=${prefixrs[$i]}
}

fromT1 () {
  out[$i]=${outt1[$i]}
  prefix[$i]=${prefixt1[$i]}
}

cp.inputs () {
  files=$(find . -name "$1")
  cp -n ${files[0]} ${steppath[$i]} 2> /dev/null
  files=$(find . -name "$2")
  cp -n ${files[0]} ${steppath[$i]} 2> /dev/null
  files=$(find . -name "$3")
  cp -n ${files[0]} ${steppath[$i]} 2> /dev/null
}

#: INÍCIO =======================================================================
fold -s <<-EOF

Protocolo de pré-processamento de RS-fMRI
--------------------------------------

RUNTIME: $(date)

Programas necessários:
GNU bash           ...$(check bash)
AFNI               ...$(check afni)
FSL                ...$(check fsl5.0-fast)
Pyhton             ---$(check python)
MATLAB             ...$(check matlab)
  SPM5
  aztec

EOF

# checando se todos os programas necessários estão instalados
if ( ! command -v bash || ! command -v afni || ! command -v fsl5.0-fast || ! command -v python  ) > /dev/null ; then
	printf "\nUm ou mais programas necessários para o pré-processamento não estão instalados (acima). Por favor instale o(s) programa(s) faltante(s) ou então verifique se estão configurados na variável de ambiente \$PATH\n\n" | fold -s
	exit
fi
[ $aztec -eq 1 ] && [ ! $(command -v matlab) ] && echo "o Matlab e os plugins SPM5 e aztec são necessários para a análise e não foram encontrados. Certifique-se que eles estão instalados e configurados na variável de ambiente $PATH" | fold -s && exit 

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

# informando os usuários das variáveis definidas ou defaults
fold -s <<-EOF
As variáveis que serão usadas como parametros para as análises são:
Aztec                   - Tempo de repetição(s)   => $TR
Slice timing correction - sequência de aquisição  => $ptn
Motion correction       - valor base              => $mcbase
Homogenize Grid         - tamanho da grade        => $gRL $gAP $gIS
BET                     - bet f                   => $betf
3dBandpass              - filtro gaussiano        => $blur

TEMPLATE: $template

EOF

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
ID=$(cat $subs)

# Checando imagens com os nomes fornecidos
echo "Lista de indivíduos para análise:"
a=0
for i in $ID; do 
  echo -n "$i  ... " 
  [ $(find . -name "T1_$i.nii") ] && printf "T1" || printf "(T1 não encontrado)"; a=$((a + 1))
  [ $(find . -name "RS_$i.nii") ] && printf " RS" || printf " (RS não encontrado)"; a=$((a + 1)) 
  [ $(find . -name "z_RS_$i.nii") ] && printf " aztec"
  [ $(find . -name "t*_RS_$i.nii") ] && printf " stc"
  [ $(find . -name "rt*_RS_$i.nii") ] && printf " mc"
  [ $(find . -name "SS_T1_$i.nii") ] && printf " ss"
  [ $(find . -name "MNI_T1_$i.nii") ] && printf " nm"
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

# CHECANDO SE OUTPUT JÁ EXISTE
for i in $ID; do
file=$(find . -name "bf*_RS_$i.nii")
cp -n $file OUTPUT/$i/
file=$(find . -name "cbf*_RS_$i.nii")
cp -n $file OUTPUT/$i/
file=$(find . -name "preproc_$i.log")
cp -n $file OUTPUT/$i/
file=$(find . -name "SS_T1_$i.nii")
cp -n $file OUTPUT/$i/
# incluir quality report aqui tbm
#file=$(find . -name "report_$i.html")
#cp -n $file OUTPUT/$i/
done

# Preparando para iniciar a análise
[ -d DATA ] || mkdir DATA
[ -d OUTPUT ] || mkdir OUTPUT

unset a; a=0
for i in $ID; do
  [ -d DATA/$i ] || mkdir DATA/$i 
  [ -d OUTPUT/$i ] || mkdir OUTPUT/$i 
  for ii in T1_$i.nii RS_$i.nii physlog_$i; do
    [ ! -f DATA/$i/$ii ] && wp=$(find . -name $ii) && rp=DATA/$i/$ii && mv $wp $rp 2> /dev/null && a=$((a + 1))
  done
done
if [ ! $a -eq 0 ]; then 
  echo "O caminho das imagens não está conformado com o padrâo: DATA/<ID>/T1_<ID>.nii"
  echo "Conformando..."
  echo
fi

pwd=($PWD)

#: DATA INPUT ====================================================================
for i in $ID; do
  prefix[$i]=_RS_
  prefixt1[$i]=_T1_
  out[$i]=RS_$i.nii
  steppath[$i]=DATA/$i/STEPS
  [ ! -d $steppath ] && mkdir -p $steppath
  [ ! -f $steppath/RS_$i.nii ] && cp DATA/$i/RS_$i.nii $steppath 2> /dev/null
  [ ! -f $steppath/T1_$i.nii ] && cp DATA/$i/T1_$i.nii $steppath 2> /dev/null
done

#: QC1 ========================================================================

#: QC2 ========================================================================

#: AZTEC ========================================================================
if [ $aztec -eq 1 ]; then
  printf "=============================AZTEC==================================\n\n"
  for i in $ID; do
    prefix[$i]=z${prefix[$i]}
    inputs "${out[$i]}" "RS_$i.log"
    outputs "${prefix[$i]}$i.nii"
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

#: SLICE TIMING CORRECTION =======================================================
printf "=======================SLICE TIMING CORRECTION====================\n\n"
for i in $ID; do
  prefix[$i]=t${prefix[$i]}
  inputs "${out[$i]}"
  outputs "${prefix[$i]}$i.nii"
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

#: MOTION CORRECTION ============================================================
printf "\n=========================MOTION CORRECTION=======================\n\n"
for i in $ID; do
  prefix[$i]=r${prefix[$i]}
  inputs "${out[$i]}"
  outputs "${prefix[$i]}$i.nii" "mc_$i.1d" "${prefix[$i]}mcplot_$i.jpg"
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

#: QC3 ========================================================================

[ $break -eq 1 ] && echo "Interrompendo script a pedido do usuário" && exit

#: DEOBLIQUE RS ============================================================
printf "\n=========================DEOBLIQUE RS=======================\n\n"
for i in $ID; do
  get.info1 "${out[$i]}"; if [ $is_oblique -eq 1 ]; then 
  prefix[$i]=d${prefix[$i]}
  inputs "${out[$i]}"
  outputs "${prefix[$i]}$i.nii"
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

#: QC4 ========================================================================

#: DEOBLIQUE T1 ============================================================
printf "\n=========================DEOBLIQUE T1=======================\n\n"
pwd=($PWD)
for i in $ID; do
  get.info1 "T1_$i.nii"; if [ $is_oblique -eq 1 ]; then 
  prefix[$i]=d_T1_
  inputs "T1_$i.nii"
  outputs "${prefix[$i]}$i.nii"
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

#: HOMOGENIZE RS ============================================================
printf "\n=========================HOMOGENIZE RS=======================\n\n"
for i in $ID; do 
  fromRS
  prefix[$i]=p${prefix[$i]}
  inputs "${out[$i]}"
  outputs "${prefix[$i]}$i.nii"
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


#: REORIENT T1 TO TEMPLATE ================================================
printf "\n====================REORIENT T1 TO TEMPLATE===================\n\n"
for i in $ID; do
  fromT1
  get.info1 "template/$template"
  prefix[$i]=r${prefix[$i]}
  inputs "${out[$i]}"
  outputs "${prefix[$i]}$i.nii"
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

#: REORIENT RS TO TEMPLATE ================================================
printf "\n====================REORIENT RS TO TEMPLATE===================\n\n"
for i in $ID; do
  fromRS
  get.info1 "template/$template"
  prefix[$i]=r${prefix[$i]}
  inputs "${out[$i]}"
  outputs "${prefix[$i]}$i.nii"
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


#: Align center T1 TO TEMPLATE ================================================
printf "\n====================Align center T1 TO TEMPLATE===================\n\n"
for i in $ID; do
  fromT1
  prefix[$i]=a${prefix[$i]}
  inputs "${out[$i]}"
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

#: Unifaze T1 ===========================================================
printf "\n=========================Unifaze T1========================\n\n"
for i in $ID; do
  prefix[$i]=u${prefix[$i]}
  inputs "${out[$i]}"
  outputs "${prefix[$i]}$i.nii"
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

#: SKULLSTRIP ===============================================================

if [ $bet -eq 0 ]; then
  echo "O SKULL STRIP DEVE SER FEITO MANUALMENTE. USE COMO BASE O ARQUIVO QUE ESTÁ NA PASTA OUTPUT/$i/manual_skullstrip. NOMEIE O ARQUIVO mask_T1_<SUBID>.nii.gz e salve no diretório base." | fold -s
  for i in $ID; do
    prefix[$i]=mask_T1_
    inputs "${out[$i]}"
    outputs "${prefix[$i]}$i.nii.gz"
    [ ! -d "$pwd/OUTPUT/$i/manual_skullstrip" ] && mkdir -p $pwd/OUTPUT/$i/manual_skullstrip
    cp DATA/$i/STEPS/${in[$i]} OUTPUT/$i/manual_skullstrip 2> /dev/null
    ss=$(find . -name "mask_T1_$i*")
    mv $ss /DATA/$i/STEPS 2> /dev/null
  done
else
  FSLDIR=/usr/share/fsl
  #: BET ============================================================
  printf "\n============================BET============================\n\n"
  pwd=($PWD)
  for i in $ID; do
    prefix[$i]=mask_T1_
    inputs "${out[$i]}"
    outputs "${prefix[$i]}$i.nii.gz"
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

#: QC5 ========================================================================

[ $break -eq 2 ] && echo "Interrompendo script a pedido do usuário" && exit

#: APPLY MASK TO T1 ===========================================================
printf "\n=========================APPLY MASK T1========================\n\n"
for i in $ID; do
  prefix[$i]=SS_T1_
  inputs "${out[$i]}" "uard_T1_$i.nii"
  outputs "${prefix[$i]}$i.nii"
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

#: ALIGN CENTER fMRI-T1 ======================================================
printf "\n=======================ALIGN CENTER fMRI-T1=====================\n\n"
for i in $ID; do
  fromRS
  prefix[$i]=a${prefix[$i]}
  inputs "${out[$i]}" "SS_T1_$i.nii"
  outputs "${prefix[$i]}$i.nii" "${prefix[$i]}$i.1D"
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

#: COREGISTER fMRI-T1 ======================================================
printf "\n=======================COREGISTER fMRI-T1=====================\n\n"
for i in $ID; do
  fromT1
  prefix[$i]=c${prefix[$i]}; decalre -A segrs[$i]=${prefix[$i]}
  inputs "${out[$i]}" "${prefixrs[$i]}$i.nii"
  outputs "${prefix[$i]}$i.nii"
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
    align_epi_anat.py \
    -anat ${in[$i]} \
    -epi  ${in_2[$i]} \
    -epi_base 100 \
    -anat_has_skull no \
    -volreg off \
    -tshift off \
    -deoblique off &> ${prefix[$i]}$i.log
    3dAFNItoNIFTI -prefix ${out[$i]} SS_T1_${i}_al+orig
  fi; close.node
  log "COREGISTER fMRI-T1 "
done 
input.error
echo

#: QC6 ========================================================================

[ $break -eq 3 ] && echo "Interrompendo script a pedido do usuário" && exit

#: NORMALIZE T1 TO TEMPLATE ======================================================
printf "\n=======================NORMALIZE T1 TO TEMPLATE=====================\n\n"
for i in $ID; do 
  prefix[$i]=MNI_T1_
  inputs "${out[$i]}" 
  outputs "${prefix[$i]}$i.nii"
  cp.inputs "$template.HEAD" "$template.BRIK.gz"
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
    3dQwarp \
      -prefix ${out[$i]} \
      -blur 0 3 \
      -base $template \
      -allineate \
      -source ${in[$i]} &> ${prefix[$i]}$i.log
   fi; close.node
  log "NORMALIZE T1 TO TEMPLATE "
  toT1
done 
input.error
echo

#: QC7 ========================================================================

#: fMRI SPATIAL NORMALIZATION ======================================================
printf "\n=======================fMRI SPATIAL NORMALIZATION=====================\n\n"
for i in $ID; do
  fromRS
  prefix[$i]=${prefix[$i]}_MNI_
  inputs "${out[$i]}" "$template.HEAD" "$template.BRIK.gz"
  outputs "${prefix[$i]}$i.nii"
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
   3drename MNI_T1_"$i"_WARP+tlrc MNI_T1_WARP
    3dNwarpApply \
    -source ${in[$i]} \
    -nwarp 'MNI_T1_WARP+tlrc' \
    -master "$template" \
    -newgrid 3 \
    -prefix ${out[$i]} &> ${prefix[$i]}$i.log
    3drename MNI_T1_WARP+tlrc MNI_T1_"$i"_WARP
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
for i in $ID; do
  fromT1
  prefix[$i]=seg_
  inputs "${out[$i]}"
  outputs "${prefix[$i]}$i.nii" "${i}_CSF.nii" "${i}_WM.nii"
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
    ${fsl5}fast \
    -o ${out[$i]} \
    -S 1 \
    -t 1 \
    -n 3 \
    cSS_T1_"$i".nii &> ${prefix[$i]}$i.log
    3dcalc \
    -a seg_"$i"_pve_0.nii.gz \
    -expr 'equals(a,1)' \
    -prefix ${out_2[$i]} &>> ${prefix[$i]}$i.log
    ### now, the WM
    3dcalc \
    -a seg_"$i"_pve_2.nii.gz \
    -expr 'equals(a,1)' \
    -prefix ${out_3[$i]} &>> ${prefix[$i]}$i.log
  fi; close.node
  log "T1 SEGMENTATION "
done 
input.error
echo

# RS SEGMENTATION ======================================================
printf "\n=======================RS SEGMENTATION=====================\n\n"
for i in $ID; do
  inputs "${segrs[$i]}$i.nii" "${out_2[$i]}" "${out_3[$i]}"
  outputs "${i}_CSF_signal.1d" "${i}_WM_signal.1d"
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
    ### resample CSF mask
    3dresample \
    -master ${in[$i]} \
    -inset ${in_2[$i]} \
    -prefix "$i"_CSF_resampled+orig &>> ${prefix[$i]}$i.log
    ### resample WM mask
    3dresample \
    -master ${in[$i]} \
    -inset ${in_3[$i]} \
    -prefix "$i"_WM_resampled+orig &>> ${prefix[$i]}$i.log
    ### first, mean CSF signal
    3dmaskave \
    -mask "$i"_CSF_resampled+orig \
    -quiet \
    ${in[$i]} \
    > ${out[$i]}
    ### now, mean WM signal
    3dmaskave \
    -mask "$i"_WM_resampled+orig \
    -quiet \
    ${in[$i]} \
    > ${out_2[$i]}
  fi; close.node
  log "RS SEGMENTATION "
done 
input.error
echo

#: QC9 ========================================================================

[ $break -eq 5 ] && echo "Interrompendo script a pedido do usuário" && exit

#: RS FILTERING ======================================================
printf "\n=======================RS FILTERING=====================\n\n"
for i in $ID; do
  fromRS
  prefix[$i]=f${prefix[$i]}
  inputs "${out[$i]}" 
  outputs "${prefix[$i]}$i.nii" "mc_$i.1d" "$i_CSF_signal.1d" "$i_WM_signal.1d"
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
   3dBandpass \
  -band 0.01 0.08 \
  -despike \
  -ort mc_"$i".1d \
  -ort "$i"_CSF_signal.1d \
  -ort "$i"_WM_signal.1d \
  -prefix ${out[$i]} \
  -input ${in[$i]} &> ${prefix[$i]}$i.log
  fi; close.node
  log "RS SEGMENTATION "
done 
input.error
echo

#: RS SMOOTHING ======================================================
printf "\n=======================RS SMOOTHING=====================\n\n"
for i in $ID; do
  prefix[$i]=b${prefix[$i]}
  inputs "${out[$i]}" 
  outputs "${prefix[$i]}$i.nii"
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
    3dmerge \
    -1blur_fwhm "$blur" \
    -doall \
    -prefix ${out[$i]} \
    ${in[$i]} &> ${prefix[$i]}$i.log
  fi; close.node
  log "RS SMOOTHING "
done 
input.error
echo

if [ $censor -eq 1 ]; then
#: RS MOTIONCENSOR ======================================================
printf "\n=======================RS MOTIONCENSOR=====================\n\n"
for i in $ID; do
  prefix[$i]=c${prefix[$i]}
  inputs "${out[$i]}" "mc_$i.1d" "RS_$i.nii"
  outputs "${prefix[$i]}$i.nii"
  cp.inputs
  echo -n "$i> "
  open.node; if [ $go -eq 1 ]; then
    ### take the temporal derivative of each vector (done as first backward difference)
    1d_tool.py \
    -infile ${in_2[$i]} \
    -derivative \
    -write "$i"_RS.deltamotion.1D &>> ${prefix[$i]}$i.log

    ### calculate total framewise displacement (sum of six parameters)
    1deval \
    -a "$i"_RS.deltamotion.1D'[0]' \
    -b "$i"_RS.deltamotion.1D'[1]' \
    -c "$i"_RS.deltamotion.1D'[2]' \
    -d "$i"_RS.deltamotion.1D'[3]' \
    -e "$i"_RS.deltamotion.1D'[4]' \
    -f "$i"_RS.deltamotion.1D'[5]' \
    -expr '100*sind(abs(a)/2) + 100*sind(abs(b)/2) + 100*sind(abs(c)/2) + abs(d) + abs(e) + abs(f)' \
    > "$i"_RS.deltamotion.FD.1D

    ### create temporal mask (1 = extreme motion)
    1d_tool.py \
    -infile "$i"_RS.deltamotion.FD.1D \
    -extreme_mask -1 0.5 \
    -write "$i"_RS.deltamotion.FD.extreme0.5.1D &>> ${prefix[$i]}$i.log

    ### create temporal mask (0 = extreme motion)
    1deval -a "$i"_RS.deltamotion.FD.extreme0.5.1D \
    -expr 'not(a)' \
    > "$i"_RS.deltamotion.FD.moderate0.5.1D

    ### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
    1deval \
    -a "$i"_RS.deltamotion.FD.moderate0.5.1D \
    -b "$i"_RS.deltamotion.FD.moderate0.5.1D'{1..$,0}' \
    -expr 'ispositive(a + b - 1)' \
    > "$i"_RS.deltamotion.FD.moderate0.5.n.1D

    ### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
    1deval \
    -a "$i"_RS.deltamotion.FD.moderate0.5.n.1D \
    -b "$i"_RS.deltamotion.FD.moderate0.5.n.1D'{0,0..$}' \
    -expr 'ispositive(a + b - 1)' \
    > "$i"_RS.deltamotion.FD.moderate0.5.n.n.1D

    ### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
    1deval \
    -a "$i"_RS.deltamotion.FD.moderate0.5.n.n.1D \
    -b "$i"_RS.deltamotion.FD.moderate0.5.n.n.1D'{0,0..$}' \
    -expr 'ispositive(a + b - 1)' \
    > "$i"_RS.deltamotion.FD.moderate0.5.n.n.n.1D

    ### normalize and scale the BOLD to percent signal change
    ### find the mean
    3dTstat \
    -mean \
    -prefix meanBOLD_"$i" \
    ${in_3[$i]} &>> ${prefix[$i]}$i.log
    ### scale BOLD signal to percent change
    3dcalc \
    -a ${in_3[$i]} \
    -b meanBOLD_"$i"+orig \
    -expr "(a/b) * 100" \
    -prefix "$i"_RS_scaled &>> ${prefix[$i]}$i.log
    ### temporal derivative of the frames
    3dcalc \
    -a "$i"_RS_scaled+orig \
    -b 'a[0,0,0,-1]' \
    -expr '(a - b)^2' \
    -prefix "$i"_RS.backdif2 &>> ${prefix[$i]}$i.log
    ### Extract brain mask
    3dAutomask \
    -prefix "$i".auto_mask.brain \
    ${in_3[$i]} &>> ${prefix[$i]}$i.log
    ### average data from each frame (inside brain mask)
    3dmaskave \
    -mask "$i".auto_mask.brain+orig \
    -quiet "$i"_RS.backdif2+orig \
    > "$i"_RS.backdif2.avg.1D
    ### square root to finally get DVARS
    1deval \
    -a "$i"_RS.backdif2.avg.1D \
    -expr 'sqrt(a)' \
    > "$i"_RS.backdif2.avg.dvars.1D
    ### mask extreme (1 = extreme motion)
    1d_tool.py \
    -infile "$i"_RS.backdif2.avg.dvars.1D \
    -extreme_mask -1 5 \
    -write "$i"_RS.backdif2.avg.dvars.extreme5.1D &>> ${prefix[$i]}$i.log
    ### mask extreme (0 = extreme motion)
    1deval \
    -a "$i"_RS.backdif2.avg.dvars.extreme5.1D \
    -expr 'not(a)' \
    > "$i"_RS.backdif2.avg.dvars.moderate5.1D
    ### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 1)
    1deval \
    -a "$i"_RS.backdif2.avg.dvars.moderate5.1D \
    -b "$i"_RS.backdif2.avg.dvars.moderate5.1D'{1..$,0}' \
    -expr 'ispositive(a + b - 1)' \
    > "$i"_RS.backdif2.avg.dvars.moderate5.n.1D
    ### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 2)
    1deval \
    -a "$i"_RS.backdif2.avg.dvars.moderate5.n.1D \
    -b "$i"_RS.backdif2.avg.dvars.moderate5.n.1D'{0,0..$}' \
    -expr 'ispositive(a + b - 1)' \
    > "$i"_RS.backdif2.avg.dvars.moderate5.n.n.1D
    ### temporal are augmented by also marking the frames 1 back and 2 forward from any marked frames (step 3)
    1deval \
    -a "$i"_RS.backdif2.avg.dvars.moderate5.n.n.1D \
    -b "$i"_RS.backdif2.avg.dvars.moderate5.n.n.1D'{0,0..$}' \
    -expr 'ispositive(a + b - 1)' \
    > "$i"_RS.backdif2.avg.dvars.moderate5.n.n.n.1D


    ### Integrate FD and DVARS censoring
    ### (only frames censored on both will be excluded, as in Power et al., 2012)

    ### FD censor OR DVARS censor
    1deval \
    -a "$i"_RS.deltamotion.FD.moderate0.5.n.n.n.1D \
    -b "$i"_RS.backdif2.avg.dvars.moderate5.n.n.n.1D \
    -expr 'or(a, b)' \
    > "$i"_powerCensorIntersection.1D

    ### Apply censor file in the final preprocessed image (after temporal filtering and spatial blurring)
    afni_restproc.py -apply_censor ${in[$i]} "$i"_powerCensorIntersection.1D ${out[$i]} &>> ${prefix[$i]}$i.log
  fi; close.node
  log "RS MOTIONCENSOR "
done 
input.error
echo

#: QC10 ========================================================================

fi

#: QC11 ========================================================================

#: DATA OUTPUT ===================================================================
for i in $ID; do
#rm -r OUTPUT/$i/manual_skullstrip 2> /dev/null
file=$(find . -name "bf*_RS_$i.nii")
cp -n $file OUTPUT/$i/
file=$(find . -name "cbf*_RS_$i.nii")
cp -n $file OUTPUT/$i/
file=$(find . -name "preproc_$i.log")
cp -n $file OUTPUT/$i/
file=$(find . -name "SS_T1_$i.nii")
cp -n $file OUTPUT/$i/
# incluir quality report aqui tbm
#file=$(find . -name "report_$i.html")
#cp -n $file OUTPUT/$i/
done





exit #=================================================================================
#======================================================================================
#======================================================================================
#======================================================================================
#======================================================================================
#======================================================================================
#======================================================================================


