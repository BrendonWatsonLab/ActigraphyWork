%% Bar Plot Overall
% Using direct data from .csv (5 minute bins)

% Plotting
combinedData = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyEphys/EphysCohortData.csv');

% List of conditions for plotting
conditions = {'300Lux', '1000Lux1', '1000Lux4', 'sleep_deprivation'};

% Initialize cell arrays to store data
condData = cell(length(conditions), 1);

% Collect data for each condition
for condIdx = 1:length(conditions)
    condition = conditions{condIdx};
    filtData = combinedData(strcmp(combinedData.Condition, condition), :);
    condData{condIdx} = filtData.NormalizedActivity;
end

% Combine data into a single array and create a grouping variable
allData = vertcat(condData{:});
group = {};

for condIdx = 1:length(conditions)
    group = [group; repmat(conditions(condIdx), length(condData{condIdx}), 1)];
end

% Convert group cell array to a categorical vector
group = categorical(group);

% Perform one-way ANOVA
[p, tbl, stats] = anova1(allData, group, 'off');

% Output ANOVA p-value
fprintf('ANOVA p-value: %f\n', p);

% Post-hoc multiple comparisons using Tukey's HSD test
comparisons = multcompare(stats, 'CType', 'tukey-kramer', 'Display', 'off');

% Calculate mean and standard error for each condition
means = zeros(length(conditions), 1);
stderr = zeros(length(conditions), 1);

for condIdx = 1:length(conditions)
    means(condIdx) = mean(condData{condIdx});
    stderr(condIdx) = std(condData{condIdx}) / sqrt(length(condData{condIdx})); % Standard error
end

% Create the bar plot
figure;
bar(means);
hold on;
errorbar(1:length(conditions), means, stderr, 'k', 'LineStyle', 'none');
set(gca, 'XTick', 1:length(conditions), 'XTickLabel', conditions, 'FontSize', 14, 'FontWeight', 'bold'); % Increase font size and bold
ylabel('Normalized Activity (z-score)', 'FontSize', 18, 'FontWeight', 'bold'); % Increase font size and bold
title('Comparison of Activity Across Lighting Conditions', 'FontSize', 20, 'FontWeight', 'bold'); % Increase font size and bold

% Prepare data for sigstar
significanceGroups = {};
significancePValues = [];
sigThreshold = 0.05; % Significance threshold

for i = 1:size(comparisons, 1)
    if comparisons(i, 6) < sigThreshold % significance level
        groupIndices = comparisons(i, 1:2);
        significanceGroups{end + 1} = groupIndices; %#ok<AGROW>
        significancePValues(end + 1) = comparisons(i, 6); %#ok<AGROW>
    end
end

% Add significance asterisks using sigstar if available
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