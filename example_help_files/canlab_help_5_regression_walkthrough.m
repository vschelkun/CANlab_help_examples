%% Load sample data
% BLOCK 1
% ---------------------------------------------------------------

% Load sample data using load_image_set(), which produces an fmri_data
% object. Data loading exceeds the scope of this tutorial, but a more
% indepth demosntration may be provided by canlab_help_2_load_a_sample_dataset.m

% These are [Reappraise - Look Neg] contrast images, one image per person

[image_obj, networknames, imagenames] = load_image_set('emotionreg');

% Summarize and print a table with characteristics of the data:
desc = descriptives(image_obj);

% Load behavioral data
% This is "Reappraisal success", one score per person, in our example
% If you do not have the file on your path, you will get an error.

beh = importdata('Wager_2008_emotionreg_behavioral_data.txt')
success = beh.data(:, 2);           % Reappraisal success

% Load a mask that we would like to apply to analysis/results

mask = which('gray_matter_mask.img')

maskdat = fmri_data(mask, 'noverbose');

%% Visualize the mask
% ---------------------------------------------------------------
% BLOCK 2: Check mask

% This is an underlay brain:

o2 = canlab_results_fmridisplay([], 'noverbose');
drawnow, snapnow;

% This is a basic gray-matter mask we will use for analysis:
% It can help reduce multiple comparisons relative to whole-image analysis
% but we should still look at what's happening in ventricles and
% out-of-brain space to check for artifacts.

o2 = addblobs(o2, region(maskdat));

% Add a title to montage 1, the axial slice montage:
o2 = title_montage(o2, 1, 'Mask image: Gray matter with border');

drawnow, snapnow;

%% Visualize summary of brain coverage
% ---------------------------------------------------------------
% BLOCK 3: Check that we have valid data in most voxels for most subjects

% Show summary of coverage - how many images have non-zero, non-NaN values in each voxel

o2 = removeblobs(o2);
o2 = montage(region(desc.coverage_obj), o2, 'trans', 'transvalue', .3);

o2 = title_montage(o2, 1, 'Coverage in images');

% OR:
% orthviews(desc.coverage_obj, 'continuous');

%% BLOCK 4
% ---------------------------------------------------------------
% Check histograms of individual subjects for global shifts in contrast values

% The 'histogram' object method will allow you to examine a series of
% images in one panel each.  See help fmri_data.histogram for more options,
% including breakdown by tissue type.

hist_han = histogram(image_obj, 'byimage', 'color', 'b');

% This shows us that some of the images do not have the same mean as the
% others. This is fairly common, as individual subjects can often have
% global artifacts (e.g., task-correlated head motion or outliers) that
% influence the whole contrast image, even when baseline conditions are
% supposed to be "subtracted out".  
%
% It suggests that we may want to do an outlier analysis and/or standardize 
% the scale of the images. We'll return to this below.

%% BLOCK 5
% ---------------------------------------------------------------
% Examine predictor distribution and leverages
% Leverage is a measure of how much each point influences the regression
% line. The more extreme the predictor value, the higher the leverage.
% Outliers will have very high leverage. High-leverage behavioral observations 
% can strongly influence, and sometimes invalidate, an analysis.

X = scale(success, 1); X(:, end+1) = 1;         % A simple design matrix, behavioral predictor + intercept
H = X * inv(X'* X) * X';                        % The "Hat Matrix", which produces fits. Diagonals are leverage

create_figure('levs', 2, 1); 
plot(success, 'o', 'MarkerFaceColor', [0 .3 .7], 'LineWidth', 3); 
set(gca, 'FontSize', 24); 
xlabel('Subject number'); 
ylabel('Reappraisal success');

subplot(2, 1, 2);
plot(diag(H), 'o', 'MarkerFaceColor', [0 .3 .7], 'LineWidth', 3); 
set(gca, 'FontSize', 24); 
xlabel('Subject number'); 
ylabel('Leverage');


%% BLOCK 6
% Run regression
% The regress method takes predictors that are attached in the object's X
% attribute (X stands for design matrix) and regresses each voxel's
% activity (y) on the set of regressors.  
% This is a group analysis, in this case correlating brain activity with
% reappraisal success at each voxel.

% .X must have the same number of observations, n, in an n x k matrix.
% n images is the number of COLUMNS in image_obj.dat

% mean-center success scores and attach them to image_obj in image_obj.X
image_obj.X = scale(success, 1);

% runs the regression at each voxel and returns statistic info and creates
% a visual image.  regress = multiple regression.

out = regress(image_obj);

% out has statistic_image objects that have information about the betas
% (slopes) b, t-values and p-values (t), degrees of freedom (df), and sigma
% (error variance).  The critical one is out.t.
% out = 
% 
%         b: [1x1 statistic_image]
%         t: [1x1 statistic_image]
%        df: [1x1 fmri_data]
%     sigma: [1x1 fmri_data]

% Now let's try thresholding the image at q < .05 fdr-corrected.
 t = threshold(out.t, .05, 'fdr');
 
% ...and display

o2 = montage(t, 'trans');
o2 = title_montage(o2, 2, 'Behavioral predictor: Reappraisal success');
o2 = title_montage(o2, 4, 'Intercept: Group average activation');
snapnow

% Or:
% orthviews(t)

% This is a multiple regression, and there are two output t images, one for
% each regressor.  We've only entered one regressor, why two images?  The program always
% adds an intercept by default.  The intercept is always the last column of the design matrix

% Image   1  <--- brain contrast values correlated with "success"
% Positive effect:   0 voxels, min p-value: 0.00001192
% Negative effect:   0 voxels, min p-value: 0.00170529
% Image   2 FDR q < 0.050 threshold is 0.003193
% 
% Image   2 <--- intercept, because we have mean-centered, this is the
% average group effect (when success = average success).  "Reapp - Look"
% contrast in the whole group.
% Positive effect: 3133 voxels, min p-value: 0.00000000
% Negative effect:  51 voxels, min p-value: 0.00024068

% re-threshold at p < .005 uncorrected
t = threshold(out.t, .005, 'unc');

o2 = montage(t, 'trans');
o2 = title_montage(o2, 2, 'Behavioral predictor: Reappraisal success');
o2 = title_montage(o2, 4, 'Intercept: Group average activation');
snapnow


%% BLOCK 7
% Display the results on slices

% multi_threshold lets us see the blobs with significant voxels at the
% highest (most stringent) threshold, and voxels that are touching
% (contiguous) down to the lowest threshold, in different colors.

o2 = multi_threshold(out.t, 'thresh', [.005 .01 .05], 'sizethresh', [5 1 1]);

o2 = title_montage(o2, 2, 'Behavioral predictor: Reappraisal success');
o2 = title_montage(o2, 4, 'Intercept: Group average activation');
snapnow

%% BLOCK 8: Look for signal in ventricles, white matter, outside of brain
%
% We want to diagnose potential problems due to outliers, etc...

% Strategy 1:  Apply a very liberal threshold.
t = threshold(out.t, .05, 'unc');

figure;
o2 = canlab_results_fmridisplay;
o2 = addblobs(o2, region(t));

o2 = title_montage(o2, 5, 'Liberal threshold: .05 uncorrected');


% Strategy 2: Extract mean signal from WM and ventricles
m = extract_gray_white_csf(image_obj);

barplot_columns(m, 'title', 'Gray white CSF per subject', 'names', {'Gray' 'White' 'CSF'}, 'XTick', [1:3], 'colors', {[1 0 0] [0 .7 0] [0 0 1]});

ylabel('Contrast values');


% global_gray_white_csf = extract_gray_white_csf(image_obj);
% corr([global_gray_white_csf diag(H) success])

%% BLOCK 9: Compare results to meta-analysis for positive controls

% Map from neurosynth.org 
metaimg = which('emotion regulation_pAgF_z_FDR_0.01_8_14_2015.nii')
r = region(metaimg);

o2 = removeblobs(o2);
o2 = addblobs(o2, r, 'maxcolor', [1 0 0], 'mincolor', [.7 .2 .5]);

o2 = title_montage(o2, 5, 'Neurosynth mask: Emotion regulation');

%% BLOCK 10: Apply gray-matter mask and show FDR-thresholded results

% This can increase power by focusing on areas we think there are plausible
% effects. First is the success effect (regressor) and second is the
% intercept (group average contrast) map.

%t = threshold(out.t, .05, 'fdr', 'mask', mask);

t = apply_mask(out.t, maskdat);
t = threshold(t, .05, 'fdr');

% Select the reappraisal success effect only and show it
t1 = select_one_image(t, 1);

o2 = removeblobs(o2);
o2 = addblobs(o2, region(t1));

o2 = title_montage(o2, 5, 'Behavioral predictor, gray-matter masked, q < .05 FDR');


%% BLOCK 11: Refine analysis by removing outlier and ranking predictor values

% exclude high-leverage subject 16
datno16 = image_obj;
datno16.dat(:, 16) = [];

% try rank: robust...
% Ranking is a kind of nonparametric

datno16.X = success;
datno16.X(16) = [];
datno16.X = scale(rankdata(datno16.X), 1);

% Re-run regression
out = regress(datno16);

% Apply gray matter mask and threshold
t = apply_mask(out.t, maskdat);
t = threshold(t, .005, 'unc');
%orthviews(t)

o2 = multi_threshold(t, 'thresh', [.005 .01 .05], 'sizethresh', [1 1 1]);

o2 = title_montage(o2, 2, 'Behavioral predictor: Reappraisal success');
o2 = title_montage(o2, 4, 'Intercept: Group average activation');
snapnow


% Select the reappraisal success effect only and write it to disk

t1 = select_one_image(t, 1);
t1.fullpath = fullfile(pwd, 'Reapp_Success_005_outlier_removed.nii');
write(t1)

%% Block 12: Extract and plot data from (biased) regions of interest
% Let's visualize the correlation scatterplots in the areas we've
% discovered as related to Success

% Select the Success regressor map
r = region(t1);

% Autolabel regions and print a table
r = table(r);

% Make a montage showing each significant region
montage(r, 'colormap', 'regioncenters');

%% Block 13: Extract and plot data from (biased) regions of interest
% Let's visualize the correlation scatterplots in the areas we've
% discovered as related to Success

% Extract data from all regions
% r(i).dat has the averages for each subject across voxels for region i
r = extract_data(r, datno16);

% Select only regions with 3+ voxels
wh = cat(1, r.numVox) < 3;
r(wh) = [];

% Set up the scatterplots
nrows = floor(sqrt(length(r)));
ncols = ceil(length(r) ./ nrows);
create_figure('scatterplot_region', nrows, ncols);

% Make a loop and plot each region
for i = 1:length(r)
    
    subplot(nrows, ncols, i);

    % Use this line for non-robust correlations:
    %plot_correlation_samefig(r(i).dat, datno16.X);
    
    % Use this line for robust correlations:
    plot_correlation_samefig(r(i).dat, datno16.X, [], 'k', 0, 1);
  
    set(gca, 'FontSize', 12);
    xlabel('Reappraise - Look Neg brain response');
    ylabel('Reappraisal success');
    
    % input('Press a key to continue');
    
end


%% Block 14: Extract and plot data from unbiased regions of interest
% Let's visualize the correlation scatterplots in some meta-analysis
% derived ROIs

% Select the Neurosynth meta-analysis map
r = region(metaimg);

% Extract data from all regions
r = extract_data(r, datno16);

% Select only regions with 20+ voxels
wh = cat(1, r.numVox) < 20;
r(wh) = [];

r = table(r);

% Make a montage showing each significant region
montage(r, 'colormap', 'regioncenters');

% Set up the scatterplots
nrows = floor(sqrt(length(r)));
ncols = ceil(length(r) ./ nrows);
create_figure('scatterplot_region', nrows, ncols);

% Make a loop and plot each region
for i = 1:length(r)
    
    subplot(nrows, ncols, i);

    % Use this line for non-robust correlations:
    %plot_correlation_samefig(r(i).dat, datno16.X);
    
    % Use this line for robust correlations:
    plot_correlation_samefig(r(i).dat, datno16.X, [], 'k', 0, 1);
  
    set(gca, 'FontSize', 12);
    xlabel('Brain');
    ylabel('Success');
    title(' ');
   
end

%% Block 15: Multivariate prediction from unbiased ROI averages


datno16.Y = datno16.X;  % .Y is the outcome to be explained

% 5-fold cross validated prediction, stratified on outcome

[cverr, stats, optout] = predict(datno16, 'algorithm_name', 'cv_lassopcrmatlab', 'nfolds', 5);

% Though many areas show some significant effects, these are not strong
% enough to obtain a meaningful out-of-sample prediction of Success

