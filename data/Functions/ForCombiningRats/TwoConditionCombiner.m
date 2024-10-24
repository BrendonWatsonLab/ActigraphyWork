function TwoConditionCombiner(parentDir, folder_name, lights_on_hour_DST, lights_on_hour_nonDST)
    dataDir = fullfile(parentDir, folder_name);
    
    % Define the names of the combined files for each condition
    combinedFileName_300Lux = [folder_name '_300Lux_combined_data.csv'];
    combinedFileName_1000Lux = [folder_name '_1000Lux_combined_data.csv'];
    
    % Define the period for each lighting condition using datetimes
    LUX300_start = datetime(2024, 7, 4, 6, 0, 0, 'TimeZone', 'America/New_York');
    LUX300_end = datetime(2024, 8, 9, 6, 0, 0, 'TimeZone', 'America/New_York');
    LUX1000_start = datetime(2024, 8, 9, 6, 0, 0, 'TimeZone', 'America/New_York');
    LUX1000_end = datetime(2024, 9, 6, 18, 0, 0, 'TimeZone', 'America/New_York');
    
    % Get a list of CSV files in the specified folder.
    csvFiles = dir(fullfile(dataDir, '*.csv'));
    
    % Initialize variables to store combined data for each condition
    combinedData_300Lux = [];
    combinedData_1000Lux = [];

    % Read and separate data from each CSV file.
    for i = 1:length(csvFiles)
        csvFileName = csvFiles(i).name;
        
        % Skip the file if it is one of the combined files from a previous run
        if strcmp(csvFileName, combinedFileName_300Lux) || strcmp(csvFileName, combinedFileName_1000Lux)
            continue;
        end

        csvFilePath = fullfile(dataDir, csvFileName);
        csvData = readtable(csvFilePath);

        % Convert 'PositTime' from milliseconds to seconds and to datetime in EST
        csvData.PositTime = datetime(csvData.PositTime / 1000, 'ConvertFrom', 'posixtime', 'TimeZone', 'UTC');
        csvData.PositTime.TimeZone = 'America/New_York';
        csvData.Properties.VariableNames{'PositTime'} = 'Date';

        % Separate the data based on the Date condition
        condition_300Lux = (csvData.Date >= LUX300_start) & (csvData.Date < LUX300_end);
        condition_1000Lux = (csvData.Date >= LUX1000_start) & (csvData.Date <= LUX1000_end);
        
        if any(condition_300Lux)
            data_300Lux = csvData(condition_300Lux, :);
            if isempty(combinedData_300Lux)
                combinedData_300Lux = data_300Lux;
            else
                combinedData_300Lux = [combinedData_300Lux; data_300Lux];
            end
        end
        
        if any(condition_1000Lux)
            data_1000Lux = csvData(condition_1000Lux, :);
            if isempty(combinedData_1000Lux)
                combinedData_1000Lux = data_1000Lux;
            else
                combinedData_1000Lux = [combinedData_1000Lux; data_1000Lux];
            end
        end
    end

    % Check if combinedData arrays are still empty
    if isempty(combinedData_300Lux)
        error('No valid CSV files were found for the 300Lux condition.');
    end
    if isempty(combinedData_1000Lux)
        error('No valid CSV files were found for the 1000Lux condition.');
    end
    
    % Sorting the combined data by the 'Date' column for both conditions
    sortedCombinedData_300Lux = sortrows(combinedData_300Lux, 'Date', 'ascend');
    sortedCombinedData_1000Lux = sortrows(combinedData_1000Lux, 'Date', 'ascend');

    % Delete the 'Frame' column if it exists
    if ismember('Frame', sortedCombinedData_300Lux.Properties.VariableNames)
        sortedCombinedData_300Lux = removevars(sortedCombinedData_300Lux, {'Frame'});
    end
    if ismember('Frame', sortedCombinedData_1000Lux.Properties.VariableNames)
        sortedCombinedData_1000Lux = removevars(sortedCombinedData_1000Lux, {'Frame'});
    end

    % Logic to convert to ZT
    % Function to determine which lights on hour to use based on DST status
    function lights_on_hour = determineLightsOnHour(datetimeCol)
        % Define DST start and end dates
        DST_start = datetime(year(datetimeCol), 3, 10, 'TimeZone', 'America/New_York'); % approximate start
        DST_end = datetime(year(datetimeCol), 11, 3, 'TimeZone', 'America/New_York');  % approximate end

        % Determine whether each date falls within the DST period
        isDST = (datetimeCol >= DST_start) & (datetimeCol < DST_end);
        
        % Assign the appropriate lights on hour based on DST status
        lights_on_hour = zeros(size(datetimeCol));
        lights_on_hour(isDST) = lights_on_hour_DST;
        lights_on_hour(~isDST) = lights_on_hour_nonDST;
    end

    % Function to adjust Zeitgeber time across both dataframes
    function adjustedData = adjustZT(data)
        datetimeCol = data.Date;
        lightsOnHours = determineLightsOnHour(datetimeCol);
        zt_datetimes = datetimeCol - hours(lightsOnHours);
        isBeforeLightsOn = hours(timeofday(zt_datetimes)) < 0;
        zt_datetimes(isBeforeLightsOn) = zt_datetimes(isBeforeLightsOn) + hours(24);
        data.Date = zt_datetimes;
        adjustedData = data; % Assign the modified data to the output variable
    end

    % Apply ZT conversion for both datasets
    sortedCombinedData_300Lux = adjustZT(sortedCombinedData_300Lux);
    sortedCombinedData_1000Lux = adjustZT(sortedCombinedData_1000Lux);
    
    % Write the sorted combined data to new CSV files for each condition.
    writetable(sortedCombinedData_300Lux, fullfile(dataDir, combinedFileName_300Lux));
    writetable(sortedCombinedData_1000Lux, fullfile(dataDir, combinedFileName_1000Lux));
    
    % Notify the user of progress.
    fprintf('Sorted, combined, and ZTed CSV files for 300Lux into "%s"\n', combinedFileName_300Lux);
    fprintf('Sorted, combined, and ZTed CSV files for 1000Lux into "%s"\n', combinedFileName_1000Lux);

    % Notify the user that the process is complete.
    disp('Done');
end

