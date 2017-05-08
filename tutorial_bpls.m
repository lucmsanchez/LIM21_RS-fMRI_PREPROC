%I prefer to use the Command Line option because it allows me to include PLS in Matlab scripts and they are more versatile.
%When you download PLS, you will find a Matlab .m file “pls_analysis.m” (inside the folder plscmd). This file (“pls_analysis.m”) is a Matlab function. To understand how it works, open Matlab, go inside the folder where the “pls_analysis.m” file is saved, type
%help pls_analysis
%and press enter (return).
%The command help will display the help-related content of the function “pls_analysis.m”.
%You will notice that the basic usage is:
%result = pls_analysis(datamat_lst, num_subj_lst, num_cond, option);
%Let’s start with a very simple example.
%Say you want to characterize the relationship between cognitive performance and brain functional connectivity.
%You have already estimated functional connectivity in the Example-Tutorial about Resting State Functional Connectivity. Is that example you estimated the whole-brain functional connectivity of 97 subjects. To do this, the brain was parcellated in 116 regions (AAL atlas) and, for each subject you estimated the connectivity between all possible pairs of regions (6670 connections). You finally built a 97 x 6670 matrix (97 subjects, one subject per line; 6670 connections, one connections per column). This matrix was stored in the variable clean_functional_connectivity. This is going to be our “brain dataset” to perform a PLS analysis.
%To make things easier I have saved the matrix clean_functional_connectivity inside this folder here. Just download it and save in your computer. Then, load it in Matlab:
%load '/WHERE_YOU_SAVED_THE_FILE/clean_functional_connectivity.mat'
%And now, we need cognitive performance data.
%Let’s use the following (artificially created) data regarding memory performance of the 97 participants.:
memory_performance = [16 25 23 21 23 21 17 15 15 16 13 19 18 14 18 21 12 23 14 27 19 15 12 16 18 20 20 14 13 17 20 18 13 24 12 22 14 21 19 19 26 25 19 19 19 25 18 22 26 23 15 22 14 26 13 13 15 13 13 18 19 14 21 21 21 21 19 12 21 19 19 11 14 20 18 18 14 15 20 12 15 11 20 17 23 17 19 22 19 12 18 17 22 17 23 18 17];
memory_performance = memory_performance'; % transpose so that each line is a participant

%Let’s use PLS to check if there is a relationship between memory performance and brain connectivity:
%Firstly, download PLS to your computer (https://www.rotman-baycrest.on.ca/index.php?section=84). Save it somewhere you remember.
%Now, use it on Matlab:
%% add PLS to your path
addpath /Users/luiz/THIS_IS_WHERE_I_SAVED_PLS/Pls/plscmd % You need to modify this! Include here the specific path to the command line PLS folder ([YOUR_PATH]/Pls/plscmd)
%% determine the number of permutations and bootstraps:
num_permutations = 1000;
num_bootstraps = 1000;
% clear key variables
clear braindata;
clear behavdata1;
clear datamat;
clear res
%% input data
braindata = clean_functional_connectivity;
behavdata1 = memory_performance;
datamat{1} = braindata; % cell format
datamat_lst = datamat;
num_subj_lst = size(clean_functional_connectivity,1);
%% PLS options (read help pls_analysis for more info)
num_cond = 1;
option.method = 3;
option.num_perm = num_permutations;
option.num_boot = num_bootstraps;
option.num_split = 0;
option.stacked_behavdata = behavdata1;
option.meancentering_type = 0;
%% run PLS
res = pls_analysis(datamat_lst, num_subj_lst, num_cond, option);

%Now, let’s understand the results.
%The variable res now contains all results from the PLS analysis.
%By using the command whos 
whos res
%you can see that the variable res is a “structure”. A structure is a type of Matlab variable that can contain multiple types of information. Structures are organized in “fields” (and each field can contain any type of data).
%If you type res and press return (or enter) you will see that the variable res contains many fields (method, is_struct, datamatcorrs_lst, etc).
%The field field_descrip includes the information about how to understand these fields (meta-information). To see what is inside this field, type:
res.field_descrip
%This information will help you understand what each field contains and where to find the data you need.

%For instance, let’s check the result from the permutation procedure. By reading the information on res.field_descrip we know that the field perm_result contains the information about the permutation procedure. We also know that this field contains subfields. Check what is inside the field res.perm_result
%You will see that it shows the number of permutations executed (field num_perm), the number of times that the singular values calculated after permutation exceeded the singular value calculated originally, i.e without permutation (field sp). And there is also a subfield containing the “p-value”, i.e. the probability that permuted singular values are greater than the original (non-permuted) singular value (field sprob).
%This p-value may differ slightly from one analysis to another (due to the random permutation procedures) but you very probably will get a value around 0.003 ~ 0.01.
%Okay, so we know that the result is statistically significant.

%Now, let’s check the result from the bootstrap procedure.
%Firstly, the confidence interval of the brain-behavior correlation
%This information is stored in the field boot_result, subfields ulcorr and llcorr:
%% check the bootstrap result:
ul = res.boot_result.ulcorr;
ll = res.boot_result.llcorr;
fprintf('Confidence interval \n of the correlation between clinical variable and brain score: \n')
fprintf([ num2str(ll) ' ~ ' num2str(ul) '\n \n \n']);
%Okay, the confidence interval is far from ‘0’ so now we know that the brain-behavior correlation is reliable and stable across the multiple bootstrap samples.

%We also need to check the bootstrap ratio of brain saliences.
%This information is stored in the field boot_result, subfield compare_u:
%% get this information and store in one variable
btr = res.boot_result.compare_u;
%% rebuild square matrix to display results
num_roi = 116; % we used 116 regions of interest (AAL atlas)
btr_square_matrix = NaN(num_roi, num_roi); % container
%% to rebuild the square matrix you need to remember how you extract non-redundant data from the original square matrix so that they match.
%% build lower triangle of the square matrix
counter = 1; % reset counter
for c = 1:(num_roi-1); % start on column 1, end in the penultimate column
    for l = (c+1):num_roi; % start on line 2, end in the last line
        btr_square_matrix(l,c) = btr(counter);
        counter = counter+1;
    end
end
%%now, the same thing to the upper triangle (mirrors the lower triangle)
counter = 1;
for l = 1:(num_roi-1); % start on line 1, end in the penultimate line
    for c = (l+1):num_roi; % start on column 2, end in the last column
        btr_square_matrix(l,c) = btr(counter);
        counter = counter+1;
    end
end
%% threshold for absolute bootstrap ratios > 3
abs_btr_square_matrix = abs(btr_square_matrix); % get absolute values
binary_btr_square_matrix = abs_btr_square_matrix>3; % binarize (threshold = 3)
thr_btr_square_matrix = btr_square_matrix;
thr_btr_square_matrix(binary_btr_square_matrix == 0) = 0; % set to 0 all values not reaching the threshold
%% display 
figure;
imagesc(thr_btr_square_matrix);
axis square;
colorbar;
%This figure is much more interesting with the AAL anatomical labels. Since we used the exact same order as in the Sample RSFC tutorial, you can also use that anatomical labeling procedure here! Give it a try!

%Where the connections are located?
%Okay, now say you want to check where the connections are anatomically located.
%Remember that we used the AAL atlas to parcelate the brain so that each region has its own anatomical label. We also took great care to keep the regions in the same order as described by the AAL label description.
%First, you need to load the AAL anatomical labels. If you don’t remember how to do it, you can check the tutorial “Sample RSFC’, section “Perhaps you want to add the AAL anatomical labels”. As described there, load the anatomical labels into a variable (we are using here the same variable as before: AAL_long_labels).
%Now we can display the btr_square_matrix with the anatomical labels:
figure;
imagesc(thr_btr_square_matrix);
axis square;
colorbar;
set(gca,'XTick',[1:numel(AAL_long_labels)]);
set(gca,'XTickLabel',AAL_long_labels);
set(gca,'YTick',[1:numel(AAL_long_labels)]);
set(gca,'YTickLabel',AAL_long_labels);
%This is what I got (remember that you results may be slightly different):

%Alternatively, you can also use the command line to find the anatomical labels of the connections presenting absolute bootstrap ratio > 3:
%% we know that thr_btr_square_matrix:
%% -> contains “zero” where the |bootstrap ratio| < 3
%% -> contains the bootstrap ratio value when |bootstrap ratio| > 3
[btr_rows btr_columns] = find(thr_btr_square_matrix); % identify the rows and the columns containing values different from zero.
btr_anat_labels = cell(numel(btr_rows),2); % container for the anatomical labels
for n = 1:numel(btr_rows); % loop through pairs of regions
    btr_anat_labels(n,1) = AAL_long_labels(btr_rows(n));
    btr_anat_labels(n,2) = AAL_long_labels(btr_columns(n));
end
btr_anat_labels % display
%Okay! Now we have the variable which contains all pairs of connections presenting |bootstrap ratio| > 3, labeled with the AAL anatomical label!
%(just remember that these connections were identified using the thr_btr_square_matrix, which is a square matrix containing duplicate data; thus, the btr_anat_labels matrix also contains duplicate connections).


%The direction of association
%You will notice that some bootstrap ratio values are positive and others are negative. This is because some connections present a positive correlation with memory and others a negative correlation. You need to look at two pieces of information to interpret this correctly:
%1) the signal of the brain-behavior correlation
%2) the signal of the bootstrap ratios
%If the signal of the brain-behavior correlation is positive, then, a positive bootstrap ration means that this connection is positively associated with memory and a negative bootstrap ration means that the connection is negatively associated with memory.
%If the signal of the brain-behavior correlation is negative it is the inverse: a positive bootstrap ration means that this connection is negatively associated with memory and a negative bootstrap ration means that the connection is positively associated with memory.


%Let’s work with more than one behavioral variable!
%We worked with just one behavioral variable. But in general you have more than one. Say we have three tests: memory (the same as above), attention and executive functions.
attention_performance = [47 13 19 39 18 28 65 73 78 63 75 41 61 81 68 36 66 23 49 10 75 65 84 53 71 22 33 52 53 49 68 58 85 26 60 70 83 25 39 48 41 42 45 24 73 49 60 44 0 57 78 66 80 42 66 67 73 66 86 33 65 49 29 66 49 69 38 85 44 42 63 83 77 40 44 56 59 44 46 75 62 90 29 71 51 60 68 22 30 66 76 65 11 79 24 64 39];
attention_performance = attention_performance';
executive_performance = [79 47 74 134 151 83 129 29 151 109 73 104 69 132 163 67 45 93 142 167 45 30 179 125 107 80 26 62 145 92 49 37 122 153 134 103 100 99 130 69 30 172 60 32 37 201 157 111 46 114 119 96 80 15 54 6 120 96 110 151 116 84 50 66 84 184 6 54 97 12 50 112 154 45 111 177 171 163 91 3 73 148 93 136 115 53 112 76 112 66 143 83 54 42 122 113 137];
executive_performance = executive_performance';
%First, let’s concatenate all three behavioral variables in one matrix:
memory_attention_executive = [memory_performance attention_performance executive_performance];
%Now, use PLS to characterize the relationships between this set of behavioral variables and brain connectivity:
%% clear key variables
clear braindata;
clear behavdata1;
clear datamat;
clear res
%% input data
braindata = clean_functional_connectivity;
behavdata1 = memory_attention_executive;
datamat{1} = braindata; % cell format
datamat_lst = datamat;
num_subj_lst = size(clean_functional_connectivity,1);
%% PLS options (read help pls_analysis for more info)
num_cond = 1;
option.method = 3;
option.num_perm = num_permutations;
option.num_boot = num_bootstraps;
option.num_split = 0;
option.stacked_behavdata = behavdata1;
option.meancentering_type = 0;
%% run PLS
res = pls_analysis(datamat_lst, num_subj_lst, num_cond, option);

%Check the result from the permutation procedure
res.perm_result.sprob
%In my case this yielded (your results are probably going to be similar but not equal to mine):
0.0040
0
0.7802
%We have three sets of latent variables and, for each set, we get a p-value. In this case, the first two are significant (0.004 and <0.001) but the third is not (0.78).
%Thus, we are going to proceed with the first two sets of latent variables and ignore the third.

%Check the confidence interval of the brain-behavior correlation
ul = res.boot_result.ulcorr; % get upper values
ll = res.boot_result.llcorr; % get lower values
behavioral_labels = {'memory' 'attention' 'executive'};
%% first latent variable:
lv = 1;
fprintf(['Latent variable n.' num2str(lv) '\n']);
fprintf('Confidence interval \n of the correlation between clinical variables and brain score: \n')
for b = 1:numel(behavioral_labels); % loop through each behavioral variable
fprintf([ behavioral_labels{b} ': ' num2str(ll(b,lv)) ' ~ ' num2str(ul(b,lv)) '\n']);
end
fprintf('\n \n \n'); 
%This yielded the following to me:
%Latent variable n.1
%Confidence interval 
% of the correlation between clinical variables and brain score: 
%memory: -0.88267 ~ -0.77885
%attention: 0.76808 ~ 0.88448
%executive: -0.13793 ~ 0.36634
%This means that, for the first latent variable, the reliable associations were between the connectivity pattern and memory; and between connectivity and attention. But not between connectivity and executive function (the confidence interval includes zero).
%Note also that the signal of the correlation between memory and connectivity is negative while it is positive between attention and connectivity. This is important when interpreting the boostrap ratio results (see above section “The direction of association”)
%Now, let’s move to the second latent variable:
%% second latent variable:
lv = 2;
fprintf(['Latent variable n.' num2str(lv) '\n']);
fprintf('Confidence interval \n of the correlation between clinical variables and brain score: \n')
for b = 1:numel(behavioral_labels); % loop through each behavioral variable
fprintf([ behavioral_labels{b} ': ' num2str(ll(b,lv)) ' ~ ' num2str(ul(b,lv)) '\n']);
end
fprintf('\n \n \n');
%In my case, this gave:
%Latent variable n.2
%Confidence interval 
% of the correlation between clinical variables and brain score: 
%memory: -0.38598 ~ 0.14535
%attention: -0.20778 ~ 0.24945
%executive: -0.93432 ~ -0.84984
%So, for the second latent variable the association between connectivity and memory and connectivity and attention were not reliable (confidence intervals include zero). But the association between executive function and connectivity was reliable.

%Therefore, we see now that PLS characterized two significant sets of latent variables that describe relationships between the behavioral and brain variables. The first one captured changes in connectivity that are associated with better attention and worse memory performance. While the second latent variable found a pattern of connectivity associated with executive function.
%Let’s now have a look at these connectivity patterns.

%Check the bootstrap ratio of brain saliences
%This procedure is very similar to the one we have performed when we had just one behavioral variable but now we need to understand that we have 3 behavioral variables and 3 latent variables.
%% bootstrap ratios
%% get this information and store in one variable
btr = res.boot_result.compare_u;
btr_square_matrix = NaN(num_roi, num_roi,size(btr,2)); % container for all latent variables
%% build lower triangle of the square matrix
for a = 1:size(btr,2); % loop through each latent variable
    counter = 1; % reset counter
    for c = 1:(num_roi-1); % start on column 1, end in the penultimate column
        for l = (c+1):num_roi; % start on line 2, end in the last line
            btr_square_matrix(l,c,a) = btr(counter,a);
            counter = counter+1;
        end
    end
end
%%now, the same thing to the upper triangle (mirrors the lower triangle)
for a = 1:size(btr,2); % loop through each latent variable
    counter = 1;
    for l = 1:(num_roi-1); % start on line 1, end in the penultimate line
        for c = (l+1):num_roi; % start on column 2, end in the last column
            btr_square_matrix(l,c,a) = btr(counter,a);
            counter = counter+1;
        end
    end
end

%% threshold for absolute bootstrap ratios > 3
abs_btr_square_matrix = abs(btr_square_matrix); % get absolute values
binary_btr_square_matrix = abs_btr_square_matrix>3; % binarize (threshold = 3)
thr_btr_square_matrix = btr_square_matrix;
thr_btr_square_matrix(binary_btr_square_matrix == 0) = 0; % set to 0 all values not reaching the threshold

%% display
%% first latent variable
lv = 1;
figure;
imagesc(thr_btr_square_matrix(:,:,lv));
axis square;
colorbar;
title(['Thresholded bootstrap ratios, Latent Variable n.' num2str(lv)]);
%% second latent variable
lv = 2;
figure;
imagesc(thr_btr_square_matrix(:,:,lv));
axis square;
colorbar;
title(['Thresholded bootstrap ratios, Latent Variable n.' num2str(lv)]);
%This gave me two figures.
%This is the thresholded bootstrap ratio figure for the First Latent Variable:

%Remember that for this First Latent Variable I had: 1) a negative correlation between brain scores and memory performance and 2) a positive correlation between brain scores and attention. This set of brain connections present both negative (blue dots) and positive saliences (red dots). This all means that there is a significant pattern of increases (red dots) and decreases (blue dots) in brain connectivity that is associated with a better attention and worse memory.

%For the second latent variable we found that executive function was negatively associated with this pattern of brain connectivity. This means that this set of brain connectivity changes are negatively associated with executive functions. In other words, the red dots are associated with worse executive function and the blue dots with better performance.

%Oh, and to improve the interpretability of these findings it is useful to include the AAL anatomical labels. We have covered that on the Sample RSFC tutorial - check it out and make your graphs better than the ones here! This will enable you to characterize where the connections are located in the brain.

%A final note about correlations of correlations
%When studying the correlation of a clinical variable with functional connectivity one must remember that functional connectivity was estimated using a correlation. In other words, we are performing a correlation of correlations.
%Thus, extra care should be taken when describing results of correlations between functional connectivity and other variables. For example, a positive correlation between age and functional connectivity may mean that greater age is associated with: 1) an increase in magnitude of positive correlation of the neural activity of brain regions studied, 2) a decrease in the magnitude of negative correlation or 3) a transformation of anticorrelation to a positive correlation. The interpretation of increases in magnitude of positive correlations can be different from that relating to a loss of anticorrelation.

