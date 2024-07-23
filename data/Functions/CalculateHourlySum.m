function hourlySum = CalculateHourlySum(data)
    % Calculate hourly sums of 'SelectedPixelDifference'
    data.HourlyBins = dateshift(data.Date, 'start', 'hour');
    hourlySumTable = groupsummary(data, 'HourlyBins', 'sum', 'SelectedPixelDifference');
    hourlySum = hourlySumTable.sum_SelectedPixelDifference;
end

