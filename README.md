# RS-fMRI automated processing pipeline

This is the initial page of the repository of scripts for RS-fMRI automated preprocessing pipeline of the LIM 21. We designed scripts in BASH SHELL to run a preprocessing pipeline of functional Magnetic Ressonance Imaging (Resting State Modality) for adult humans and specialy for group analysis. 

This pipeline is still under development

## Required Software
  
- GNU Bash v3.7+ (http://www.gnu.org/software/bash/)
- AFNI v16.3.12 (https://afni.nimh.nih.gov/afni/)
- FSL v5.0 (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/)
- Python v2.7 (https://www.python.org/)
- ImageMagick  v7.0.4-3 (https://www.imagemagick.org/)
- Libav(avconv) v12 (https://libav.org/)
- Xvfb
- Matlab (https://www.mathworks.com/)  
    - SPM5 (http://wwww.fil.ion.ucl.ac.uk/spm/software/spm5/)  
    - aztec v2.0 (http://www.ni-utrecht.nl/downloads/aztec)  
   
## Usage
This repository of scripts can be downloaded via web interface on a zip file or can be obtained using the command "git clone" (example below). 
Also to run as an executable file, file permissions need to be changed. 
  
```bash
git clone https://lucmsanchez@gitlab.com/LIM21/RS-fMRI_PROC.git RS-fMRI_PROC # Your user password will be asked to access the repository
cd RS-fMRI_PROC
chmod a+x preproc.sh
chmod a+x -r /lib
```
The main script "preproc.sh" requires:
- All input files saved on local folder
- txt file with input files filenames, Subject ID and Visit ID (named preproc.sbj, example below)

preproc.sbj - File must be organizef in the following way:
Each row refers to one subject and one visit
All columns divided by ";"
1st Column - Subject ID (6 digits)
2nd Column - Visit ID (1 digit)
3rd Column - T1 filename
4th Column - RS filename
5th Column - Physlog File filename
6th Column - Skull Strip Mask filename

```
000917;1;rd3_CRACK_000917_1_1.nii;rd3_CRACK_000917_1_2.nii;rd3_CRACK_000917_1_2.log;mask_rd3_CRACK_000917_1_1.nii.gz
001543;1;rd3_CRACK_001543_1_1.nii;rd3_CRACK_001543_1_2.nii;rd3_CRACK_001543_1_2.log;mask_rd3_CRACK_001543_1_1.nii.gz

```

Also on the folder named Template, if no template were found by the script, save the template and the atlas for ROI parcellation on the folder. If you need a different template or atlas you can change the name variables "template" and "atlas" on the beginning of the script


```bash
./preproc.sh [ Options ] --subjects <sbj txt file>

opções:
-a or --start   # Specify an STEP to begin
-o or --stop    # Specify an STEP to end. It ends before running that step.
```

If there is a txt file named preproc.sbj on the same folder as the script you can run only:

```bash
./preproc.sh 
```

If you want to run only steps 3 to 5 and have a file named subjects.txt, you have to run:

```bash
./preproc.sh -a 3 -o 6 --subs subjects.txt
```

## Bugs and Limitations 
    
- Script doesn't check the required packages inside MATLAB. (Bug #8)
- Can't use automated skull-strip (Bug #9)

## TO DO    
    

  
## Shortcuts
  
- [Repository](https://gitlab.com/LIM21/RS-fMRI_PROC/tree/master)
- [Manual](https://gitlab.com/LIM21/RS-fMRI_PROC/wikis/home)
- [Bugs/Issues](https://gitlab.com/LIM21/RS-fMRI_PROC/issues)



## Pipeline Overview  
    
  
  
  
![Etapas do protocolo][chart]

[chart]: chart/flowchart.jpg "Etapas do protocolo"
