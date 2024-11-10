% Analysis for AO5-8, including dark conditions. This improves upon the original approach by
% aggregating data into daily means to avoid skewing caused by the large dataset,
% providing more meaningful statistics.

fprintf('Combining and Normalizing Data\n');

% Read the data from the CSV file
combinedData = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/AO1-8Dark_binned_data.csv');

% Display the column names to verify
disp('Column names in the data:');
disp(combinedData.Properties.VariableNames);

% The correct column name for NormalizedActivity (replace 'NormalizedActivi…' with the correct full name)
normalizedActivityColumn = 'NormalizedActivity';

% Filter out AO1-4 from the data for 'FullDark' and '300LuxEnd'
combinedData_AO5_8 = combinedData(~(ismember(combinedData.Animal, {'AO1', 'AO2', 'AO3', 'AO4'}) & ismember(combinedData.Condition, {'FullDark', '300LuxEnd'})), :);

% Aggregate the data to daily means
dailyData_AO5_8 = aggregate_daily_means(combinedData_AO5_8, normalizedActivityColumn);

% Extract data for each condition
data300Lux = dailyData_AO5_8(strcmp(dailyData_AO5_8.Condition, '300Lux'), :);
data1000Lux = dailyData_AO5_8(strcmp(dailyData_AO5_8.Condition, '1000Lux'), :);
dataFullDark = dailyData_AO5_8(strcmp(dailyData_AO5_8.Condition, 'FullDark'), :);
data300LuxEnd = dailyData_AO5_8(strcmp(dailyData_AO5_8.Condition, '300LuxEnd'), :);

%% Plotting: 300Lux vs 1000Lux
conditions1 = {'300Lux', '1000Lux'};
means1 = [mean(data300Lux.Mean_NormalizedActivity), mean(data1000Lux.Mean_NormalizedActivity)];
stderr1 = [mean(data300Lux.StdError), mean(data1000Lux.StdError)];

% Perform t-test between 300Lux and 1000Lux
[h1, p1] = ttest2(data300Lux.Mean_NormalizedActivity, data1000Lux.Mean_NormalizedActivity);
fprintf('p-value for 300Lux vs 1000Lux: %f\n', p1);

% Create bar plot
figure;
bar(means1);
hold on;
errorbar(1:length(conditions1), means1, stderr1, 'k', 'LineStyle', 'none');
set(gca, 'XTickLabel', conditions1, 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Normalized Activity (z-score)', 'FontSize', 18, 'FontWeight', 'bold');
title('Comparison of Activity: 300Lux vs 1000Lux', 'FontSize', 20, 'FontWeight', 'bold');

% Determine y-limits and place significance markers
max_y1 = max(means1 + stderr1);
min_y1 = min(means1 - stderr1);
line_y1 = max_y1 + 0.05 * abs(max_y1 - min_y1);
line_y1_neg = min_y1 - 0.05 * abs(max_y1 - min_y1);

if p1 < 0.05
    if max_y1 > 0
        plot([1, 2], [line_y1, line_y1], '-k', 'LineWidth', 1.5);
        text(1.5, line_y1 + 0.02 * abs(max_y1 - min_y1), '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    else
        plot([1, 2], [line_y1_neg, line_y1_neg], '-k', 'LineWidth', 1.5);
        text(1.5, line_y1_neg + 0.02 * abs(max_y1 - min_y1), '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    end
end
ylim([min_y1 - 0.3 * abs(max_y1 - min_y1), max_y1 + 0.3 * abs(max_y1 - min_y1)]);
hold off;

%% Plotting: 300Lux vs FullDark vs 300LuxEnd
conditions2 = {'300Lux', 'FullDark', '300LuxEnd'};
means2 = [mean(data300Lux.Mean_NormalizedActivity), mean(dataFullDark.Mean_NormalizedActivity), mean(data300LuxEnd.Mean_NormalizedActivity)];
stderr2 = [mean(data300Lux.StdError), mean(dataFullDark.StdError), mean(data300LuxEnd.StdError)];

% Perform t-tests between conditions
[h2, p2] = ttest2(data300Lux.Mean_NormalizedActivity, dataFullDark.Mean_NormalizedActivity);
[h3, p3] = ttest2(data300Lux.Mean_NormalizedActivity, data300LuxEnd.Mean_NormalizedActivity);
[h6, p6] = ttest2(dataFullDark.Mean_NormalizedActivity, data300LuxEnd.Mean_NormalizedActivity);

fprintf('p-value for 300Lux vs FullDark: %f\n', p2);
fprintf('p-value for 300Lux vs 300LuxEnd: %f\n', p3);
fprintf('p-value for FullDark vs 300LuxEnd: %f\n', p6);

% Create bar plot
figure;
bar(means2);
hold on;
errorbar(1:length(conditions2), means2, stderr2, 'k', 'LineStyle', 'none');
set(gca, 'XTickLabel', conditions2, 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Normalized Activity (z-score)', 'FontSize', 18, 'FontWeight', 'bold');
title('Comparison of Activity: 300Lux vs FullDark vs 300LuxEnd', 'FontSize', 20, 'FontWeight', 'bold');

% Determine y-limits and place significance markers
max_y2 = max(means2 + stderr2);
min_y2 = min(means2 - stderr2);
line_y2 = max_y2 + 0.05 * abs(max_y2 - min_y2);
line_y2_neg = min_y2 - 0.05 * abs(max_y2 - min_y2);
increment_y = max_y2 * 0.05;
increment_y_neg = min_y2 * 0.05;

if p2 < 0.05
    if max_y2 > 0
        plot([1, 2], [line_y2, line_y2], '-k', 'LineWidth', 1.5);
        text(1.5, line_y2 + increment_y, '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        line_y2 = line_y2 + 1.2 * increment_y;
    else
        plot([1, 2], [line_y2_neg, line_y2_neg], '-k', 'LineWidth', 1.5);
        text(1.5, line_y2_neg + increment_y_neg, '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        line_y2_neg = line_y2_neg + 1.2 * increment_y_neg;
    end
end
if p3 < 0.05
    if max_y2 > 0
        plot([1, 3], [line_y2, line_y2], '-k', 'LineWidth', 1.5);
        text(2, line_y2 + increment_y, '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        line_y2 = line_y2 + 1.2 * increment_y;
    else
        plot([1, 3], [line_y2_neg, line_y2_neg], '-k', 'LineWidth', 1.5);
        text(2, line_y2_neg + increment_y_neg, '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        line_y2_neg = line_y2_neg + 1.2 * increment_y_neg;
    end
end
if p6 < 0.05
    if max_y2 > 0
        plot([2, 3], [line_y2, line_y2], '-k', 'LineWidth', 1.5);
        text(2.5, line_y2 + increment_y, '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        line_y2 = line_y2 + 1.2 * increment_y;
    else
        plot([2, 3], [line_y2_neg, line_y2_neg], '-k', 'LineWidth', 1.5);
        text(2.5, line_y2_neg + increment_y_neg, '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        line_y2_neg = line_y2_neg + 1.2 * increment_y_neg;
    end   
end

ylim([min_y2 - 0.3 * abs(max_y2 - min_y2), max_y2 + 0.3 * abs(max_y2 - min_y2)]);
hold off;

% Save the figures if necessary (uncomment and adjust paths):
% saveas(gcf, fullfile(saveDir, 'Activity_Comparison_300Lux_vs_1000Lux.png'));
% saveas(gcf, fullfile(saveDir, 'Activity_Comparison_300Lux_vs_FullDark_vs_300LuxEnd.png'));

disp('Bar plots with statistical significance markers generated and saved.');

%% Function Definition
function aggregatedData = aggregate_daily_means(data, normalizedActivityColumn)
    aggregatedData = varfun(@mean, data, 'InputVariables', normalizedActivityColumn, 'GroupingVariables', {'Condition', 'Animal', 'RelativeDay'});
    
    % Verify column names before using them:
    meanColumnName = ['mean_' normalizedActivityColumn];
    if ismember(meanColumnName, aggregatedData.Properties.VariableNames)
        meanColumn = aggregatedData.(meanColumnName);
    else
        error('The column %s does not exist in aggregatedData.', meanColumnName);
    end
    
    stdError = varfun(@std, data, 'InputVariables', normalizedActivityColumn, 'GroupingVariables', {'Condition', 'Animal', 'RelativeDay'});
    stdErrorValues = stdError{:, ['std_' normalizedActivityColumn]} ./ sqrt(aggregatedData.GroupCount);
    
    aggregatedData = addvars(aggregatedData, meanColumn, 'NewVariableNames', 'Mean_NormalizedActivity');
    aggregatedData = addvars(aggregatedData, stdErrorValues, 'NewVariableNames', 'StdError');
    aggregatedData.GroupCount = []; % Remove the GroupCount variable
end