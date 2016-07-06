#!/usr/bin/env bash

# Debug options ================================================================
# export PS4='(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]} - [${SHLVL},${BASH_SUBSHELL}, $?]
# export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
# set -x
# trap 'echo Variable Listing --- a = $a  b = $b' EXIT
# trap 'echo "VARIABLE-TRACE> \$variable = \"$variable\""' DEBUG
# ==============================================================================

# DECLARANDO VARIÁVEIS =========================================================
ptn=seq+z
#
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
  while true; do
  if [ ! -d $outpath ]; then
    mkdir $outpath
  fi
  if [ -e $inpath$in ]; then
    if [ ! -e $outpath$out1 ] || [ ! -e $outpath$out2 ]; then
      cd $inpath
      $1 &> $prefix$i.log \
        && printf "Processamento da imagem %s realizado com sucesso!\n" "$i" \
        || printf "Houve um erro no processamento da imagem %s, consulte o log %s\n" "$i" "$prefix$i.log" | fold -s
      cd $pwd
      mv $inpath$prefix* $outpath
      break
    else
      if [ $outpath$out1 -ot $inpath$in ] || [ $outpath$out2 -ot $inpath$in ]; then
        printf "INPUT MODIFICADO. REFAZENDO ANÁLISE DA IMAGEM\n         "
        rm $outpath$out1
        rm $outpath$out2
      else
      echo JÁ EXISTE O OUTPUT $out1 $out2; break
      fi
    fi
  else
  echo NÃO ENCONTRADO O INPUT $in; break
  fi
done
}
# ==============================================================================


# INÍCIO =======================================================================

fold -s <<-EOF

Protocolo de pré-processamento de fMRI
--------------------------------------
Autor: Luis Kobuti Ferreira <emaildoluis@gmail.com>

Checando se todos os programas necessários estão instalados e estão disponíveis na variável de ambiente \$PATH

GNU bash, version                         ...$(check bash)
AFNI                                      ...$(check afni)
FSL                                       ...$(check fsl5.0-fast)
EOF

if (command -v bash && command -v afni && command -v fsl5.0-fast) > /dev/null ; then
	printf "\nTodos os prorgamas necessários estão instalados, prosseguindo...\n\n"
else
	printf "\nUm ou mais programas necessários para o pré-processamento não estão instalados (acima). Por favor instale o(s) programa(s) faltante(s) ou então verifique se estão configurados na variável de ambiente \$PATH\n\n" | fold -s
	exit
fi

# Checando diretórios em busca das imagens
fold -s <<-EOF
Esse pipeline usa o diretório atual ($PWD) como diretório base para o processamento. Irá reconhecer apenas imagens no formato NIFTI que estejam dentro da pasta atual e irá movê-las para a pasta DATA, contanto que respeitem a regra de denominação abaixo:

  RS_<ID>.nii - para a imagem de Resting State
  T1_<ID>.nii - para a imagem T1 estrutural
  ID - código idenificador uníco do indivíduo

  Exemplo da estrutura básica:
  DATA/<ID>/RS_<ID>.nii
  DATA/<ID>/T1_<ID>.nii

  .
  ├── DATA
  │   ├── T000328
  │   │   ├── RS_T000328.nii
  │   │   └── T1_T000328.nii
  │   └── T000329
  │       ├── RS_T000329.nii
  │       └── T1_T000329.nii
  ├── OUTPUT
  │   ├── T000328
  │   └── T000329
  ├── WORK
  │   ├── T000328
  │   └── T000329
  ├── manual.md
  ├── preproc.graphml
  └── preproc.sh
EOF

# Procurar imagens na pasta atual
printf "\nBuscando no diretório atual as imagens:\n\n"
if [[ ! -z $(find . -name "T1_*.nii") && ! -z $(find . -name "RS_*.nii") ]]; then
	printf "\nForam encontradas as imagens T1 abaixo:\n"
	find . -name "T1_*.nii"
  echo -n "Total: " ; find . -name "T1_*.nii" | wc -l
	printf "\nForam encontradas as imagens RS abaixo:\n"
  find . -name "RS_*.nii"
  echo -n "Total: " ; find . -name "RS_*.nii" | wc -l
	else
	printf "\nNão foram encontradas imagens no formato T1_<ID>.nii E RS_<ID>.nii. Adicione ou renomeie as imagens de acordo com o padronizado pelo pipeline.\n" | fold -s
	exit
fi

# Perguntar se deseja prosseguir
c=0
until [ $c -eq 1 ]; do
  echo
	read -p "Deseja prosseguir com o processamento dessas imagens? [S/N]"
	case $REPLY in
		S|s ) printf "\nProsseguindo...\n"; c=1;;
		N|n ) printf "\nAbortando script...\n"; exit; c=1;;
		* ) printf "\nResponda apenas com S ou N\n";;
	esac
done

# Estruturar corretamente as imagens
printf "\nEstruturando as imagens encontradas de acordo com o padrão descrito acima...\n\n"
ID=$(find . -name "T1_*.nii" -type f -printf "%f\n" | cut -d "_" -f 2 | cut -d "." -f 1)
for i in $ID; do
  wfp_T1=$(find . -name "T1_$i.nii")
	wfp_RS=$(find . -name "RS_$i.nii")
	rfp_T1=DATA/$i/T1_$i.nii
	rfp_RS=DATA/$i/RS_$i.nii
	for f in DATA WORK OUTPUT; do
		if [ ! -d $f/$i ]; then
		    mkdir -p $f/$i
	 	fi
	done
	mv $wfp_T1 $rfp_T1 2> /dev/null
	mv $wfp_RS $rfp_RS 2> /dev/null
done

# SLICE TIMING CORRECTION=======================================================
printf "================INCIANDO A ETAPA SLICE TIMING CORRECTION================\n\n"
pwd=($PWD)
for i in $ID; do
  prefix=t_RS_
  in=RS_$i.nii
  out1=t_RS_$i+orig.HEAD
  out2=t_RS_$i+orig.BRIK
  inpath=DATA/$i/
  outpath=WORK/$i/slice_correction/
  echo -n "$i> "
  node "3dTshift \
    -verbose \
    -tpattern $ptn \
    -prefix $prefix$i \
    -Fourier \
    $in"
done
exit
# MOTION CORRECTION============================================================
printf "================INCIANDO A ETAPA MOTION CORRECTION================\n\n"
pwd=($PWD)
for i in $ID; do
  prefix=rt_RS_
  in=$out2
  out1=rt_RS_$i+orig.HEAD
  out2=rt_RS_$i+orig.BRIK
  inpath=$outpath
  outpath=WORK/$i/motion_correction/
  echo -n "$i> "
  node "dvolreg \
  -prefix rt_RS_"$i" \
  -base "$vr" \
  -zpad 2 \
  -twopass \
  -Fourier \
  -1Dfile motioncorrection_"$i".1d \
  t_RS_"$i"+orig
done
