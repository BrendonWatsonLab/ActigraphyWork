%==========================================================================
% MASTER ACTIGRAPHY DATA PROCESSOR
%
% Description:
%   This script consolidates the entire data processing pipeline for the
%   Nile Grass Rat actigraphy project. It performs the following steps:
%   1. Reads raw CSV data for specified animals and conditions.
%   2. Combines, sorts, and converts time to EST and ZT.
%   3. Calculates RelativeDay for each animal within each condition.
%   4. Normalizes activity data using a specified condition and time window.
%   5. Bins the final data into specified time intervals.
%   6. Saves a single, clean CSV file ready for analysis.
%
% Author: Noah Muscat
% Date: June 19, 2025
%==========================================================================

clear; clc; close all;

%% ========================================================================
% --- (1) CONFIGURATION SECTION ---
% --- Customize all parameters here ---
% =========================================================================

% --- File and Path Parameters ---
% Root folder where raw data subfolders (e.g., 'AO1_300Lux') are located.
% This should point to a directory like '.../Cohort1Data' or a parent directory.
% The script will search for folders with the format 'Animal_Condition'.
config.rawDataSource = '/nfs/turbo/umms-brendonw/JeremyData/GrassRatAOActigResults';

% Folder where the final, processed CSV file will be saved.
config.outputFolder = '/nfs/turbo/umms-brendonw/JeremyData/GrassRatAOActigResults';
config.outputFileName = 'AO_Processed_Data.csv';

% --- Animal and Condition Parameters ---
% List of all animals to be included in the processing.
config.animals = {'AO9', 'AO10', 'AO11', 'AO12'};

% List of all possible conditions. The script will look for folders like
% 'AO1_300Lux', 'AO1_1000Lux', etc.
config.conditions = {'300Lux', '1000Lux', 'FullDark', '300LuxEnd'};

% --- Time and ZT Parameters ---
% Lights-on hour (ZT=0) in 'America/New_York' time (EST).
% This handles the EST/EDT shift automatically.
config.lightsOnHour = 6; % 6 AM

% --- Normalization Parameters ---
% The condition to use as the baseline for normalization.
config.normalizationCondition = '300Lux';

% The time window within the normalization condition to use for calculating
% the mean and standard deviation.
% Options: 'first7days', 'last7days'
config.normalizationWindow = 'last7days';

% --- Binning Parameters ---
% The time interval for binning the data, in minutes.
config.binningIntervalMinutes = 5;


%% ========================================================================
% --- (2) INITIAL DATA COMBINATION AND TIME CONVERSION ---
% --- Corresponds to your 'CombineSortZT.m' script ---
% =========================================================================
disp('--- Step 2: Starting Data Combination and Time Conversion ---');

allAnimalData = []; % Initialize an empty table to store all processed data

for i_animal = 1:length(config.animals)
    animalID = config.animals{i_animal};
    for i_condition = 1:length(config.conditions)
        conditionName = config.conditions{i_condition};
        
        % Construct the expected folder name for the raw data
        sourceFolderName = [animalID, '_', conditionName];
        sourceFolderPath = fullfile(config.rawDataSource, sourceFolderName);
        
        if ~isfolder(sourceFolderPath)
            % fprintf('INFO: Folder not found for %s. Skipping.\n', sourceFolderName);
            continue; % Skip if this animal-condition combo doesn't exist
        end
        
        fprintf('Processing folder: %s\n', sourceFolderName);
        
        % Get a list of all CSV files in the folder
        csvFiles = dir(fullfile(sourceFolderPath, '*.csv'));
        if isempty(csvFiles)
            fprintf('WARNING: No CSV files found in %s. Skipping.\n', sourceFolderName);
            continue;
        end
        
        % Read and concatenate data from all CSV files in the folder
        combinedData = [];
        for i_file = 1:length(csvFiles)
            try
                csvData = readtable(fullfile(sourceFolderPath, csvFiles(i_file).name));
                combinedData = [combinedData; csvData]; %#ok<AGROW>
            catch ME
                fprintf('WARNING: Could not read file %s. Error: %s. Skipping file.\n', csvFiles(i_file).name, ME.message);
            end
        end
        
        if isempty(combinedData)
            fprintf('WARNING: No data could be read for %s. Skipping.\n', sourceFolderName);
            continue;
        end
        
        % --- Data Cleaning and Time Conversion ---
        % Verify required columns exist
        if ~ismember('PositTime', combinedData.Properties.VariableNames) || ~ismember('SelectedPixelDifference', combinedData.Properties.VariableNames)
             fprintf('WARNING: Required columns missing in %s. Skipping.\n', sourceFolderName);
             continue;
        end

        % Remove unnecessary columns
        if ismember('Frame', combinedData.Properties.VariableNames)
            combinedData.Frame = [];
        end
        if ismember('RawDifference', combinedData.Properties.VariableNames)
            combinedData.RawDifference = [];
        end
         if ismember('RMSE', combinedData.Properties.VariableNames)
            combinedData.RMSE = [];
        end
        
        % Sort by time
        combinedData = sortrows(combinedData, 'PositTime');
        
        % Convert POSIX time to datetime objects
        positTime_seconds = combinedData.PositTime / 1000;
        positTime_utc = datetime(positTime_seconds, 'ConvertFrom', 'posixtime', 'TimeZone', 'UTC');
        
        % Convert to EST/EDT (America/New_York)
        DateEST = positTime_utc;
        DateEST.TimeZone = 'America/New_York';
        
        % Calculate ZT time
        lightsOnTime = hours(config.lightsOnHour);
        DateZT = DateEST - lightsOnTime;
        
        % Add Animal and Condition identifiers
        combinedData.Animal = repmat({animalID}, height(combinedData), 1);
        combinedData.Condition = repmat({conditionName}, height(combinedData), 1);
        
        % Replace original PositTime with our new datetime columns
        combinedData.PositTime = [];
        combinedData.DateEST = DateEST;
        combinedData.DateZT = DateZT;
        
        % Append to the master table
        allAnimalData = [allAnimalData; combinedData]; %#ok<AGROW>
    end
end

if isempty(allAnimalData)
    error('MasterProcessing:NoDataFound', 'No valid data was found in any of the specified folders. Halting script.');
end

disp('--- Step 2: Finished Combination and Time Conversion ---');


%% ========================================================================
% --- (3) RELATIVE DAY CALCULATION ---
% --- Corresponds to your 'RelativeDayCalculator.m' script ---
% =========================================================================
disp('--- Step 3: Starting Relative Day Calculation ---');

allAnimalData.RelativeDay = NaN(height(allAnimalData), 1);
uniqueGroups = unique(allAnimalData(:, {'Animal', 'Condition'}), 'rows');

for i_group = 1:height(uniqueGroups)
    animalID = uniqueGroups.Animal{i_group};
    conditionName = uniqueGroups.Condition{i_group};
    
    % Get indices for the current animal/condition group
    groupIndices = strcmp(allAnimalData.Animal, animalID) & strcmp(allAnimalData.Condition, conditionName);
    
    if any(groupIndices)
        groupData = allAnimalData(groupIndices, :);
        % Find the earliest date for this specific group
        minDate = min(groupData.DateEST);
        % Calculate relative days (days elapsed + 1)
        relativeDays = days(groupData.DateEST - minDate) + 1;
        % Assign back to the main table
        allAnimalData.RelativeDay(groupIndices) = relativeDays;
    end
end

disp('--- Step 3: Finished Relative Day Calculation ---');

%% ========================================================================
% --- (4) Z-SCORE NORMALIZATION ---
% --- Corresponds to your 'Normalize_Combine.m' script ---
% =========================================================================
disp('--- Step 4: Starting Z-Score Normalization ---');

allAnimalData.NormalizedActivity = NaN(height(allAnimalData), 1);

for i_animal = 1:length(config.animals)
    animalID = config.animals{i_animal};
    fprintf('  Normalizing data for animal: %s\n', animalID);
    
    % --- Part A: Get the normalization stats from the baseline condition ---
    
    % Filter data to get the baseline condition for the current animal
    normDataIndices = strcmp(allAnimalData.Animal, animalID) & ...
                      strcmp(allAnimalData.Condition, config.normalizationCondition);
                  
    if ~any(normDataIndices)
        fprintf('  WARNING: Normalization condition "%s" not found for %s. Cannot normalize this animal.\n', ...
                config.normalizationCondition, animalID);
        continue;
    end
    
    normData = allAnimalData(normDataIndices, :);
    
    % Select the time window for calculating stats
    switch config.normalizationWindow
        case 'first7days'
            minDay = min(normData.RelativeDay);
            windowIndices = normData.RelativeDay < (minDay + 7);
        case 'last7days'
            maxDay = max(normData.RelativeDay);
            windowIndices = normData.RelativeDay > (maxDay - 7);
        otherwise
            error('Invalid normalizationWindow. Choose "first7days" or "last7days".');
    end
    
    dataForStats = normData(windowIndices, :);
    
    if isempty(dataForStats)
        fprintf('  WARNING: No data in the specified normalization window for %s. Using all data from condition instead.\n', animalID);
        dataForStats = normData; % Fallback to all data in the condition
    end

    % Calculate mean and standard deviation
    mean_val = mean(dataForStats.SelectedPixelDifference, 'omitnan');
    std_val = std(dataForStats.SelectedPixelDifference, 'omitnan');
    
    if std_val == 0
        fprintf('  WARNING: Standard deviation is zero for %s. Z-scores will be NaN.\n', animalID);
        std_val = 1; % Avoid division by zero, will result in NaNs if mean is subtracted
    end
    
    % --- Part B: Apply normalization to ALL data for this animal ---
    animalIndices = strcmp(allAnimalData.Animal, animalID);
    allAnimalData.NormalizedActivity(animalIndices) = ...
        (allAnimalData.SelectedPixelDifference(animalIndices) - mean_val) / std_val;
end

disp('--- Step 4: Finished Z-Score Normalization ---');


%% ========================================================================
% --- (5) DATA BINNING AND FINAL COLUMN CREATION ---
% --- Corresponds to your 'Binner.m' script ---
% =========================================================================
disp('--- Step 5: Starting Data Binning ---');

% Use the 'Animal' and 'Condition' to group data for binning
[G, groupIDs] = findgroups(allAnimalData(:, {'Animal', 'Condition'}));

binnedData = [];
for i_group = 1:size(groupIDs, 1)
    
    % Get data for the current group
    groupIndices = (G == i_group);
    subTable = allAnimalData(groupIndices, :);
    
    % Convert to a timetable for binning
    subTT = table2timetable(subTable, 'RowTimes', 'DateEST');
    
    % Bin the data by the specified interval, taking the mean
    % 'retime' is excellent for this. It handles empty bins correctly.
    binnedTT = retime(subTT, 'minutes', config.binningIntervalMinutes, 'mean');
    
    % Convert back to a table
    binnedTable = timetable2table(binnedTT);
    
    % Append to the final binned data table
    binnedData = [binnedData; binnedTable]; %#ok<AGROW>
end

disp('--- Step 5: Finished Data Binning ---');


%% ========================================================================
% --- (6) FINAL CLEANUP AND SAVE ---
% =========================================================================
disp('--- Step 6: Finalizing and Saving Data ---');

% Add final helper columns based on the binned data
binnedData.ZT_Time = hour(binnedData.DateZT);
binnedData.DayOfCondition = floor(binnedData.RelativeDay); % As requested

% Remove any rows with NaN in key columns after binning
binnedData = rmmissing(binnedData, 'DataVariables', {'SelectedPixelDifference', 'RelativeDay'});

% Reorder columns to match your analysis scripts
finalColumns = {'SelectedPixelDifference', 'NormalizedActivity', 'Animal', ...
                'Condition', 'RelativeDay', 'DateZT', 'DateEST', 'ZT_Time', 'DayOfCondition'};
finalDataTable = binnedData(:, finalColumns);

% Save the final table to a CSV file
outputFilePath = fullfile(config.outputFolder, config.outputFileName);
if ~isfolder(config.outputFolder)
    mkdir(config.outputFolder);
    fprintf('Created output directory: %s\n', config.outputFolder);
end

writetable(finalDataTable, outputFilePath);

fprintf('\nSUCCESS! Processing complete.\n');
fprintf('Final combined and binned data saved to: %s\n', outputFilePath);

disp('--- All Done ---');