function sleepSummaryTable = analyzeSleepStates(filename, lightingLux, animalSex)
    % Function to analyze sleep states
    % Inputs:
    %   filename: full path of the .mat file containing sleep state data
    %   lightingLux: lighting conditions in Lux
    %   animalSex: gender of the animal ('M' or 'F')

    % Extract animal name, date, and time from the filename
    [~, name, ~] = fileparts(filename);
    
    try
        % Locate the positions based on fixed format
        animalNameEndIdx = find(name == '_', 1) - 1;
        dateStrStartIdx = animalNameEndIdx + 2;
        dateStrEndIdx = dateStrStartIdx + 5;
        timeStrStartIdx = dateStrEndIdx + 2;
        timeStrEndIdx = timeStrStartIdx + 5;
        
        animalName = name(1:animalNameEndIdx);
        dateStr = name(dateStrStartIdx:dateStrEndIdx);
        timeStr = name(timeStrStartIdx:timeStrEndIdx);

        % Convert extracted date and time to datetime
        manualStartTime = datetime([dateStr timeStr], 'InputFormat', 'yyMMddHHmmss', 'TimeZone', 'America/New_York');
    catch
        error('Failed to parse date and time information from filename.');
    end

    % Load the sleep state data
    sleepData = load(filename);
    sleepStates = sleepData.SleepState.idx.states;

    % Filter valid sleep states (only 1, 3, 5 are valid)
    validStates = ismember(sleepStates, [1, 3, 5]);
    sleepStates = sleepStates(validStates);

    % Filter corresponding timestamps
    timestamps = sleepData.SleepState.idx.timestamps(validStates);

    % Confirm unique states available in the data (1: WAKE, 3: NREM, 5: REM)
    uniqueStates = unique(sleepStates);
    disp('Unique sleep states present in the data:');
    disp(uniqueStates');

    % Check the length of the timestamps to ensure it matches the sleep states length
    if length(timestamps) ~= length(sleepStates)
        error('Mismatch between the length of timestamps and sleep states data.');
    end

    % Compute the time array based on the manual start time
    timeArray = manualStartTime + seconds(timestamps);

    % Bin data by 1-second intervals using retime and the mode of the sleep states in each bin
    timeTable = table(timeArray, sleepStates, 'VariableNames', {'Time', 'State'});
    timeTable = table2timetable(timeTable);

    % Use 'regular' time vector with 1-second intervals
    startTime = min(timeArray);
    endTime = max(timeArray);
    regularTime = (startTime:seconds(1):endTime)';

    % Synchronize timetable to regular time vector
    timeTableSync = retime(timeTable, regularTime, 'nearest');
    binnedTimeArray = timeTableSync.Time;
    binnedSleepStates = timeTableSync.State;

    % Correct Posix time to reflect real time
    binnedPosixTime = posixtime(binnedTimeArray);

    % Calculate Zeitgeber Time (ZT) in hours considering DST for the binned time array
    ZTtime = zeros(size(binnedTimeArray));
    for i = 1:length(binnedTimeArray)
        currentHour = hour(binnedTimeArray(i));
        isDST = isdst(binnedTimeArray(i));
        if isDST
            % Daylight Saving Time (lights on at 6 AM, lights off at 6 PM)
            ZTtime(i) = mod((currentHour - 6) + (minute(binnedTimeArray(i)) / 60), 24);
        else
            % Standard Time (lights on at 5 AM, lights off at 5 PM)
            ZTtime(i) = mod((currentHour - 5) + (minute(binnedTimeArray(i)) / 60), 24);
        end
    end

    % Determine lighting condition based on ZT time (1 for lights on: ZT 0-12, 0 for lights off: ZT 12-24)
    lights = repmat({'OFF'}, length(ZTtime), 1); % Default to 'OFF'
    lights(ZTtime >= 0 & ZTtime < 12) = {'ON'}; % Set 'ON' for ZT 0-12

    % Set lighting condition in Lux (manually)
    lightingCondition = repmat(lightingLux, length(ZTtime), 1);  % Set the Lux value for every time point

    % Metadata for animal sex
    animalSexColumn = repmat({animalSex}, length(binnedTimeArray), 1);  % Set gender for every time point

    % Ensure all arrays are column vectors and the same length
    variables = {binnedPosixTime, ZTtime, binnedSleepStates, lightingCondition, lights, animalSexColumn};
    variableNames = {'binnedPosixTime', 'ZTtime', 'binnedSleepStates', 'lightingCondition', 'lights', 'animalSexColumn'};

    for i = 1:numel(variables)
        if ~iscolumn(variables{i})
            variables{i} = variables{i}(:); % Ensure each variable is a column vector
        end
        disp(['Length of ' variableNames{i} ': ' num2str(length(variables{i}))]);
    end

    assert(length(binnedPosixTime) == length(ZTtime) && length(ZTtime) == length(binnedSleepStates) ...
        && length(binnedSleepStates) == length(lightingCondition) && length(lightingCondition) == length(lights) ...
        && length(lights) == length(animalSexColumn), 'All table variables must have the same number of rows.');

    % Create a table to save data, adding relevant columns for your specific analysis
    sleepSummaryTable = table(binnedPosixTime, ZTtime, binnedSleepStates, lightingCondition, lights, animalSexColumn, ...
                              'VariableNames', {'PosixTime', 'ZT_time_hours', 'SleepState', 'LightingCondition', 'Lights', 'AnimalSex'});

    % Save the table to a CSV file
    outputFilename = ['/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/Sleep_Scoring/' animalName '/' name '_sleep_summary.csv'];
    writetable(sleepSummaryTable, outputFilename);

    disp('Sleep summary CSV created successfully.');
end