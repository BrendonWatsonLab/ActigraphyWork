function [dailySum] = CalculateDailySum(data)
    % Calculate daily sums of 'SelectedPixelDifference'
    data.HourlyBins = dateshift(data.Date, 'start', 'hour');
    data.Day = dateshift(data.Date, 'start', 'day');
    uniqueDays = unique(data.Day);
    dailySum = zeros(length(uniqueDays), 1);

    for i = 1:length(uniqueDays)
        dayIndex = data.Day == uniqueDays(i);
        currentDayData = data(dayIndex, :);
        dailySum(i) = sum(currentDayData.SelectedPixelDifference);
    end
end