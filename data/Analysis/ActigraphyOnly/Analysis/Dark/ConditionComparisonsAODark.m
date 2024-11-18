% Analysis for AO5-8, including dark conditions. This improves upon the original approach by
% aggregating data into daily means to avoid skewing caused by the large dataset,
% providing more meaningful statistics.

fprintf('Combining and Normalizing Data\n');

% Read the data from the CSV file
combinedData = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/AO1-8Dark_binned_data.csv');

% Display the column names to verify
disp('Column names in the data:');
disp(combinedData.Properties.VariableNames);

% The correct column name for NormalizedActivity
normalizedActivityColumn = 'NormalizedActivity';

% Define male and female animals
maleAnimals = {'AO1', 'AO2', 'AO3', 'AO7'};
femaleAnimals = {'AO4', 'AO5', 'AO6', 'AO8'};

% Separate the data into males and females
maleData = combinedData(ismember(combinedData.Animal, maleAnimals), :);
femaleData = combinedData(ismember(combinedData.Animal, femaleAnimals), :);

% Function to process each group (males/females)
function process_group(groupData, groupName, normalizedActivityColumn)
    % Filter out AO1-4 from the data for 'FullDark' and '300LuxEnd'
    groupData_AO5_8 = groupData(~(ismember(groupData.Animal, {'AO1', 'AO2', 'AO3', 'AO4'}) & ...
                                  ismember(groupData.Condition, {'FullDark', '300LuxEnd'})), :);
    
    % Print the size of the filtered dataset
    fprintf('%s data size after filtering: %d rows\n', groupName, height(groupData_AO5_8));
    
    % Aggregate the data to daily means
    dailyData_AO5_8 = aggregate_daily_means(groupData_AO5_8, normalizedActivityColumn);

    % Print unique conditions to verify
    disp(['Unique conditions in ', groupName, ' dataset:']);
    disp(unique(dailyData_AO5_8.Condition));

    % Extract data for each condition
    data300Lux = dailyData_AO5_8(strcmp(dailyData_AO5_8.Condition, '300Lux'), :);
    data1000Lux = dailyData_AO5_8(strcmp(dailyData_AO5_8.Condition, '1000Lux'), :);
    dataFullDark = dailyData_AO5_8(strcmp(dailyData_AO5_8.Condition, 'FullDark'), :);
    data300LuxEnd = dailyData_AO5_8(strcmp(dailyData_AO5_8.Condition, '300LuxEnd'), :);

    %% Statistical Analysis: ANOVA and post hoc Tukey's HSD
    % Prepare data for ANOVA
    anovaData = [data300Lux; data1000Lux; dataFullDark; data300LuxEnd];
    p = anovan(anovaData.Mean_NormalizedActivity, {anovaData.Condition}, 'model', 'full', 'varnames', {'Condition'});

    % Conduct Tukey's HSD post hoc test
    [~, ~, stats] = anova1(anovaData.Mean_NormalizedActivity, anovaData.Condition, 'off');
    comp = multcompare(stats, 'CType', 'tukey-kramer', 'Display', 'off');

    % Extract pairwise comparisons and p-values
    pairwise_comparisons = comp(:, 1:2);
    p_values = comp(:, 6);
    
    %% Plotting: 300Lux vs 1000Lux
    conditions1 = {'300Lux', '1000Lux'};
    means1 = [mean(data300Lux.Mean_NormalizedActivity), mean(data1000Lux.Mean_NormalizedActivity)];
    stderr1 = [mean(data300Lux.StdError), mean(data1000Lux.StdError)];

    % Create bar plot
    figure;
    bar(means1);
    hold on;
    errorbar(1:length(conditions1), means1, stderr1, 'k', 'LineStyle', 'none');
    
    % Add significance stars if any p-values are significant for this comparison
    indices = find((pairwise_comparisons(:, 1) == 1 & pairwise_comparisons(:, 2) == 2) | (pairwise_comparisons(:, 1) == 2 & pairwise_comparisons(:, 2) == 1));
    if any(p_values(indices) < 0.05)
        sigstar({[1, 2]}, p_values(indices));
    end

    set(gca, 'XTickLabel', conditions1, 'XTick', 1:length(conditions1), 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Normalized Activity (z-score)', 'FontSize', 18, 'FontWeight', 'bold');
    title(sprintf('Comparison of Activity: 300Lux vs 1000Lux (%s)', groupName), 'FontSize', 20, 'FontWeight', 'bold');
    hold off;

    %% Plotting: 300Lux vs FullDark vs 300LuxEnd
    conditions2 = {'300Lux', 'FullDark', '300LuxEnd'};
    means2 = [mean(data300Lux.Mean_NormalizedActivity), mean(dataFullDark.Mean_NormalizedActivity), mean(data300LuxEnd.Mean_NormalizedActivity)];
    stderr2 = [mean(data300Lux.StdError), mean(dataFullDark.StdError), mean(data300LuxEnd.StdError)];

    % Create bar plot
    figure;
    bar(means2);
    hold on;
    errorbar(1:length(conditions2), means2, stderr2, 'k', 'LineStyle', 'none');
    
    % Add significance stars for any significant pairwise comparisons for these conditions
    pairs = {[1, 2], [2, 3], [1, 3]};
    for i = 1:length(pairs)
        indices = find((pairwise_comparisons(:, 1) == pairs{i}(1) & pairwise_comparisons(:, 2) == pairs{i}(2)) | ...
                       (pairwise_comparisons(:, 1) == pairs{i}(2) & pairwise_comparisons(:, 2) == pairs{i}(1)));
        if any(p_values(indices) < 0.05)
            sigstar(pairs(i), p_values(indices));
        end
    end
    
    set(gca, 'XTickLabel', conditions2, 'XTick', 1:length(conditions2), 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Normalized Activity (z-score)', 'FontSize', 18, 'FontWeight', 'bold');
    title(sprintf('Comparison of Activity: 300Lux vs FullDark vs 300LuxEnd (%s)', groupName), 'FontSize', 20, 'FontWeight', 'bold');
    hold off;
end

% Process data for males and females
process_group(maleData, 'Males', normalizedActivityColumn);
process_group(femaleData, 'Females', normalizedActivityColumn);

disp('Bar plots generated.');

%% Function Definition
function aggregatedData = aggregate_daily_means(data, normalizedActivityColumn)
    % Print the size of the original dataset
    fprintf('Original data size: %d rows\n', height(data));

    % Floor the RelativeDay values to aggregate by integer days
    data.RelativeDay = floor(data.RelativeDay);

    % Print the unique RelativeDay values to ensure flooring worked
    disp('Unique RelativeDay values after flooring:');
    disp(unique(data.RelativeDay));

    % Aggregate the data to daily means
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

    % Create a new table with desired variables only
    aggregatedData = aggregatedData(:, {'Condition', 'Animal', 'RelativeDay'}); % Retain only relevant columns
    aggregatedData.Mean_NormalizedActivity = meanColumn;  % Add mean column
    aggregatedData.StdError = stdErrorValues;  % Add standard error column
    
    % Print the size of the aggregated dataset
    fprintf('Aggregated data size: %d rows\n', height(aggregatedData));
end