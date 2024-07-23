function [dailyLOnSum, dailyLOffSum, uniqueDays] = LightsOnVsOff(filename, convert_ZT)
    dataTable = readtable(filename);
    if convert_ZT
        dataTable = make_ZT(dataTable, 5);
    end

    % Floor 'DateTime' to the nearest hour to create hourly bins
    dataTable.HourlyBins = dateshift(dataTable.Date, 'start', 'hour');
    % Extract just the date part from 'DateTime'
    dataTable.Day = dateshift(dataTable.Date, 'start', 'day');
    % Get a list of unique days to iterate over
    uniqueDays = unique(dataTable.Day);

    % Initialize variables for storing daily sums
    dailyLOnSum = zeros(length(uniqueDays), 1);
    dailyLOffSum = zeros(length(uniqueDays), 1);

    % For each unique day, calculate sums for lights on and lights off periods
    for i = 1:length(uniqueDays)
        % Make sure the current day is valid and not NaT (Not-a-Time)
        if isdatetime(uniqueDays(i)) && ~isnat(uniqueDays(i))
            % Create a logical index for the current day
            dayIndex = dataTable.Day == uniqueDays(i);
            currentDayData = dataTable(dayIndex, :);

            % Calculate sums for lights on (hours 0-11) and lights off (hours 12-23) periods
            lightsOnData = currentDayData(hour(currentDayData.Date) < 12, :);
            lightsOffData = currentDayData(hour(currentDayData.Date) >= 12, :);

            dailyLOnSum(i) = sum(lightsOnData.SelectedPixelDifference);
            dailyLOffSum(i) = sum(lightsOffData.SelectedPixelDifference);
        end
    end
end

