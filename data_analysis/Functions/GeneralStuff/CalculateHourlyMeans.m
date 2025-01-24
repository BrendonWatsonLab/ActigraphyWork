function [hourlyMeans, hourlyBinTimes] = CalculateHourlyMeans(data)
    % Calculate hourly means of 'NormalizedActivity'
    data.HourlyBins = dateshift(data.DateZT, 'start', 'hour');
    hourlySumTable = groupsummary(data, 'HourlyBins', 'mean', 'NormalizedActivity');
    hourlyMeans = hourlySumTable.mean_NormalizedActivity;
    hourlyBinTimes = hourlySumTable.HourlyBins;
end