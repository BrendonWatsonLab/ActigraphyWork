function CombineSortZT(parentDir, folder_name, lights_on_hour)
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

    % Logic to convert to ZT
    % Check if the 'Date' column exists in the dataset
    if ~any(strcmp('Date', sortedCombinedData.Properties.VariableNames))
        error('The dataset does not contain a ''Date'' column.');
    end

    % Determine the "lights on" time (e.g., 5 AM as ZT0)
    lightsOn = hours(lights_on_hour);

    % Extract the 'Date' column from the dataset
    datetimeCol = sortedCombinedData.Date;

    % Subtract 'lights on' time from each datetime entry to get Zeitgeber time
    zt_datetimes = datetimeCol - lightsOn;

    % Wrap negative times to the previous day (e.g., if before ZT0, then it is ZT>0 of the previous day)
    isBeforeLightsOn = hours(timeofday(zt_datetimes)) < 0;
    zt_datetimes(isBeforeLightsOn) = zt_datetimes(isBeforeLightsOn) + hours(24);

    % Update the 'Date' column in the dataset with adjusted Zeitgeber time
    sortedCombinedData.Date = zt_datetimes;
    
    % Write the sorted combined data to a new CSV file.
    fullCombinedFilePath = fullfile(dataDir, combinedFileName);
    writetable(sortedCombinedData, fullCombinedFilePath);
    
    % Notify the user of progress.
    fprintf('Sorted, combined, and ZTed CSV files in folder "%s" into "%s"\n', folder_name, combinedFileName);

    % Notify the user that the process is complete.
    disp('Done');
end


