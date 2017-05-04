
num_roi = dlmread(['PROC/nroi.1D']);
subj = textread('PROC/ts.1D','%q');;
age = 56;

fprintf(['*** Processing ' subj{1} ' ***\n']);

% Pearson correlation between all time series
times_series_corr_array = NaN(num_roi,num_roi);
ts = dlmread(subj{1});
r = corrcoef(ts);
times_series_corr_array = r;

% Fisher r-to-z-transformation
functional_connect_array = atanh(times_series_corr_array);


% clean matrix
dim = [1 nchoosek(num_roi,2)]; 
clean_functional_connectivity = NaN(dim);

counter = 1; % reset counter for each subject
    for c = 1:(num_roi-1); % set to start on column 1, line 2 (i.e. will read lower triangle)
        for l = (c+1):num_roi;
            clean_functional_connectivity(1,counter) = functional_connect_array(l,c);
            counter=counter+1;
        end;
    end;
