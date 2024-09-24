function CombineSortCsv2(parentDir, folder_name)
    dataDir = fullfile(parentDir, folder_name);
    
    % Define the name of the combined file
    combinedFileName = [folder_name '_combined_data.csv'];
    
    % Get a list of CSV files in the specified folder.
    csvFiles = dir(fullfile(dataDir, '*.csv'));
    
    % Initialize a variable to store the combined data as a table.
    combinedData = [];

    % Read and concatenate data from each CSV file.
    for i = 1:length(csvFiles)
        csvFileName = csvFiles(i).name;
        
        % Skip the file if it is the combined file from a previous run
        if strcmp(csvFileName, combinedFileName)
            continue;  % Skip this iteration and go to the next file
        end

        csvFilePath = fullfile(dataDir, csvFileName);
        csvData = readtable(csvFilePath);
        
        % Concatenate the data, ensuring it remains a table.
        if isempty(combinedData)
            combinedData = csvData;
        else
            combinedData = [combinedData; csvData]; % Assuming CSV files have the same structure.
        end
    end

    % Check if combinedData is still empty
    if isempty(combinedData)
        error('No valid CSV files were found in the specified folder.');
    end
    
    % Confirm combinedData is a table
    if ~istable(combinedData)
        error('Combined data is not a table.');
    end
    
    % Verify that PositTime exists and is formatted correctly
    if ismember('PositTime', combinedData.Properties.VariableNames)
        % Sort the combined data by the 'PositTime' column.
        sortedCombinedData = sortrows(combinedData, 'PositTime', 'ascend');
    else
        error('PositTime column not found in the combined data.');
    end
    
    % Delete unnecessary columns (Frame and TimeElapsed)
    sortedCombinedData = removevars(sortedCombinedData, {'Frame'});

    % Convert 'PositTime' from milliseconds to seconds
    PositTime_seconds = sortedCombinedData.PositTime / 1000;
    
    % Convert to datetime (in UTC)
    PositTime_datetime = datetime(PositTime_seconds, 'ConvertFrom', 'posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', 'UTC');
    
    % Convert time from UTC to EST
    PositTime_datetime.TimeZone = 'America/New_York';  % This will take into account Daylight Saving Time
    sortedCombinedData.PositTime = PositTime_datetime;
    sortedCombinedData.Properties.VariableNames{'PositTime'} = 'Date';
    
    % Write the sorted combined data to a new CSV file.
    fullCombinedFilePath = fullfile(dataDir, combinedFileName);
    writetable(sortedCombinedData, fullCombinedFilePath);
    
    % Notify the user of progress.
    fprintf('Sorted and combined CSV files in folder "%s" into "%s"\n', folder_name, combinedFileName);

    % Notify the user that the process is complete.
    disp('Done');
end


