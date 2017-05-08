%At this moment you are probably familiar with Matlab. Thus, as an exercise, I will write down a sample Matlab script here explaining how to estimate functional connectivity when you already have extracted the time series. My hope is that it should be self-explaining. My suggestion is to copy and paste it on Matlab editor so that the automatic colors help your reading.
%You can test this script using an artificial dataset of time series from 97 hypothetical subjects. This dataset can be found in the same folder as this tutorial (Time_series_97subjects_116regions.zip). In this zipped file there are 97 files. Each file contains data from one subject. Each file contains 116 columns and 200 lines. Each column represent one brain region and each line represent one time point. Just download this dataset and unzip it. Check where you saved the files and modify the following line of the script
%Ok, now, let’s calculate the functional connectivity from all these 97 subjects. Use the script below:

% this script estimates functional connectivity

% set path to the folder where the data is stored and where it will be saved
path_data = '/Users/luiz/Desktop/caixa_de_areia/'; % you need to modify this!

% set number of regions of interest
num_roi = 116;

% set list of the files
list_of_files = {'time_series_Subj001.txt' 'time_series_Subj002.txt' 'time_series_Subj003.txt' 'time_series_Subj004.txt' 'time_series_Subj005.txt' 'time_series_Subj006.txt' 'time_series_Subj007.txt' 'time_series_Subj008.txt' 'time_series_Subj009.txt' 'time_series_Subj010.txt' 'time_series_Subj011.txt' 'time_series_Subj012.txt' 'time_series_Subj013.txt' 'time_series_Subj014.txt' 'time_series_Subj015.txt' 'time_series_Subj016.txt' 'time_series_Subj017.txt' 'time_series_Subj018.txt' 'time_series_Subj019.txt' 'time_series_Subj020.txt' 'time_series_Subj021.txt' 'time_series_Subj022.txt' 'time_series_Subj023.txt' 'time_series_Subj024.txt' 'time_series_Subj025.txt' 'time_series_Subj026.txt' 'time_series_Subj027.txt' 'time_series_Subj028.txt' 'time_series_Subj029.txt' 'time_series_Subj030.txt' 'time_series_Subj031.txt' 'time_series_Subj032.txt' 'time_series_Subj033.txt' 'time_series_Subj034.txt' 'time_series_Subj035.txt' 'time_series_Subj036.txt' 'time_series_Subj037.txt' 'time_series_Subj038.txt' 'time_series_Subj039.txt' 'time_series_Subj040.txt' 'time_series_Subj041.txt' 'time_series_Subj042.txt' 'time_series_Subj043.txt' 'time_series_Subj044.txt' 'time_series_Subj045.txt' 'time_series_Subj046.txt' 'time_series_Subj047.txt' 'time_series_Subj048.txt' 'time_series_Subj049.txt' 'time_series_Subj050.txt' 'time_series_Subj051.txt' 'time_series_Subj052.txt' 'time_series_Subj053.txt' 'time_series_Subj054.txt' 'time_series_Subj055.txt' 'time_series_Subj056.txt' 'time_series_Subj057.txt' 'time_series_Subj058.txt' 'time_series_Subj059.txt' 'time_series_Subj060.txt' 'time_series_Subj061.txt' 'time_series_Subj062.txt' 'time_series_Subj063.txt' 'time_series_Subj064.txt' 'time_series_Subj065.txt' 'time_series_Subj066.txt' 'time_series_Subj067.txt' 'time_series_Subj068.txt' 'time_series_Subj069.txt' 'time_series_Subj070.txt' 'time_series_Subj071.txt' 'time_series_Subj072.txt' 'time_series_Subj073.txt' 'time_series_Subj074.txt' 'time_series_Subj075.txt' 'time_series_Subj076.txt' 'time_series_Subj077.txt' 'time_series_Subj078.txt' 'time_series_Subj079.txt' 'time_series_Subj080.txt' 'time_series_Subj081.txt' 'time_series_Subj082.txt' 'time_series_Subj083.txt' 'time_series_Subj084.txt' 'time_series_Subj085.txt' 'time_series_Subj086.txt' 'time_series_Subj087.txt' 'time_series_Subj088.txt' 'time_series_Subj089.txt' 'time_series_Subj090.txt' 'time_series_Subj091.txt' 'time_series_Subj092.txt' 'time_series_Subj093.txt' 'time_series_Subj094.txt' 'time_series_Subj095.txt' 'time_series_Subj096.txt' 'time_series_Subj097.txt'};

% we will build an array of matrices: each matrix is a matrix of correlation of each subject
times_series_corr_array = NaN(num_roi,num_roi,numel(list_of_files));

% loop through each subject
    for s=1:numel(list_of_files);
        subj = list_of_files{s};
        fprintf(['*** Processing ' subj ' ***\n']);

        % load the time series
        ts = dlmread([path_data list_of_files{s}]);
        
        % Pearson correlation between all time series
        r = corrcoef(ts);
        
        % insert the correlation matrix into our array
        times_series_corr_array(:,:,s) = r;
    end

% Fisher r-to-z-transformation
% it is common practice to perform Fisher r-to-z-transformation
% in functional connectivity studies
% this procedure makes the correlation values more normally distributed
functional_connect_array = atanh(times_series_corr_array);


%4. Visualizing the connectivity matrix
%4.1. Now, that you have the functional connectivity matrix, you may want to see what happened.
%To visualize the connectivity matrix of subject n.23, you can use the following command:
figure;
imagesc(functional_connect_array(:,:,23));
colorbar;
axis square;
title('Functional connectivity of subject number 23');


%4.2 Perhaps you want to add the AAL anatomical labels. The list of AAL anatomical labels is saved in the file ROI_MNI_V4.txt (saved inside the same folder as this tutorial). This file contains 3 columns: the first column is an abbreviated string label, the second is the long string label and the third label is the numeric label (that matches the AAL image: ROI_MNI_V4.nii).

%Let’s load this file into matlab.
fid = fopen([path_data 'ROI_MNI_V4.txt']);
AAL_labels = textscan(fid, '%s %s %f');
fclose(fid);

%The long string labels are in the second column of this file.
AAL_long_labels = AAL_labels{2};

%Now we can build a connectivity matrix with the anatomical labels:
figure;
imagesc(functional_connect_array(:,:,23));
colorbar;
axis square;
title('Functional connectivity of subject number 23');
set(gca,'YTick',[1:numel(AAL_long_labels)]);
set(gca,'YTickLabel',AAL_long_labels);


%5. Correlate functional connectivity with a clinical variable
%Now you may want to test for correlations between a clinical variable and functional connectivity.
%5.1 In this example I will use “age” as my clinical variable.
%Let’s include the age data for the 97 subjects:
age = [53 35 15 62 36 51 27 18 33 38 60 59 47 57 36 58 19 58 45 94 60 25 51 18 65 26 42 78 78 44 63 42 20 25 75 30 47 30 53 51 54 28 12 56 16 46 62 27 50 52 35 70 22 42 39 80 50 22 92 55 70 32 27 22 58 46 20 39 64 29 19 19 59 47 33 60 31 37 88 35 18 63 46 66 78 75 15 42 90 74 44 76 74 30 88 53 50] % artificially created data
age = age'; % transpose so that each line is a subject

%5.2 Prepare functional connectivity data
%For each subject we created a square matrix (116 x 116) containing the functional connectivity data. This matrix is interesting for visualization purposes, but it contains redundant data (the upper and lower triangle contains the same information). Let’s extract the lower triangle from every subject. There are some ways to perform this task. The following set of commands take care of this task:
dim = [numel(list_of_files) nchoosek(num_roi,2)]; % dimensions of the matrix that will contain the nonredundant data

clean_functional_connectivity = NaN(dim); % each line is a subject; each column is an edge (number of columns is calculated by the binomial coefficient) using nchoosek

for s = 1:numel(list_of_files);
    counter = 1; % reset counter for each subject
    for c = 1:(num_roi-1); % set to start on column 1, line 2 (i.e. will read lower triangle)
        for l = (c+1):num_roi;
            clean_functional_connectivity(s,counter) = functional_connect_array(l,c,s);
            counter=counter+1;
        end;
    end;
end


%5.3. Calculate Pearson’s correlation between age and functional connectivity
% container for the correlation 'r' values; each column is an edge (i.e. a connection) 
r_age_FC_correl = NaN(1,size(clean_functional_connectivity,2)); 

% container for the correlation 'p' values; each column is an edge (i.e. a connection)
p_age_FC_correl = NaN(1,size(clean_functional_connectivity,2)); 
for e = 1:size(clean_functional_connectivity,2);
    [R,P]=corrcoef(age,clean_functional_connectivity(:,e));
    r_age_FC_correl(e) = R(2);
    p_age_FC_correl(e) = P(2);
end

%5.4 Recreate the square matrix with the results to visualize them
% square matrix dimensions
matrix_dim = [num_roi num_roi];

% container to the correlation 'r' values
r_age_FC_square_matrix = NaN(matrix_dim);

% do it first for the lower triangle
counter = 1; % reset counter
for c = 1:(num_roi-1);
    for l = (c+1):num_roi;
        r_age_FC_square_matrix(l,c) = r_age_FC_correl(counter);
        counter = counter+1;
    end
end

%now, the same thing to the upper triangle
counter = 1; % reset counter
for l = 1:(num_roi-1);
    for c = (l+1):num_roi;
        r_age_FC_square_matrix(l,c) = r_age_FC_correl(counter);
        counter = counter+1;
    end
end

%finally, insert "zeros" in the diagonal
r_age_FC_square_matrix(logical(eye(size(r_age_FC_square_matrix)))) = 0;

%%%%%
% now, everything again for the p-values
%%%%

% container to the correlation 'p' values
p_age_FC_square_matrix = NaN(matrix_dim);

% do it first for the lower triangle
counter = 1; % reset counter
for c = 1:(num_roi-1);
    for l = (c+1):num_roi;
        p_age_FC_square_matrix(l,c) = p_age_FC_correl(counter);
        counter = counter+1;
    end
end

%now, the same thing to the upper triangle
counter = 1; % reset counter
for l = 1:(num_roi-1);
    for c = (l+1):num_roi;
        p_age_FC_square_matrix(l,c) = p_age_FC_correl(counter);
        counter = counter+1;
    end
end

%finally, insert "Inf" in the diagonal
p_age_FC_square_matrix(logical(eye(size(p_age_FC_square_matrix)))) = Inf;


%5.5 Threshold the results so that only the significant one appear.
%5.5.1 Let’s start without any corrections for multiple testing
%Consider all connections presenting a p-value < 0.05 (uncorrected) significantly correlated with age.
uncorr_thr = 0.05; % set uncorrected threshold
uncorr_binary_matrix = p_age_FC_square_matrix < uncorr_thr; % binarize
uncorr_p_age_FC_square_matrix = Inf(num_roi,num_roi); % container
uncorr_p_age_FC_square_matrix(uncorr_binary_matrix == 1) = p_age_FC_square_matrix(uncorr_binary_matrix == 1); % keep original significant values

% display the thresholded p-values
figure;
imagesc(uncorr_p_age_FC_square_matrix);
axis square;
colorbar;
title(['P-values: Age x Functional Connectivity; threshold = ' num2str(uncorr_thr)])
set(gca,'YTick',[1:numel(AAL_long_labels)]);
set(gca,'YTickLabel',AAL_long_labels);
caxis([0 0.05]);

%5.5.2  Now, let’s use Bonferroni correction for multiple testing
number_of_tests = nchoosek(num_roi,2);
Bonf_corr_thr = uncorr_thr/number_of_tests;
Bonf_corr_binary_matrix = p_age_FC_square_matrix < Bonf_corr_thr; % binarize
Bonf_corr_p_age_FC_square_matrix = Inf(num_roi,num_roi); % container
Bonf_corr_p_age_FC_square_matrix(Bonf_corr_binary_matrix == 1) = p_age_FC_square_matrix(Bonf_corr_binary_matrix == 1); % keep original significant values

% display the thresholded p-values
figure;
imagesc(Bonf_corr_p_age_FC_square_matrix);
axis square;
colorbar;
title(['P-values: Age x Functional Connectivity; threshold = ' num2str(Bonf_corr_thr) ' (Bonferroni)'])
set(gca,'YTick',[1:numel(AAL_long_labels)]);
set(gca,'YTickLabel',AAL_long_labels);
caxis([0 0.05]);

%You will notice that the square matrix has only two colored points. Since the lower and upper triangle are mirrored (redundant information), we have only one connection that presented significant correlation with age after Bonferroni correction.
%Let’s find out more about this connection!
%Identify the pair of regions of this connection:
[r,c] = find(Bonf_corr_binary_matrix == 1) % find the row and the column where the significant connection is located

%Ok, now we know that this connection is between regions 30 and 67. Let’s find out their anatomical labels:
AAL_long_labels(30) % display anatomical label in the position 30
AAL_long_labels(67) % display anatomical label in the position 67

%Ok! So this connection is between the Right Insula and the Left Precuneus
%Display the p- and r-value of the correlation between age and functional connectivity between these two regions:
p_age_FC_square_matrix(r(1),c(1))
r_age_FC_square_matrix(r(1),c(1))
%This reveals that the correlation between age and functional connectivity between these two regions has r = 0.59 and p = 0.00000000028 (that’s why it survived Bonferroni!)

%5.5.3  We can also use False Discovery Rate (FDR) correction for multiple testing
%One option to perform FDR correction is to download a Matlab function that was developed by David Groppe and is available at http://www.mathworks.com/matlabcentral/fileexchange/27418-benjamini-hochbergyekutieli-procedure-for-controlling-false-discovery-rate/content/fdr_bh.m
%Unzip it somewhere in your computer and add the path to matlab:
addpath /Users/luiz/This_Is_Where_I_Saved_The_FDR_function

%Read its manual (open the function in Matlab or read its webpage).
%Then, use it:
[h, crit_p, adj_p]=fdr_bh(p_age_FC_correl);

%Let’s see the corrected p-values.
%Firstly, place the variables h and adj_p in square matrices (like we did before):
% square container to h
h_square_matrix = NaN(matrix_dim);

% do it first for the lower triangle
counter = 1; % reset counter
for c = 1:(num_roi-1);
    for l = (c+1):num_roi;
        h_square_matrix(l,c) = h(counter);
        counter = counter+1;
    end
end

%now, the same thing to the upper triangle
counter = 1; % reset counter
for l = 1:(num_roi-1);
    for c = (l+1):num_roi;
        h_square_matrix(l,c) = h(counter);
        counter = counter+1;
    end
end

%%%%%
% now, everything again for the adjusted p-values
%%%%

% square container to adj_p
adj_p_square_matrix = NaN(matrix_dim);

% do it first for the lower triangle
counter = 1; % reset counter
for c = 1:(num_roi-1);
    for l = (c+1):num_roi;
        adj_p_square_matrix(l,c) = adj_p(counter);
        counter = counter+1;
    end
end

%now, the same thing to the upper triangle
counter = 1; % reset counter
for l = 1:(num_roi-1);
    for c = (l+1):num_roi;
        adj_p_square_matrix(l,c) = adj_p(counter);
        counter = counter+1;
    end
end

%finally, insert "Inf" in the diagonal
adj_p_square_matrix(logical(eye(size(adj_p_square_matrix)))) = Inf;

%Now, let’s leave inside the adj_p_square_matrix only the significant values:
thresholded_adj_p_square_matrix = Inf(num_roi,num_roi); % container
thresholded_adj_p_square_matrix(h_square_matrix == 1) = adj_p_square_matrix(h_square_matrix == 1); % keep original significant values

%And finally, plot the results:
% display the thresholded p-values
figure;
imagesc(thresholded_adj_p_square_matrix);
axis square;
colorbar;
title(['Significant P-values, FDR-corrected: Age x Functional Connectivity'])
set(gca,'YTick',[1:numel(AAL_long_labels)]);
set(gca,'YTickLabel',AAL_long_labels);
caxis([0 0.05]);

%Well, after FDR correction, two connections were considered significantly correlated with age.
%And now, a last task that by now you should be able to perform alone: can you identify the two pairs of regions of these significant connections?
