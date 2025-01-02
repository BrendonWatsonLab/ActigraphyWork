function [hourlyMeans, hourlyBinTimes] = CalculateHourlyMeans(data)
    % Calculate hourly means of 'SelectedPixelDifference'
    data.HourlyBins = dateshift(data.DateZT, 'start', 'hour');
    hourlySumTable = groupsummary(data, 'HourlyBins', 'mean', 'SelectedPixelDifference');
    hourlyMeans = hourlySumTable.mean_SelectedPixelDifference;
    hourlyBinTimes = hourlySumTable.HourlyBins;
end