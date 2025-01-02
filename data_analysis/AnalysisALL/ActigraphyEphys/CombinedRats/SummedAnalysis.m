%% Overview
% This script reads activity data from a CSV file, segregating it by various light conditions.
% It performs statistical analyses including one-way ANOVA and post-hoc multiple comparisons using Tukey's HSD test.
% Finally, it visualizes the results using a bar plot with error bars representing standard errors,
% and marks significant differences between conditions if the `sigstar` function is available.

%% Bar Plot Overall
% Using direct data from .csv (5 minute bins)

% Load and read data from the CSV file
combinedData = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyEphys/EphysCohortData.csv');

% List of experimental conditions for plotting
conditions = {'300Lux', '1000Lux1', '1000Lux4', 'sleep_deprivation'};

% Initialize cell arrays to store data for each condition
condData = cell(length(conditions), 1);

% Collect data for each condition
for condIdx = 1:length(conditions)
    condition = conditions{condIdx};
    % Filter data based on the current condition
    filtData = combinedData(strcmp(combinedData.Condition, condition), :);
    % Store the selected pixel difference values for the current condition
    condData{condIdx} = filtData.SelectedPixelDifference;
end

% Combine data from all conditions into a single array and create a grouping variable
allData = vertcat(condData{:});
group = {};

for condIdx = 1:length(conditions)
    % Repeat the condition name for the number of data points in that condition
    group = [group; repmat(conditions(condIdx), length(condData{condIdx}), 1)];
end

% Convert the group cell array to a categorical vector for ANOVA
group = categorical(group);

% Perform one-way ANOVA analysis
[p, tbl, stats] = anova1(allData, group, 'off');

% Output the ANOVA p-value to the console
fprintf('ANOVA p-value: %f\n', p);

% Post-hoc multiple comparisons using Tukey's HSD test
comparisons = multcompare(stats, 'CType', 'tukey-kramer', 'Display', 'off');

% Calculate mean and standard error for each condition
means = zeros(length(conditions), 1);
stderr = zeros(length(conditions), 1);

for condIdx = 1:length(conditions)
    % Calculate the mean of the selected pixel difference values
    means(condIdx) = mean(condData{condIdx});
    % Calculate the standard error of the mean
    stderr(condIdx) = std(condData{condIdx}) / sqrt(length(condData{condIdx}));
end

% Create the bar plot for visualizing the data
figure;
bar(means);   % Plot the means as a bar chart
hold on;
% Add error bars to the bar chart
errorbar(1:length(conditions), means, stderr, 'k', 'LineStyle', 'none');
% Customize the appearance of the plot
set(gca, 'XTick', 1:length(conditions), ...
          'XTickLabel', conditions, ...
          'FontSize', 14, ...
          'FontWeight', 'bold'); % Increase font size and bold
ylabel('SelectedPixelDifference', ...
       'FontSize', 18, ...
       'FontWeight', 'bold'); % Increase font size and bold
title('Comparison of Activity Across Lighting Conditions', ...
      'FontSize', 20, ...
      'FontWeight', 'bold'); % Increase font size and bold

% Prepare data for marking significance in the plot
significanceGroups = {};
significancePValues = [];
sigThreshold = 0.05; % Define the significance threshold

for i = 1:size(comparisons, 1)
    if comparisons(i, 6) < sigThreshold % Only consider significant comparisons
        groupIndices = comparisons(i, 1:2);
        significanceGroups{end + 1} = groupIndices; 
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

% Save the figure if necessary
% saveas(gcf, fullfile(saveDir, 'Activity_Comparison_BarPlot_with_Significance.png'));

disp('Bar plot with ANOVA significance markers generated and saved.');

% Output Tukey's HSD test p-values for each comparison
fprintf('\nTukey''s HSD test comparisons:\n');
for i = 1:size(comparisons, 1)
    fprintf('%s vs %s: p-value = %.5f\n', conditions{comparisons(i, 1)}, conditions{comparisons(i, 2)}, comparisons(i, 6));
end