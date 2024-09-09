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
rootFolder = '/home/noahmu/Documents/JeremyData/ZT';
% Define folder structure
lightingConditions = {'300Lux', '1000LuxWeek1', '1000LuxWeek4'};
validFieldNames = {'Lux300', 'Lux1000Week1', 'Lux1000Week4'};

% Initialize a table to store all the normalized data across all animals
combinedNormalizedData = table();

% Iterate over each animal's folder
animalFolders = dir(rootFolder);
for i = 1:length(animalFolders)
    if animalFolders(i).isdir && ~strcmp(animalFolders(i).name, '.') && ~strcmp(animalFolders(i).name, '..')
        animalPath = fullfile(rootFolder, animalFolders(i).name);
        files = dir(fullfile(animalPath, '*.csv'));
        dataByCondition = struct();
        
        % Load all CSV files for the current animal
        for j = 1:length(files)
            filePath = fullfile(animalPath, files(j).name);
            data = readtable(filePath);
            
            % Extract the lighting condition from the file name
            for k = 1:length(lightingConditions)
                if contains(lower(files(j).name), lower(lightingConditions{k}))
                    dataByCondition.(validFieldNames{k}) = data;
                    break;
                end
            end
        end
        
        % Normalize data based on the 300 lux condition
        if isfield(dataByCondition, 'Lux300')
            avg_300lux = dataByCondition.('Lux300').SelectedPixelDifference;
            mean_300lux = mean(avg_300lux);
            std_300lux = std(avg_300lux);
            
            animalNormalizedData = table();
            conditions = fieldnames(dataByCondition);
            for k = 1:length(conditions)
                dataByCondition.(conditions{k}).NormalizedSelectedPixelDifference = normalizeData(...
                    dataByCondition.(conditions{k}).SelectedPixelDifference, mean_300lux, std_300lux ...
                );
                dataByCondition.(conditions{k}).Animal = repmat({animalFolders(i).name}, height(dataByCondition.(conditions{k})), 1);
                dataByCondition.(conditions{k}).Condition = repmat(lightingConditions{k}, height(dataByCondition.(conditions{k})), 1);
                
                % Store normalized data for the current animal
                animalNormalizedData = [animalNormalizedData; dataByCondition.(conditions{k})(:, {'Date', 'NormalizedSelectedPixelDifference', 'Animal', 'Condition'})]; %#ok<AGROW>
            end
            
            % Export normalized data for the current animal to CSV
            writetable(animalNormalizedData, fullfile(animalPath, 'normalized_data.csv'));
            
            % Append current animal's data to the combined table
            combinedNormalizedData = [combinedNormalizedData; animalNormalizedData]; %#ok<AGROW>
        end
    end
end

writetable(combinedNormalizedData, fullfile(rootFolder, 'total_normalized_data.csv'));

%% Plotting
% Loading and Preprocessing Data
disp('Loading data...');
data = readtable('total_normalized_data.csv'); % replace 'yourfile.csv' with the actual file name

disp('Ensuring Date column is in datetime format...');
% Ensure the 'Date' column is in datetime format and extract the date part
data.Date = datetime(data.Date, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS');

disp('Extracting date part and ignoring the time...');
% Extract only the date part (ignoring the time)
data.DateOnly = dateshift(data.Date, 'start', 'day');

% Find unique conditions
conditions = unique(data.Condition);
numConditions = length(conditions);

% Initialize a new table to store processed data
processedData = data;
processedData.Day = zeros(height(data), 1); % Initialize the 'Day' column to zero

% Print update
fprintf('Processing each condition (Total conditions: %d)...\n', numConditions);

% Processing Each Condition Separately to Update Day Column
for i = 1:numConditions
    condition = conditions{i};
    fprintf('Processing condition %d/%d: %s\n', i, numConditions, condition);
    
    conditionIdx = strcmp(data.Condition, condition);
    
    % Find the unique dates for this condition
    uniqueDates = unique(data.DateOnly(conditionIdx));
    numDates = length(uniqueDates);
    
    % Map the original days to a sequential day for this condition
    dayMap = containers.Map(cellstr(uniqueDates), 1:numDates);
    
    % Update the Day column in the processed data table
    for j = 1:numDates
        dateKey = char(uniqueDates(j));
        dateIdx = strcmp(cellstr(data.DateOnly), dateKey) & conditionIdx;
        processedData.Day(dateIdx) = dayMap(dateKey);
    end
end

disp('Saving processed data to CSV...');
writetable(processedData, fullfile('/home/noahmu/Documents/JeremyData/ZT', 'daily_processed_combined_data.csv'));

% Calculating Averages
disp('Calculating averages...');
% Calculate the average NormalizedSelectedPixelDifference for each condition and day
avgData = varfun(@mean, processedData, 'InputVariables', 'NormalizedSelectedPixelDifference', ...
    'GroupingVariables', {'Condition', 'Day'});

disp('Preparing data for plotting...');
% Convert the result to a format suitable for plotting
conditions = unique(avgData.Condition);
colors = lines(length(conditions)); % Different colors for each condition for better visualization

figure;
hold on;

% Print update
fprintf('Plotting data for each condition...\n');

% Plot data for each condition
for i = 1:length(conditions)
    condition = conditions{i};
    conditionData = avgData(strcmp(avgData.Condition, condition), :);
    plot(conditionData.Day, conditionData.mean_NormalizedSelectedPixelDifference, ...
        '-o', 'DisplayName', condition, 'Color', colors(i, :));
end

% Customizing the Plot
disp('Customizing the plot...');
xlabel('Day');
ylabel('Average Normalized Selected Pixel Difference');
title('Average Normalized Selected Pixel Difference by Lighting Condition and Day');
legend('show');
grid on;
hold off;

disp('Finished!');

%% testing
datatatata = readtable('total_normalized_data.csv');

%% Function to normalize data
function normalizedValues = normalizeData(data, mean_300lux, std_300lux)
    normalizedValues = (data - mean_300lux) / std_300lux;
end