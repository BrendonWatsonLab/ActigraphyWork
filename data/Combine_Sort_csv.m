function [] = Combine_Sort_csv(parentDir,folder_name)
dataDir = fullfile(parentDir, folder_name);
% Get a list of all subfolders within 'data'.
folders = dir(dataDir);
dirFlags = [folders.isdir] & ~strcmp({folders.name}, '.') & ~strcmp({folders.name}, '..');
subFolders = folders(dirFlags);

% Process each subfolder.
for k = 1:length(subFolders)
    % Get the current folder name.
    folderName = subFolders(k).name;
    folderPath = fullfile(dataDir, folderName);

    % Define the name of the combined file based on the subfolder
    combinedFileName = [folderName '_combined_data.csv'];
    
    % Get a list of CSV files in the current folder.
    csvFiles = dir(fullfile(folderPath, '*.csv'));
    
    % Initialize a variable to store the combined data.
    combinedData = [];
    
    % Read and concatenate data from each CSV file.
    for i = 1:length(csvFiles)
        csvFileName = csvFiles(i).name;
        
        % Skip the file if it is the combined file from a previous run
        if strcmp(csvFileName, combinedFileName)
            continue;  % Skip this iteration and go to the next file
        end

        csvFilePath = fullfile(folderPath, csvFiles(i).name);
        csvData = readtable(csvFilePath);
        % Concatenate the data.
        combinedData = [combinedData; csvData]; % Assuming CSV files have the same structure.
    end
    
    % Sets all variable names to ensure proper labeling
    combinedData.Properties.VariableNames = {'Frame', 'TimeElapsed', 'RawDifference', 'RMSE', 'SelectedPixelDifference', 'PositTime'};
    % Sort the combined data by the 'posit_time' column.
    sortedCombinedData = sortrows(combinedData, 'PositTime');
    % Deletes unnecessary columns (Frame and elapsed time)
    sortedCombinedData = removevars(sortedCombinedData, {'Frame','TimeElapsed'});

    % Convert 'PositTime' from milliseconds to seconds
    PositTime_seconds = sortedCombinedData.PositTime / 1000;
    % Convert to datetime (in UTC)
    PositTime_datetime = datetime(PositTime_seconds, 'ConvertFrom', 'posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', 'UTC');
    % Convert time from UTC to EST
    PositTime_datetime.TimeZone = 'America/New_York';  % This will take into account Daylight Saving Time
    sortedCombinedData.PositTime = PositTime_datetime;
    sortedCombinedData.Properties.VariableNames{'PositTime'} = 'Date';
    
    % Write the sorted combined data to a new CSV file.
    fullCombinedFilePath = fullfile(folderPath, combinedFileName);
    writetable(sortedCombinedData, fullCombinedFilePath);
    
    % Notify the user of progress.
    fprintf('Sorted and combined CSV files in folder "%s" into "%s"\n', folderName, combinedFileName);
end

% Notify the user that the process is complete.
disp('All CSV files have been successfully combined and sorted in their respective folders.');
end

