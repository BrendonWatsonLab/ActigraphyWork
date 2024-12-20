% Analysis for AO5-8, including dark conditions. This improves upon the original approach by
% aggregating data into daily means to avoid skewing caused by the large dataset,
% providing more meaningful statistics.

%% starting
fprintf('Combining and Normalizing Data\n');

% Read the data from the CSV file
combinedData = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/AOCohortData.csv');

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

%% Function to process each group (males/females)
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
    numWeeks = 4; % Assuming 4 weeks per condition

    % Create bar plot
    figure;
    hold on;

    for i = 1:numel(conditions)
        % Calculate means and standard errors for each week
        means = arrayfun(@(w) mean(data{i}.Mean_NormalizedActivity(data{i}.Week == w)), 1:numWeeks);
        stderrs = arrayfun(@(w) mean(data{i}.StdError(data{i}.Week == w)), 1:numWeeks);
        
        % Plot bars for each week
        for w = 1:numWeeks
            bar((i-1)*numWeeks + w, means(w));
            errorbar((i-1)*numWeeks + w, means(w), stderrs(w), 'k', 'LineStyle', 'none');
        end
    end

    % Add significance stars if needed
    % Note: You need an updated statistical analysis for weekly comparisons here

    set(gca, 'XTickLabel', repelem(conditions, numWeeks), 'XTick', 1:numWeeks*numel(conditions), 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Normalized Activity (z-score)', 'FontSize', 18, 'FontWeight', 'bold');
    title(sprintf('Weekly Average Comparison of Activity (%s)', groupName), 'FontSize', 20, 'FontWeight', 'bold');
    hold off;
end

%% Process data for males and females
process_group(maleData, 'Males', normalizedActivityColumn);
process_group(femaleData, 'Females', normalizedActivityColumn);

disp('Bar plots generated.');

%% Function Definitions
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

function aggregatedData = aggregate_weekly_means(dailyData)
    % Add a new column for Weeks
    dailyData.Week = ceil(dailyData.RelativeDay / 7);
    
    % Print the size of the original dataset
    fprintf('Original data size for weekly aggregation: %d rows\n', height(dailyData));

    % Aggregate the data to weekly means
    weeklyMeanData = varfun(@mean, dailyData, 'InputVariables', 'Mean_NormalizedActivity', 'GroupingVariables', {'Condition', 'Animal', 'Week'});
    weeklyStdData = varfun(@std, dailyData, 'InputVariables', 'Mean_NormalizedActivity', 'GroupingVariables', {'Condition', 'Animal', 'Week'});
    
    % Calculate standard error
    weeklyStdData.Properties.VariableNames{'std_Mean_NormalizedActivity'} = 'StdDev';
    weeklyMeanData.StdError = weeklyStdData.StdDev ./ sqrt(weeklyMeanData.GroupCount);
    
    % Rename the columns to reflect mean values
    weeklyMeanData.Properties.VariableNames{'mean_Mean_NormalizedActivity'} = 'Mean_NormalizedActivity';

    % Print the size of the aggregated dataset
    fprintf('Aggregated weekly data size: %d rows\n', height(weeklyMeanData));
    
    % Return the aggregated data
    aggregatedData = weeklyMeanData;
end