% Define input and output file names
inputFileName = '/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyEphys/EphysCohortDataOld.csv';
outputFileName = '/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyEphys/EphysCohortData.csv';

% Check the existence of the input file
if ~isfile(inputFileName)
    error('The file does not exist: %s', inputFileName);
end

% Read the CSV file into a table
data = readtable(inputFileName);

% Verify if the 'Date' column exists
if ~ismember('Date', data.Properties.VariableNames)
    error('The table does not contain a "Date" column.');
end

% Convert the 'Date' column to datetime
data.DateZT = datetime(data.Date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');

% Initialize the new columns
data.DateEST = datetime(data.Date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss'); % Placeholder
data.ZT_Time = zeros(height(data), 1);

% Loop through each date and adjust based on DST and non-DST
for j = 1:height(data)
    currDate = data.DateZT(j);
    
    if isDST(currDate)
        % During DST (EDT), shift by 6 hours to get EST and calculate original ZT
        data.DateEST(j) = currDate + hours(6); % Shift from ZT to EST
        data.ZT_Time(j) = hour(currDate);
    else
        % During non-DST (EST), shift by 5 hours to get EST and calculate original ZT
        data.DateEST(j) = currDate + hours(5); % Shift from ZT to EST
        data.ZT_Time(j) = hour(currDate);
    end
end

data = removevars(data, 'Date');

% Save the updated table to a new .csv file
writetable(data, outputFileName);

disp('Table updated and saved successfully.');

% Function to determine if a timestamp is in DST
function isDst = isDST(timestamp)
    % DST starts on the second Sunday in March and ends on the first Sunday in November
    % Calculate DST start
    startDST = datetime(timestamp.Year, 3, 8) + days(7 - weekday(datetime(timestamp.Year, 3, 8), 'dayofweek'));
    % Calculate DST end
    endDST = datetime(timestamp.Year, 11, 1) + days(7 - weekday(datetime(timestamp.Year, 11, 1), 'dayofweek'));
    % Determine if the given timestamp is within DST period
    isDst = (timestamp >= startDST) && (timestamp < endDST);
end