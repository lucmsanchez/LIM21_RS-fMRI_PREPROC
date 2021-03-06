# RS-fMRI automated Preprocessing pipeline v1.2

This is the initial page of the repository of scripts for RS-fMRI automated preprocessing pipeline of the LIM 21. We designed scripts in BASH SHELL to run a processing pipeline of functional Magnetic Ressonance Imaging (Resting State Modality) for adult humans and specialy for group analysis. 

## Required Software
  
- GNU Bash v3.7+ (http://www.gnu.org/software/bash/)
- AFNI v16.3.12 (https://afni.nimh.nih.gov/afni/)
- FSL v5.0 (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/)
- Python v2.7 (https://www.python.org/)
- ImageMagick  v7.0.4-3 (https://www.imagemagick.org/)
- Xvfb
- Matlab (https://www.mathworks.com/)  
    - SPM5 (http://wwww.fil.ion.ucl.ac.uk/spm/software/spm5/)  
    - aztec v2.0 (http://www.ni-utrecht.nl/downloads/aztec)  
   
## Usage
This repository of scripts can be downloaded via web interface on a zip file or can be obtained using the command "git clone" (example below). 
Also to run as an executable file, file permissions need to be changed. 
  
```bash
git clone https://lucmsanchez@gitlab.com/LIM21/RS-fMRI_PREPROC.git RS-fMRI_PROC # Your user password will be asked to access the repository
cd RS-fMRI_PREPROC
chmod a+x run_all.sh
chmod a+x -r /lib
```
The main script "run_all.sh" requires:
- All input files saved inside local folder (T1, RS and Physlog)
- txt file with input files filenames ans Subject ID (named subjects.csv, see example below)

subjects.csv - File must be organized in the following way:  
Each row must refers to one subject and one visit only  
All columns must be divided by ";"  
1st Column - Subject ID  
2nd Column - T1 filename  
3rd Column - RS filename  
4th Column - Physlog File filename  


```
P000917;1;rd3_CRACK_000917_1_1.nii;rd3_CRACK_000917_1_2.nii;rd3_CRACK_000917_1_2.log
P001543;1;rd3_CRACK_001543_1_1.nii;rd3_CRACK_001543_1_2.nii;rd3_CRACK_001543_1_2.log

```

Also on the folder named Template, if no template were found by the script, save the template and the atlas for ROI parcellation on the folder. If you need a different template or atlas you can change the name variables "template" and "atlas" on the beginning of the scripts.


```bash
./run_all.sh --subjects subjects.csv

Options:
--parallel n   # Run n subjects in the background in parallel
--no_aztec  # Run without the aztec step
```

If there is a txt file named subjects.csv on the same folder as the script you can run only:

```bash
./run_all.sh 
```

## Bugs and Limitations 
    
- Script doesn't check the required packages inside MATLAB. (Bug #8)
- Can't use automated skull-strip (Bug #9)

## TO DO    
    

  
## Shortcuts
  
- [Repository](https://gitlab.com/LIM21/RS-fMRI_PREPROC/tree/master)
- [Manual](https://gitlab.com/LIM21/RS-fMRI_PREPROC/wikis/home)
- [Bugs/Issues](https://gitlab.com/LIM21/RS-fMRI_PREPROC/issues)



## Pipeline Overview  
    
  
  
  
![Etapas do protocolo][chart]

[chart]: chart/flowchart.jpg "Etapas do protocolo"
