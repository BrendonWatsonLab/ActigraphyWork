data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyOnly/AOActivityData.csv');

% Define gender groups
maleAnimals = {'AO1', 'AO2', 'AO3', 'AO7'};
femaleAnimals = {'AO4', 'AO5', 'AO6', 'AO8'};

% Define conditions in desired order
conditions = {'300Lux', '1000Lux', 'FullDark', '300LuxEnd'};

% Initialize variables to store results
means = struct();
stdErrors = struct();

% Convert DateZT to datetime for easier manipulation
data.DateZT = datetime(data.DateZT, 'InputFormat', 'MM/dd/yy HH:mm');

% Loop through genders
for g = {'male', 'female'}
    gender = g{1};
    
    % Determine which animals are of the current gender
    if strcmp(gender, 'male')
        animals = maleAnimals;
    else
        animals = femaleAnimals;
    end
    
    means.(gender) = [];
    stdErrors.(gender) = [];
    labels = {};
    
    % Loop through each condition
    for condIdx = 1:length(conditions)
        condition = conditions{condIdx};
        
        % Filter data by condition and gender
        genderData = data(ismember(data.Animal, animals) & strcmp(data.Condition, condition), :);
        
        % Get the last date for this condition
        lastDate = max(genderData.DateZT);
        
        % Calculate "week number" based on reverse order
        genderData.WeekNumber = ceil(days(lastDate - genderData.DateZT) / 7) + 1;
        
        % Get unique week numbers in reverse order
        uniqueWeeks = unique(genderData.WeekNumber, 'stable');
        
        % Reverse the uniqueWeeks to start from week 1 at the last 7 days
        uniqueWeeks = flip(uniqueWeeks);
        
        % Loop through each week
        for weekIdx = 1:length(uniqueWeeks)
            week = uniqueWeeks(weekIdx);
            
            % Get data for the current week
            weekData = genderData(genderData.WeekNumber == week, :);
            
            % Calculate mean and standard error
            meanValue = mean(weekData.NormalizedActivity);
            stdErrorValue = std(weekData.NormalizedActivity) / sqrt(height(weekData));
            
            % Store the results
            means.(gender) = [means.(gender), meanValue];
            stdErrors.(gender) = [stdErrors.(gender), stdErrorValue];
            
            % Store label
            labels{end+1} = sprintf('%s:Wk%d', condition, weekIdx);
        end
    end
    
    % Plotting for the current gender
    figure;
    hold on;
    bar(means.(gender), 'FaceColor', gender(1)); % use 'm' or 'f' as the color
    errorbar(1:length(means.(gender)), means.(gender), stdErrors.(gender), 'k', 'LineStyle', 'none');
    
    % Set axis labels and title
    xticks(1:length(labels));
    xticklabels(labels);
    xlabel('Condition:Week');
    ylabel('Mean Normalized Activity');
    title(sprintf('Mean Normalized Activity by Condition and Week for %s', gender));
    hold off;
end

%% other logic
% Read the data from the CSV file
combinedData = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyOnly/AOActivityData.csv');

% Display the column names to verify
disp('Column names in the data:');
disp(combinedData.Properties.VariableNames);

% The correct column name for SelectedPixelDifference
selectedPixelDifferenceColumn = 'NormalizedActivity';

% Define male and female animals
maleAnimals = {'AO1', 'AO2', 'AO3', 'AO7'};
femaleAnimals = {'AO4', 'AO5', 'AO6', 'AO8'};

% Separate the data into males and females
maleData = combinedData(ismember(combinedData.Animal, maleAnimals), :);
femaleData = combinedData(ismember(combinedData.Animal, femaleAnimals), :);

process_group(maleData, 'Males', selectedPixelDifferenceColumn);
process_group(femaleData, 'Females', selectedPixelDifferenceColumn);

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
