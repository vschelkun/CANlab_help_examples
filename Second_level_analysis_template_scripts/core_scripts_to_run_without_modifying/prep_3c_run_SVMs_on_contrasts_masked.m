% THIS SCRIPT RUNS SVMs for WITHIN-PERSON CONTRASTS
% Specified in DAT.contrasts
% --------------------------------------------------------------------

% USER OPTIONS

% Now set in a2_set_default_options
if ~exist('dosavesvmstats', 'var') || ~exist('dobootstrap', 'var') || ~exist('boot_n', 'var')
    a2_set_default_options;
end

% dosavesvmstats = true;  % default false
% dobootstrap = true;    % default false
% boot_n = 100;           % default number of boot samples is 5,000

% Specified in DAT.contrasts
% --------------------------------------------------------------------

spath = which('use_spider.m');
if isempty(spath)
    disp('Warning: spider toolbox not found on path; prediction may break')
end

kc = size(DAT.contrasts, 1);

if dobootstrap, svmtime = tic; end

%% Get mask
if exist('maskname', 'var') && ~isempty(maskname)
    
    svmmask = fmri_data(maskname);
    
end

%% Train all models
% --------------------------------------------------------------------

svm_stats_results = cell(1, kc);

for c = 1:kc
    
    printstr(DAT.contrastnames{c});
    printstr(dashes)
    
    mycontrast = DAT.contrasts(c, :);
    wh = find(mycontrast);
    
    % Create combined data object with all input images
    % --------------------------------------------------------------------
    [cat_obj, condition_codes] = cat(DATA_OBJ{wh});
    
    % Norm options:
    % --------------------------------------------------------------------
    % possibly normalize_each_subject_by_l2norm; can help with numerical scaling and inter-subject scaling diffs
    % Sometimes condition differences are very small relative to baseline
    % values and SVM is numerically unstable. If so, re-normalizing each
    % subject can help.
    
    if exist('dosubjectnorm', 'var') && dosubjectnorm
        % cat_obj = normalize_each_subject_by_l2norm(cat_obj, condition_codes);
        disp('Normalizing intensity of all images by L2 norm before SVM.')
        
        cat_obj = normalize_images_by_l2norm(cat_obj);
    end
    
    % Z-score each input image, removing image mean and forcing std to 1.
    % Removes overall effects of image intensity and scale. Can be useful
    % across studies but also removes information. Use judiciously.
    
    if exist('dozscoreimages', 'var') && dozscoreimages
        
        disp('Z-scoring each image before SVM.')
        cat_obj = rescale(cat_obj, 'zscoreimages');
        
    end
    
    % Apply mask
    
    if exist('svmmask', 'var')
        
        cat_obj = apply_mask(cat_obj, svmmask);
        
    end
    
    % a. Format and attach outcomes: 1, -1 for pos/neg contrast values
    % b. Define holdout sets: Define based on plugin script
    %    Assume that subjects are in same position in each input file
    % --------------------------------------------------------------------

    plugin_get_holdout_sets;
    
    cat_obj.Y = outcome_value;
    
    % Skip if necessary
    % --------------------------------------------------------------------
    
    if all(cat_obj.Y > 0) || all(cat_obj.Y < 0)
        % Only positive or negative weights - nothing to compare
        
        printhdr(' Only positive or negative weights - nothing to compare');
        
        continue    
    end
    
    % Run prediction model
    % --------------------------------------------------------------------
    if dobootstrap
        [cverr, stats, optout] = predict(cat_obj, 'algorithm_name', 'cv_svm', 'nfolds', holdout_set, 'bootsamples', boot_n, 'error_type', 'mcr', parallelstr);
        % Threshold, if possible - can re-threshold later with threshold() method
        stats.weight_obj = threshold(stats.weight_obj, .05, 'unc'); 
        
    else
        [cverr, stats, optout] = predict(cat_obj, 'algorithm_name', 'cv_svm', 'nfolds', holdout_set, 'error_type', 'mcr', parallelstr);
    end
    
    % Save stats objects for results later
    % --------------------------------------------------------------------
    
    stats.weight_obj = enforce_variable_types(stats.weight_obj);
    svm_stats_results{c} = stats;
        
    if exist('svmmask', 'var')
    
        svm_stats_results{c}.mask = svmmask;
        svm_stats_results{c}.maskname = maskname;
    
    end
    
    if dobootstrap, disp('Cumulative run time:'), toc(svmtime); end

end  % Contrasts - run
    
%% Save
if dosavesvmstats
    
    savefilenamedata = fullfile(resultsdir, 'svm_stats_results_contrasts_masked.mat');

    save(savefilenamedata, 'svm_stats_results', '-v7.3');
    printhdr('Saved svm_stats_results for contrasts - masked');
    
end


