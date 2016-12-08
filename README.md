# Protocolo automatizado de Pré-processamento de RS-fMRI

Essa é a pagina inicial do repositório de scripts do protocolo Pré-processamento de RS-fMRI do LIM 21. Esse repositório contém scripts escritos em BASH para serem rodados em LINUX (escritos no NeuroDebian 8.0.0), que tem por objetivo rodar um protocolo semi-automatizado de pré-processamento de imagens de Ressonância Magnética Funcional Cerebral, modalidade Resting-state, de humanos adultos. 

Esse protocolo ainda está em desenvolvimento.

## Arquivo principal: [preproc.sh](preproc.sh)

## Pré-requisitos

- GNU Bash v4.4 (http://www.gnu.org/software/bash/)
- AFNI v16.3.12 (https://afni.nimh.nih.gov/afni/)
- FSL v5.0 (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/)
- R v3.3.2 (https://www.r-project.org/)
- Matlab (https://www.mathworks.com/)  
    - SPM5 (http://wwww.fil.ion.ucl.ac.uk/spm/software/spm5/)  
    - aztec v2.0 (http://www.ni-utrecht.nl/downloads/aztec)  

## Uso

Abaixo exemplo de como rodar o script. Ele usa a pasta onde é rodado como base para a análise. É necessário especificar o arquivo de configurações e o arquivo com o ID dos indivíduos. Caso o arquivo de configuração não seja especificado na primeira vez que rodar o script irá criar um com valores default.

```bash
./preproc.sh --config preproc.cfg --subs preproc.sbj 
```
Caso tenha algum problema e queira fazer Debug execute como especificado abaixo e envie o log para nós:

```bash
bash -vxn ./preproc.sh --config preproc.cfg --subs preproc.sbj &> log
```

## Limitações

- Script não checa atualizações nas variáveis definidas nas configurações. Caso mude uma das configurações deve-se apagar o output da etapa a que a configuração se refere.
- Opção e etapa aztec não funciona. 1o) qual dos arquivos de log deve-se usar? 2o) Mesmo com o exemplo fornecido usado o GUI há erro. Incompatibilidade com a versão do matlab? 3o) Na tentativa de usar a função sem GUI é necessário especificar a variável highpass, que não é usado no GUI - como é possivel? que valores usar?
 

## Atalhos

- [Repositório](https://gitlab.com/LIM21/RS-fMRI_PREPROC/tree/master)
- [Manual de uso (Wiki)](https://gitlab.com/LIM21/RS-fMRI_PREPROC/wikis/home)
- [Bugs/Issues](https://gitlab.com/LIM21/RS-fMRI_PREPROC/issues)

## Visão Geral do protocolo  
  
  
  
  
![Etapas do protocolo][chart]

[chart]: images/flowchart.jpg "Etapas do protocolo"
