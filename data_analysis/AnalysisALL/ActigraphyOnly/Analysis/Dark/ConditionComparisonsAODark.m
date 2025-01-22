% Analysis for AO5-8, including dark conditions. This improves upon the original approach by
% aggregating data into daily means to avoid skewing caused by the large dataset,
% providing more meaningful statistics.

%% Synopsis
% This script analyzes the activity data for animals AO1 to AO8, focusing specifically on
% dark conditions. The data is aggregated into daily and weekly means to ensure that the
% large dataset does not skew the results. Separate bar plots are generated for male and
% female animals, showing the weekly averages of the SelectedPixelDifference under different
% lighting conditions (300Lux, 1000Lux, FullDark, 300LuxEnd).

%% Starting

% Read the data from the CSV file
combinedData = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyOnly/AOActivityData.csv');

% Display the column names to verify
disp('Column names in the data:');
disp(combinedData.Properties.VariableNames);

% The correct column name for SelectedPixelDifference
selectedPixelDifferenceColumn = 'SelectedPixelDifference';

% Define male and female animals
maleAnimals = {'AO1', 'AO2', 'AO3', 'AO7'};
femaleAnimals = {'AO4', 'AO5', 'AO6', 'AO8'};

% Separate the data into males and females
maleData = combinedData(ismember(combinedData.Animal, maleAnimals), :);
femaleData = combinedData(ismember(combinedData.Animal, femaleAnimals), :);

%% Function to process each group (males/females)
function process_group(groupData, groupName, selectedPixelDifferenceColumn)
    % Filter out AO1-4 from the data for 'FullDark' and '300LuxEnd'
    groupData_AO5_8 = groupData(~(ismember(groupData.Animal, {'AO1', 'AO2', 'AO3', 'AO4'}) & ...
                                  ismember(groupData.Condition, {'FullDark', '300LuxEnd'})), :);
    
    % Print the size of the filtered dataset
    fprintf('%s data size after filtering: %d rows\n', groupName, height(groupData_AO5_8));
    
    % Aggregate the data to daily means
    dailyData_AO5_8 = aggregate_daily_means(groupData_AO5_8, selectedPixelDifferenceColumn);
    
    % Print unique conditions to verify
    disp(['Unique conditions in ', groupName, ' dataset:']);
    disp(unique(dailyData_AO5_8.Condition));
    
    % Calculate weekly averages
    weeklyData_AO5_8 = aggregate_weekly_means(dailyData_AO5_8);
    
    % Extract data for each condition
    data300Lux = weeklyData_AO5_8(strcmp(weeklyData_AO5_8.Condition, '300Lux'), :);
    data1000Lux = weeklyData_AO5_8(strcmp(weeklyData_AO5_8.Condition, '1000Lux'), :);
    dataFullDark = weeklyData_AO5_8(strcmp(weeklyData_AO5_8.Condition, 'FullDark'), :);
    data300LuxEnd = weeklyData_AO5_8(strcmp(weeklyData_AO5_8.Condition, '300LuxEnd'), :);

    %% Plotting: Weekly Averages for Each Condition
    conditions = {'300Lux', '1000Lux', 'FullDark', '300LuxEnd'};
    data = {data300Lux, data1000Lux, dataFullDark, data300LuxEnd};
    numWeeksPerCondition = [4, 4, 4, 1];  % Define the number of weeks per condition

    % Create bar plot
    figure;
    hold on;

    barOffset = 0;
    for i = 1:numel(conditions)
        numWeeks = numWeeksPerCondition(i);
        % Calculate means and standard errors for each week
        means = arrayfun(@(w) mean(data{i}.Mean_SelectedPixelDifference(data{i}.Week == w)), 1:numWeeks);
        stderrs = arrayfun(@(w) mean(data{i}.StdError(data{i}.Week == w)), 1:numWeeks);
        
        % Plot bars for each week
        for w = 1:numWeeks
            barIndex = barOffset + w;
            bar(barIndex, means(w));
            errorbar(barIndex, means(w), stderrs(w), 'k', 'LineStyle', 'none');
        end
        barOffset = barOffset + numWeeks;
    end

    % Generate the x-axis labels
    xTickLabels = repelem(conditions, numWeeksPerCondition);
    xTickPositions = 1:sum(numWeeksPerCondition);
    set(gca, 'XTick', xTickPositions, 'XTickLabel', xTickLabels, 'FontSize', 14, 'FontWeight', 'bold');
    
    % Labeling the y-axis and setting the title
    ylabel('Mean of Selected Pixel Difference', 'FontSize', 18, 'FontWeight', 'bold');
    title(sprintf('Weekly Average Comparison of Activity (%s)', groupName), 'FontSize', 20, 'FontWeight', 'bold');

    hold off;
end

%% Process data for males and females
process_group(maleData, 'Males', selectedPixelDifferenceColumn);
process_group(femaleData, 'Females', selectedPixelDifferenceColumn);

disp('Bar plots generated.');

%% Function Definitions
function aggregatedData = aggregate_daily_means(data, selectedPixelDifferenceColumn)
    % Print the size of the original dataset
    fprintf('Original data size: %d rows\n', height(data));

    % Floor the RelativeDay values to aggregate by integer days
    data.RelativeDay = floor(data.RelativeDay);

    % Print the unique RelativeDay values to ensure flooring worked
    disp('Unique RelativeDay values after flooring:');
    disp(unique(data.RelativeDay));

    % Aggregate the data to daily means
    aggregatedData = varfun(@mean, data, 'InputVariables', selectedPixelDifferenceColumn, 'GroupingVariables', {'Condition', 'Animal', 'RelativeDay'});
    
    % Verify column names before using them:
    meanColumnName = ['mean_' selectedPixelDifferenceColumn];
    if ismember(meanColumnName, aggregatedData.Properties.VariableNames)
        meanColumn = aggregatedData.(meanColumnName);
    else
        error('The column %s does not exist in aggregatedData.', meanColumnName);
    end

    stdError = varfun(@std, data, 'InputVariables', selectedPixelDifferenceColumn, 'GroupingVariables', {'Condition', 'Animal', 'RelativeDay'});
    stdErrorValues = stdError{:, ['std_' selectedPixelDifferenceColumn]} ./ sqrt(aggregatedData.GroupCount);

    % Create a new table with desired variables only
    aggregatedData = aggregatedData(:, {'Condition', 'Animal', 'RelativeDay'}); % Retain only relevant columns
    aggregatedData.Mean_SelectedPixelDifference = meanColumn;  % Add mean column
    aggregatedData.StdError = stdErrorValues;  % Add standard error column
    
    % Print the size of the aggregated dataset
    fprintf('Aggregated data size: %d rows\n', height(aggregatedData));
end

function aggregatedData = aggregate_weekly_means(dailyData)
    % Add a new column for Weeks
    dailyData.Week = ceil(dailyData.RelativeDay / 7);
    
    % Print the size of the original dataset
    fprintf('Original data size for weekly aggregation: %d rows\n', height(dailyData));

    % Aggregate the data to weekly means
    weeklyMeanData = varfun(@mean, dailyData, 'InputVariables', 'Mean_SelectedPixelDifference', 'GroupingVariables', {'Condition', 'Animal', 'Week'});
    weeklyStdData = varfun(@std, dailyData, 'InputVariables', 'Mean_SelectedPixelDifference', 'GroupingVariables', {'Condition', 'Animal', 'Week'});
    
    % Calculate standard error
    weeklyStdData.Properties.VariableNames{'std_Mean_SelectedPixelDifference'} = 'StdDev';
    weeklyMeanData.StdError = weeklyStdData.StdDev ./ sqrt(weeklyMeanData.GroupCount);
    
    % Rename the columns to reflect mean values
    weeklyMeanData.Properties.VariableNames{'mean_Mean_SelectedPixelDifference'} = 'Mean_SelectedPixelDifference';

    % Print the size of the aggregated dataset
    fprintf('Aggregated weekly data size: %d rows\n', height(weeklyMeanData));
    
    % Return the aggregated data
    aggregatedData = weeklyMeanData;
end