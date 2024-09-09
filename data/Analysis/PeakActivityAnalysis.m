% List of rat IDs and conditions
ratIDs = {'Rollo', 'Canute', 'Harald', 'Gunnar', 'Egil', 'Sigurd', 'Olaf'}; % Add more rat IDs as needed
conditions = {'300Lux', '1000Lux1', '1000Lux4'};

dataDir = '/home/noahmu/Documents/JeremyData/ZT'; % Ensure this path is correct
normalizedActivity = struct();

% Normalize condition names to be valid field names
validConditionNames = strcat('Cond_', conditions);

% Loop over each rat and condition
for i = 1:length(ratIDs)
    ratID = ratIDs{i};
    
    for j = 1:length(conditions)
        condition = conditions{j};
        validCondition = validConditionNames{j};
        
        % Construct the filename
        filename = sprintf('%s_%s_ZT.csv', ratID, condition); % Adjust filename based on your pattern
        fullPath = fullfile(dataDir, ratID, filename);
        
        % Check if the file exists
        if isfile(fullPath)
            % Load the data from the CSV file using readtable
            fprintf('Analyzing: %s\n', fullPath);
            dataTable = readtable(fullPath);
            
            % Assuming the data includes a 'Date' column in datetime format and a 'SelectedPixelDifference' column
            if ismember('Date', dataTable.Properties.VariableNames) && ismember('SelectedPixelDifference', dataTable.Properties.VariableNames)
                dateData = dataTable.Date; % Datetime data
                activityData = dataTable.SelectedPixelDifference;
                
                % Extract hour from datetime data
                hours = hour(dateData);
                
                % Bin data by hour (1-hour bins)
                edges = 0:24; % Correct edges to include 24 for completeness
                binIndices = discretize(hours, edges);
                
                % Remove NaN and zero indices
                validIndices = binIndices > 0;
                binIndices = binIndices(validIndices);
                activityData = activityData(validIndices);
                
                % Calculate sum of activity for each bin
                binnedActivity = accumarray(binIndices, activityData, [24, 1], @sum, NaN);
                
                % Calculate z-score normalization for the binned activity
                meanActivity = mean(binnedActivity, 'omitnan');
                stdActivity = std(binnedActivity, 'omitnan');
                
                if stdActivity == 0
                    zscoredActivity = zeros(size(binnedActivity)); % Avoid division by zero
                else
                    zscoredActivity = (binnedActivity - meanActivity) / stdActivity;
                end
                
                % Store results for each animal and condition
                normalizedActivity.(ratID).(validCondition).binnedActivity = zscoredActivity;
            else
                fprintf('Column "Date" or "SelectedPixelDifference" not found in file: %s\n', fullPath);
            end
        else
            fprintf('File not found: %s\n', fullPath);  % Log missing files
        end
    end
end

% Graphical representation of normalized activity
figure;
hold on;

% Plot all conditions together for comparison
colors = lines(length(conditions));
legendEntries = {};

for j = 1:length(validConditionNames)
    validCondition = validConditionNames{j};
    
    for i = 1:length(ratIDs)
        ratID = ratIDs{i};
        
        if isfield(normalizedActivity, ratID) && isfield(normalizedActivity.(ratID), validCondition)
            binnedActivity = normalizedActivity.(ratID).(validCondition).binnedActivity;
            
            % Plot each rat's z-score normalized activity data
            plot(0:23, binnedActivity, 'DisplayName', sprintf('%s - %s', ratID, conditions{j}), 'Color', colors(j, :));
            hold on;
            
            legendEntries{end+1} = sprintf('%s - %s', ratID, conditions{j});
        end 
     end
end


xlabel('Hour of the Day');
ylabel('Normalized Activity (z-score)');
title('Z-score Normalized Activity Over 24 Hours for Each Animal and Condition');
legend(legendEntries, 'Location', 'BestOutside');
hold off;

% Save the figure if necessary
saveas(gcf, fullfile(dataDir, 'Normalized_Activity_Per_Hour.png'));

disp('Z-score normalized activity analysis and plots generated and saved.');

%% Using 7-day 300 Lux Normalization to generate new csv
rootFolder = '/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ZT';

rats = {'Rollo', 'Canute', 'Egil', 'Olaf', 'Harald', 'Gunnar', 'Sigurd'};
conditions = {'300Lux', '1000Lux1', '1000Lux4'};

% Initialize a table to store the combined normalized data with predefined column names
combined_data = table('Size', [0, 5], ...
                      'VariableTypes', {'double', 'double', 'cell', 'cell', 'datetime'}, ...
                      'VariableNames', {'SelectedPixelDifference', 'NormalizedActivity', 'Rat', 'Condition', 'Date'});

for r = 1:length(rats)
    rat = rats{r};
    ratFolder = fullfile(rootFolder, rat);
    
    fprintf('Processing data for rat: %s\n', rat);
    
    % Initialize variables to store 300Lux data for this rat
    selectedPixelDiff_300Lux = [];
    
    % Load the 300Lux data first to compute mean and std
    file_300Lux = fullfile(ratFolder, [rat '_300Lux_ZT.csv']);
    if ~isfile(file_300Lux)
        fprintf('300Lux data file not found for rat: %s. Skipping this rat.\n', rat);
        continue;  % Skip this rat if the 300Lux file does not exist
    end
    fprintf('Loading 300Lux data from: %s\n', file_300Lux);
    ratData_300Lux = readtable(file_300Lux);
    selectedPixelDiff_300Lux = ratData_300Lux.SelectedPixelDifference;
    
    % Calculate mean and std for 300Lux condition
    mean_300Lux = mean(selectedPixelDiff_300Lux);
    std_300Lux = std(selectedPixelDiff_300Lux);
    fprintf('Calculated mean = %.2f, std = %.2f for 300Lux condition of rat: %s\n', mean_300Lux, std_300Lux, rat);
    
    % Now normalize and combine all conditions for this rat
    for c = 1:length(conditions)
        condition = conditions{c};
        file_condition = fullfile(ratFolder, [rat '_' condition '_ZT.csv']);
        
        if ~isfile(file_condition)
            fprintf('%s data file not found for rat: %s. Skipping this condition.\n', condition, rat);
            continue;  % Skip this condition if the file does not exist
        end
        
        fprintf('Loading %s data from: %s\n', condition, file_condition);
        ratData_condition = readtable(file_condition);
        
        % Normalize the SelectedPixelDifference column using the 300Lux mean and std
        ratData_condition.NormalizedActivity = (ratData_condition.SelectedPixelDifference - mean_300Lux) / std_300Lux;
        fprintf('Normalized %s data for rat: %s\n', condition, rat);
        
        % Add columns for rat name and condition
        ratData_condition.Rat = repmat({rat}, height(ratData_condition), 1);
        ratData_condition.Condition = repmat({condition}, height(ratData_condition), 1);
        
        % Ensure the table has correct columns before concatenation
        ratData_condition = ratData_condition(:, {'SelectedPixelDifference', 'NormalizedActivity', 'Rat', 'Condition', 'Date'});
        
        % Append to the combined data table
        combined_data = [combined_data; ratData_condition]; %#ok<AGROW>
    end
end

% Output the combined normalized data to a CSV file
outputFile = fullfile(rootFolder, 'Combined_Normalized_Data.csv');
writetable(combined_data, outputFile);
fprintf('Combined normalized data saved to: %s\n', outputFile);

%% Plotting

% Load the combined CSV file
fprintf('Loading combined data file...\n');
combinedFile = fullfile(rootFolder, 'Combined_Normalized_Data.csv');
combined_data = readtable(combinedFile);

% Convert 'Date' to datetime format if it's not already
if ~isdatetime(combined_data.Date)
    fprintf('Converting Date column to datetime format...\n');
    combined_data.Date = datetime(combined_data.Date, 'InputFormat', 'yyyy-MM-dd');
end

% Calculate the relative day for each rat and condition
fprintf('Calculating relative days for each rat and condition...\n');
combined_data.RelativeDay = zeros(height(combined_data), 1);

rats = unique(combined_data.Rat);
conditions = unique(combined_data.Condition);

for r = 1:length(rats)
    rat = rats{r};
    for c = 1:length(conditions)
        condition = conditions{c};
        
        ratConditionData = combined_data(strcmp(combined_data.Rat, rat) & strcmp(combined_data.Condition, condition), :);
        
        if isempty(ratConditionData)
            continue; % Skip if there is no data for this rat and condition
        end
        
        % Find the earliest date for this rat and condition
        minDate = min(ratConditionData.Date);
        
        % Calculate relative days
        for d = 1:height(ratConditionData)
            dateDiff = days(ratConditionData.Date(d) - minDate) + 1;
            combined_data.RelativeDay(strcmp(combined_data.Rat, rat) & strcmp(combined_data.Condition, condition) & (combined_data.Date == ratConditionData.Date(d))) = dateDiff;
        end
    end
end

% Save the modified data with RelativeDay to a new CSV file
outputModifiedFile = fullfile(rootFolder, 'Combined_Normalized_Data_With_RelativeDays.csv');
fprintf('Saving the modified data with RelativeDay to: %s\n', outputModifiedFile);
writetable(combined_data, outputModifiedFile);

% Now, aggregate and average the data by relative day and condition
fprintf('Aggregating and averaging data by relative day and condition...\n');
allData = [];
conditionDayLabels = [];

for c = 1:length(conditions)
    condition = conditions{c};
    for day = 1:7 % Maximum of 7 days per condition
        dayData = combined_data(strcmp(combined_data.Condition, condition) & combined_data.RelativeDay == day, :);
        
        if isempty(dayData)
            continue; % Skip if there is no data for this day and condition
        end
        
        meanNormalizedActivity = mean(dayData.NormalizedActivity);
        stdError = std(dayData.NormalizedActivity) / sqrt(height(dayData));
        
        % Append to result arrays
        allData = [allData; {condition, day, meanNormalizedActivity, stdError}];
        conditionDayLabels = [conditionDayLabels; sprintf('%s Day %d', condition, day)];
        
        fprintf('  Condition: %s, Day: %d, MeanNormalizedActivity: %.2f, StdError: %.2f\n', ...
                condition, day, meanNormalizedActivity, stdError);
    end
end

% Convert to table for easier plotting
allDataTable = cell2table(allData, 'VariableNames', {'Condition', 'Day', 'MeanNormalizedActivity', 'StdError'});

% Prepare x-axis labels
xAxisLabels = unique(conditionDayLabels, 'stable');

% Plotting
fprintf('Generating plot...\n');
figure;
hold on;

colors = {'b', 'r', 'g'}; % Different colors for different conditions

for conditionIndex = 1:length(conditions)
    condition = conditions{conditionIndex};
    
    % Filter data by condition
    conditionData = allDataTable(strcmp(allDataTable.Condition, condition), :);
    
    % Determine x positions based on the sequential days across all conditions
    conditionDayIndices = find(strcmp(conditionDayLabels, conditionData.Condition));
    
    % Plot with error bars
    errorbar(conditionDayIndices, conditionData.MeanNormalizedActivity, conditionData.StdError, ...
             'DisplayName', condition, 'Color', colors{conditionIndex}, 'LineWidth', 1.5);
end

% Customize plot
set(gca, 'XTick', 1:length(xAxisLabels), 'XTickLabel', xAxisLabels);
xlabel('Day and Condition');
ylabel('Mean Normalized Activity');
title('Mean Normalized Activity with Error Bars by Day and Condition');
legend('Location', 'Best');
grid on;
hold off;

fprintf('Plot generated successfully.\n');

%% Function to normalize data
function normalizedValues = normalizeData(data, mean_300lux, std_300lux)
    normalizedValues = (data - mean_300lux) / std_300lux;
end