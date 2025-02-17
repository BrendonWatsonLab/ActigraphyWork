sourceDirectory = '/data/Jeremy/Grass Rat Data/ActigraphyOnly_GR_Videos/Cohort2';
destinationDirectory = '/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/Cohort2DARKSleepDep';
animalNames = {'AO5', 'AO6', 'AO7', 'AO8'};

copySelectedMp4Files(sourceDirectory, destinationDirectory, animalNames);

%% First, combining

% Define the root folder and other parameters
rootFolder = '/home/noahmu/Documents/JeremyDataLocal';  % Change this to your data folder path
animals_new = {'AO5', 'AO6', 'AO7', 'AO8'};

% Dates for condition switches
fullDark_start = datetime('2024-09-06 18:00:00', 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
fullDark_end = datetime('2024-10-11 06:00:00', 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
lux_300_end_start = datetime('2024-10-11 06:00:01', 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
lux_300_end_end = datetime('2024-10-18 06:00:00', 'InputFormat', 'yyyy-MM-dd HH:mm:ss');

% Load the existing data
disp('Loading existing data...');
existingData = readtable(fullfile(rootFolder, 'binned_data.csv'));

% Fix the Date column to be datetime format
disp('Checking and converting Date column in existing data...');
if ~isdatetime(existingData.Date)
    existingData.Date = datetime(existingData.Date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSSSSS');
end

% Ensure the correct structure of existing data
disp('Ensuring existing data has the correct columns...');
if ~all(ismember({'Date', 'SelectedPixelDifference', 'NormalizedActivity', 'Animal', 'Condition', 'RelativeDay'}, existingData.Properties.VariableNames))
    error('Existing data does not have the required columns');
end

% Load raw data files for animals AO5-8
disp('Loading new data for animals AO5-AO8...');
newData_AO5 = readtable(fullfile(rootFolder, 'AO5_combined_data.csv'));
newData_AO6 = readtable(fullfile(rootFolder, 'AO6_combined_data.csv'));
newData_AO7 = readtable(fullfile(rootFolder, 'AO7_combined_data.csv'));
newData_AO8 = readtable(fullfile(rootFolder, 'AO8_combined_data.csv'));

% Convert 'Date' fields to datetime objects for new data
disp('Converting Date columns in new data...');
newData_AO5.Date = datetime(newData_AO5.Date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSSSSS');
newData_AO6.Date = datetime(newData_AO6.Date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSSSSS');
newData_AO7.Date = datetime(newData_AO7.Date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSSSSS');
newData_AO8.Date = datetime(newData_AO8.Date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSSSSS');

% Initialize cell arrays to hold new data
disp('Initializing data storage for new data...');
newData = {newData_AO5, newData_AO6, newData_AO7, newData_AO8};

%% Normalize and bin data for each animal
combinedNewData = table(); % Initialize an empty table to hold all new data
for i = 1:length(animals_new)
    animal = animals_new{i};
    disp(['Processing data for ', animal, '...']);
    new_data = newData{i};
    
    % Extract the initial 7-day 300Lux data for the animal
    disp('Extracting initial 7-day 300Lux data...');
    initial_300Lux_data = existingData(strcmp(existingData.Animal, animal) & ...
                                       strcmp(existingData.Condition, '300Lux') & ...
                                       existingData.RelativeDay <= 7, :);
    
    % Calculate mean and std for the first 7 days of the 300Lux condition
    disp('Calculating mean and std for the first 7 days of 300Lux data...');
    mean_300Lux = mean(initial_300Lux_data.SelectedPixelDifference);
    std_300Lux = std(initial_300Lux_data.SelectedPixelDifference);
    
    % Normalize the new raw data
    disp('Normalizing new raw data...');
    new_data.NormalizedActivity = (new_data.SelectedPixelDifference - mean_300Lux) / std_300Lux;
    
    % Binning (average into 5-minute intervals)
    disp('Binning data into 5-minute intervals...');
    bin_duration = minutes(5);
    new_data_binned = retime(timetable(new_data.Date, new_data.SelectedPixelDifference, new_data.NormalizedActivity), ...
                             'regular', 'mean', 'TimeStep', bin_duration);

    % Debugging output for column names after retime
    disp('Columns after retime:');
    disp(new_data_binned.Properties.VariableNames);
    
    % Fill NaN values in binned data
    disp('Handling NaN values...');
    new_data_binned = fillmissing(new_data_binned, 'nearest');  % or use 'previous' or 'next'

    % Convert timetable to table and retain column names
    disp('Converting binned data from timetable to table...');
    new_data_binned = timetable2table(new_data_binned);
    
    % Rename appropriately based on observed column names after retiming
    new_data_binned.Properties.VariableNames{'Time'} = 'Date'; 
    new_data_binned.Properties.VariableNames{'Var1'} = 'SelectedPixelDifference';
    new_data_binned.Properties.VariableNames{'Var2'} = 'NormalizedActivity';
    
    % Add remaining columns (Animal, Condition)
    new_data_binned.Animal = repmat({animal}, height(new_data_binned), 1);
    
    % Assign condition based on date ranges for FullDark and 300LuxEnd
    disp('Assigning conditions based on date ranges...');
    new_data_binned.Condition = repmat({''}, height(new_data_binned), 1);  % Initialize
    
    % FullDark condition
    fullDark_indices = (new_data_binned.Date >= fullDark_start) & (new_data_binned.Date < fullDark_end);
    new_data_binned.Condition(fullDark_indices) = {'FullDark'};
    
    % 300LuxEnd condition
    lux_300_end_indices = (new_data_binned.Date >= lux_300_end_start) & (new_data_binned.Date < lux_300_end_end);
    new_data_binned.Condition(lux_300_end_indices) = {'300LuxEnd'};
    
    % Filter out rows with empty conditions (i.e., outside specified ranges)
    disp('Filtering out rows with empty conditions...');
    new_data_binned = new_data_binned(~cellfun(@isempty, new_data_binned.Condition), :);
    
    % Create final table with required columns
    disp('Creating final table for this animal...');
    new_data_binned = new_data_binned(:, {'Date', 'SelectedPixelDifference', 'NormalizedActivity', 'Animal', 'Condition'});
    
    % Save to combinedNewData for combination later
    disp(['Saving processed data for ', animal, '...']);
    combinedNewData = [combinedNewData; new_data_binned];
end

% Ensure combined new data has the required column 'RelativeDay' in the correct order
combinedNewData.RelativeDay = zeros(height(combinedNewData), 1);  % Add a column of zeros for RelativeDay

% Reorder columns to match existingData order before combining
combinedNewData = combinedNewData(:, existingData.Properties.VariableNames);

% Print combinedNewData column names for debugging
disp('New data column names:');
disp(combinedNewData.Properties.VariableNames);

% Combine new data with existing data
disp('Combining new data with existing data...');
assert(isequal(existingData.Properties.VariableNames, combinedNewData.Properties.VariableNames), ...
    'Mismatch in table variables between existing and new data');
combinedData = vertcat(existingData, combinedNewData);

% Sort combined data by Date
disp('Sorting combined data by Date...');
combinedData = sortrows(combinedData, 'Date');

% Calculate RelativeDay for each animal and condition
disp('Calculating relative days...');
animals = unique(combinedData.Animal);
conditions = unique(combinedData.Condition);

for a = 1:length(animals)
    animal = animals{a};
    disp(['Processing relative days for ', animal, '...']);
    for c = 1:length(conditions)
        condition = conditions{c};
        disp(['  Processing condition: ', condition, '...']);
        animalConditionData = combinedData(strcmp(combinedData.Animal, animal) & strcmp(combinedData.Condition, condition), :);
        
        if isempty(animalConditionData)
            disp('    No data available for this animal and condition. Skipping...');
            continue;  % Skip if there is no data for this animal and condition
        end

        % Find the earliest date for this animal and condition
        minDate = min(animalConditionData.Date);

        % Calculate relative days
        relativeDays = days(animalConditionData.Date - minDate) + 1;

        % Update the combined_data 'RelativeDay' column
        indices = strcmp(combinedData.Animal, animal) & strcmp(combinedData.Condition, condition);
        combinedData.RelativeDay(indices) = relativeDays;

        disp('    Completed relative day calculation for this condition.');
    end
end

% Save the updated combined data
outputFile = fullfile(rootFolder, 'updated_data_with_relative_days.csv');
disp(['Saving the modified data with RelativeDay to: ', outputFile]);
writetable(combinedData, outputFile);

disp('Processing complete.');

%% Function
function copySelectedMp4Files(sourceDir, destDir, animalNames)
    % Ensure directories end with the file separator
    if sourceDir(end) ~= filesep
        sourceDir = [sourceDir, filesep];
    end
    if destDir(end) ~= filesep
        destDir = [destDir, filesep];
    end

    % Make destination directory if it does not exist
    if ~exist(destDir, 'dir')
        mkdir(destDir);
    end

    % Define the cut-off datetime
    cutoffDateTime = datetime('2024-09-06 18:00:00', 'InputFormat', 'yyyy-MM-dd HH:mm:ss');

    % Loop for each animal
    for k = 1:length(animalNames)
        animal = animalNames{k}; % Extract the actual string
        
        % Get the source directory for this animal
        animalSourceDir = fullfile(sourceDir, animal);
        
        % Get list of .mp4 files in the source directory for this animal
        files = dir(fullfile(animalSourceDir, '*.mp4'));

        % Create animal-specific subdirectory in the destination if not exists
        animalDestDir = fullfile(destDir, animal);
        if ~exist(animalDestDir, 'dir')
            mkdir(animalDestDir);
        end

        % Loop through each file and check if it matches the criteria
        for i = 1:length(files)
            fileName = files(i).name;
            % Extract the datetime part of the filename
            dateTimeStr = fileName(length(animal) + 2 : length(animal) + 20); % Adjust indexing

            try
                % Convert to datetime object
                fileDateTime = datetime(dateTimeStr, 'InputFormat', 'yyyyMMdd_HH-mm-ss.SSS');
                
                % Check if the datetime is on or after the cutoff
                if fileDateTime >= cutoffDateTime
                    % Copy the file to the destination directory
                    copyfile(fullfile(animalSourceDir, fileName), fullfile(animalDestDir, fileName));
                end
            catch
                % If there's an issue with the datetime conversion, skip the file
                warning('Skipping file: %s due to unexpected format', fileName);
                continue;
            end
        end
    end

    disp('File copying operation completed.');
end
