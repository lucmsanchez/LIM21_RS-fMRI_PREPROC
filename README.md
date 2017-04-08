# Protocolo Semi-automatizado de pré-processamento de RS-fMRI  
  
Essa é a pagina inicial do repositório de scripts do protocolo Pré-processamento de RS-fMRI do LIM 21. Esse repositório contém scripts escritos em BASH para serem rodados em LINUX (escritos no NeuroDebian 8.0.0), que tem por objetivo rodar um protocolo semi-automatizado de pré-processamento de imagens de Ressonância Magnética Funcional Cerebral, modalidade Resting-state, de humanos adultos. 

Esse protocolo ainda está em desenvolvimento.

## Arquivos principais: [preproc.sh](preproc.sh), [preproc.cfg](preproc.cfg) e [preproc.sbj](preproc.sbj)

## Pré-requisitos  
  
- GNU Bash v3.7+ (http://www.gnu.org/software/bash/)
- AFNI v16.3.12 (https://afni.nimh.nih.gov/afni/)
- FSL v5.0 (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/)
- Python v2.7 (https://www.python.org/)
- ImageMagick  v7.0.4-3 (https://www.imagemagick.org/)
- Libav(avconv) v12 (https://libav.org/)
- Xvfb
- Perl
- Sed
- Matlab (https://www.mathworks.com/)  
    - SPM5 (http://wwww.fil.ion.ucl.ac.uk/spm/software/spm5/)  
    - aztec v2.0 (http://www.ni-utrecht.nl/downloads/aztec)  
   
## Uso  
Em primeiro lugar, crie uma nova pasta em que ocorrerá toda a análise dos dados. Em seguida, baixe o repositório ou apenas os arquivos indicados acima como principais e salve na pasta criada. Altere as permissões do arquivo preproc.sh para executável:
  
```bash
mkdir PREPROC 
cd PREPROC
# Faça o download do repositório no formato .zip para a pasta recém criada PREPROC
gzip -d <nome do arquivo baixado>
sudo chmod a+x preproc.sh
```
Faça alterações ou crie os aquivos preproc.cfg e preproc.sbj (pode usar outros nomes, apenas mantenha a extensão) conforme sua necessidade. Exemplos de default abaixo:  
  
preproc.cfg
```
# Variáveis RS-fMRI Preprocessing:
fsl5=fsl5.0-
TR=2
ptn=seq+z
mcbase=100
gRL=90
gAP=90
gIS=60
template="MNI152_1mm_uni+tlrc"
betf=0.1
blur=6
cost="lpc"
```
  
preproc.sbj (o arquivo deve conter APENAS os códigos das imagens, um por linha)
```
C000001
C000002
C000003
P000001
P000002
P000003
```
Salve as imagens que serão pré-processadas na pasta base (PREPROC) confome o padrão:
```
RS.C000001.nii  # imagem Funcional
T1.C000001.nii  # imagem estrutural
RS.C000001.log  # physlog para análise aztec
```
Salve também o template na pasta principal. Caso não seja encontrado o script irá buscar o template especificado na pasta do AFNI e copiar para a pasta base

Os arquivos serão automaticamente organizados no seguinte padrão:  
  
```
.
├── DATA
│   └── C000001
│   	├── /preproc.results
│   	├── RS.C000001.nii
│   	├── T1.C000001.nii
│   	└── RS.C000001.log
├── OUTPUT
│   └── C000001
│   	├── /media.report
│       ├── report.C000001.html
│       ├── preproc.RS.C000001.nii
│       ├── SS.T1.C000001.nii
│       └── preproc.C000001.log
├── template
│   ├── MNI152_1mm_uni+tlrc.BRIK
│   └── MNI152_1mm_uni+tlrc.HEAD
├── preproc.cfg
├── preproc.sbj
└── preproc.sh
```

Abaixo instruções de como rodar o script. Ele usa a pasta onde é rodado como base para a análise. É necessário especificar o arquivo de configurações e o arquivo com o ID dos indivíduos. Caso o arquivo de configuração não seja especificado na primeira vez que rodar o script irá criar um com valores default.

```bash
./preproc.sh [ Opções ] --config <txt com variáveis para análise>  --subjects <ID das imagens>

opções:
-b | --break n interrompe o script no breakpoint de numero indicado
--aztec            realiza a etapa aztec
--bet              realiza o skull strip automatizado (Padrão: Manual)
--motioncensor_no  NÃO aplica a técnica motion censor  
```

Por exemplo, se preciso rodar a análise COM skulstrip automatizado, COM motion censor e SEM aztec e preciso interomper o script antes de aplicar a mascara do skullstrip (breakpoint numero 2) para realização de ajustes devo usar o seguinte comando:
```bash
./preproc.sh --config preproc.cfg --subs preproc.sbj --break 2 --bet
```

Caso tenha algum problema e queira fazer o Debug, execute como especificado abaixo e crie um novo item na aba Issues anexe o log:

```bash
bash -vx ./preproc.sh --config preproc.cfg --subs preproc.sbj &> log
```

## Limitações e bugs (Ordem de prioridade)  
    
- Script não checa a versão do bash - necessita de 3.7+ para rodar (Bug #10)
- Script não checa os pré-requisitos dentro do matlab - SPM e aztec. (Bug #8)
- Script não checa atualizações nas variáveis definidas nas configurações. Caso mude uma das configurações deve-se apagar o output da etapa a que a configuração se refere. (Bug #6)
- Skull strip automatizado tem resultados ruins após o co-registro com fMRI (Bug #9)

## TO DO (Ordem de prioridade)   
    
- Agrupar CQ dos individúos por etapa
- Separar controle de qualidade de aquisição X CQ de processamento  
- Implementar medidas de controle de qualidade quantitativas (SNR e DVARS?)
- melhorar funções open.node e close.node (variaveis externas + loop)
- Melhorar etapas de alinhamento (epi2anat?)
- Melhorar etapa de normalização
- Concatenar warps
- Fazer regressões com 3dTproject
  
## Atalhos  
  
- [Repositório](https://gitlab.com/LIM21/RS-fMRI_PREPROC/tree/master)
- [Manual de uso (Wiki)](https://gitlab.com/LIM21/RS-fMRI_PREPROC/wikis/home)
- [Bugs/Issues](https://gitlab.com/LIM21/RS-fMRI_PREPROC/issues)

## Visão Geral do protocolo    
    
  
  
  
![Etapas do protocolo][chart]

[chart]: chart/flowchart.jpg "Etapas do protocolo"
