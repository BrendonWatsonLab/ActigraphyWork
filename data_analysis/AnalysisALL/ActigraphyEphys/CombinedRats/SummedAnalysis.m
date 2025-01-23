%% Overview
% This script reads activity data from a CSV file, segregating it by various light conditions.
% It performs statistical analyses including one-way ANOVA and post-hoc multiple comparisons using Tukey's HSD test.
% Finally, it visualizes the results using a bar plot with error bars representing standard errors,
% and marks significant differences between conditions if the `sigstar` function is available.

%% Bar Plot Overall
% Using direct data from .csv (5 minute bins)

% Load and read data from the CSV file
combinedData = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyEphys/EphysActivityData.csv');

% Ensure 'RelativeDay' is numeric
if ~isnumeric(combinedData.RelativeDay)
    combinedData.RelativeDay = str2double(string(combinedData.RelativeDay));
end

% Use floor to group by integer days based on 'RelativeDay'
combinedData.RelativeDay = floor(combinedData.RelativeDay);

% Convert 'RelativeDay' to categorical
combinedData.RelativeDay = categorical(combinedData.RelativeDay);

% List of experimental conditions for plotting
conditions = {'300Lux', '1000Lux1', '1000Lux4', 'sleep_deprivation'};

% Ensure the 'Condition' column is a categorical type
combinedData.Condition = categorical(combinedData.Condition, conditions);

% Initialize cell arrays to store pooled means for each condition
condData = cell(length(conditions), 1);

% Collect data for each condition
for condIdx = 1:length(conditions)
    condition = conditions{condIdx};
    % Filter data using the ismember function for categorical array
    filtData = combinedData(combinedData.Condition == condition, :);
    % Calculate daily means of 'NormalizedActivity' for each day
    dailyMeans = varfun(@mean, filtData, 'InputVariables', 'NormalizedActivity', ...
                        'GroupingVariables', 'RelativeDay');
    % Store the daily mean values
    condData{condIdx} = dailyMeans.mean_NormalizedActivity;
end

% Combine data from all conditions into a single array and create a grouping variable
allData = vertcat(condData{:});
group = arrayfun(@(i) repmat(conditions(i), size(condData{i})), 1:length(conditions), 'UniformOutput', false);
group = categorical(vertcat(group{:}));

% Perform one-way ANOVA analysis
[p, tbl, stats] = anova1(allData, group, 'off');

% Output the ANOVA p-value to the console
fprintf('ANOVA p-value: %f\n', p);

% Post-hoc multiple comparisons using Tukey's HSD test
comparisons = multcompare(stats, 'CType', 'tukey-kramer', 'Display', 'off');

% Calculate mean and standard error for each condition
means = cellfun(@mean, condData);
stderr = cellfun(@(x) std(x) / sqrt(length(x)), condData);

% Create the bar plot for visualizing the data
figure;
b = bar(means, 'FaceColor', [0.7 0.7 0.7]); % Gray bars
hold on;
% Add error bars to the bar chart
errorbar(1:length(conditions), means, stderr, 'k', 'LineStyle', 'none');
% Customize the appearance of the plot
set(gca, 'XTick', 1:length(conditions), ...
         'XTickLabel', conditions, ...
         'FontSize', 14, ...
         'FontWeight', 'bold'); % Increase font size and bold
ylabel('Normalized Activity', ...
       'FontSize', 18, ...
       'FontWeight', 'bold'); % Increase font size and bold
title('Comparison of Normalized Activity Across Lighting Conditions', ...
      'FontSize', 20, ...
      'FontWeight', 'bold'); % Increase font size and bold

% Prepare data for marking significance in the plot
significanceGroups = {};
significancePValues = [];
sigThreshold = 0.05; % Define the significance threshold

for i = 1:size(comparisons, 1)
    if comparisons(i, 6) < sigThreshold % Only consider significant comparisons
        significanceGroups{end + 1} = comparisons(i, 1:2); 
        significancePValues(end + 1) = comparisons(i, 6); 
    end
end

% Add significance asterisks to the plot if `sigstar` function is available
if exist('sigstar', 'file') == 2 && ~isempty(significanceGroups)
    % Calculate y-offset for significance lines
    numSigs = length(significanceGroups);
    sigYOffset = 0.05 * (max(means + stderr) - min(means - stderr));
    
    % Ensure there is enough space at the top of the plot for significance markers
    yMax = max(means + stderr) + numSigs * sigYOffset;
    ylim([min(0, min(means - stderr)), yMax]);

    % Adjust y position of significance groups manually
    for k = 1:numSigs
        sigstar(significanceGroups(k), significancePValues(k));
    end
else
    warning('sigstar function is not available. Please ensure sigstar is added to the path or that there are significant comparisons.');
end
hold off;

disp('Bar plot with ANOVA significance markers generated.');

% Output Tukey's HSD test p-values for each comparison
fprintf('\nTukey''s HSD test comparisons:\n');
for i = 1:size(comparisons, 1)
    fprintf('%s vs %s: p-value = %.5f\n', conditions{comparisons(i, 1)}, conditions{comparisons(i, 2)}, comparisons(i, 6));
end