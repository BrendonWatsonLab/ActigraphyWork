function [] = Per_Day_Analysis(filename,movement_param,rat_name, convert_ZT)
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

% Calculate the number of subplot rows and columns
numDays = length(uniqueDays);
numSubplotRows = ceil(sqrt(numDays));
numSubplotCols = ceil(numDays / numSubplotRows);

figure;
% For each unique day, create a histogram of 'SelectedPixelDifference' binned by hour
for i = 1:numDays
    subplot(numSubplotRows, numSubplotCols, i);
    
    % Create a logical index for the current day
    dayIndex = dataTable.Day == uniqueDays(i);
    currentDayData = dataTable(dayIndex, :);
    
    % Use 'groupsummary' to calculate the sum or mean of 'SelectedPixelDifference' binned by hourly bins
    hourlySummary = groupsummary(currentDayData, 'HourlyBins', 'sum', 'SelectedPixelDifference');
    
    % Convert the HourlyBins back to just the hours
    hourNumbers = hour(hourlySummary.HourlyBins);
    b1 = bar(hourNumbers, hourlySummary.sum_SelectedPixelDifference, 'BarWidth', 1);
    title(sprintf(datestr(uniqueDays(i), 'yyyy-mm-dd')));
    if convert_ZT 
        addShadedAreaToPlotZT();
    else
        addShadedAreaToPlotNonZT();
    end
    
    % Reduce the number of ticks if there are many subplots to avoid cluttered x-axis labels
    if numSubplotCols <= 4
        xticks(0:1:23);
    else
        xticks(0:2:23);
    end
    uistack(b1, 'top');
    
end
title_string = strcat(movement_param, '-', rat_name);
sgtitle(title_string);
end

function addShadedAreaToPlotZT()
    hold on;
    % Define x and y coordinates for the shaded area (from t=12 to t=24)
    x_shaded = [12, 24, 24, 12];
    y_lim = ylim;
    y_shaded = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];
    
    fill_color = [0.7, 0.7, 0.7]; % Light gray color for the shading
    fill(x_shaded, y_shaded, fill_color, 'EdgeColor', 'none');
    
    % Additional Plot settings
    xlabel('Hour of Day (ZT Time)');
    ylabel('Sum of PixelDifference');
    xlim([-0.5, 23.5]);
    xticks(0:23);
    xtickangle(90);
    
    hold off;
end

function addShadedAreaToPlotNonZT()
    hold on;
    
    % Define x coordinates for the shaded areas
    x_shaded_left = [0, 0, 5, 5]; 
    x_shaded_right = [17, 17, 24, 24]; 
    y_lim = ylim; 

    % Adjust y limits to only include positive y values
    y_lim(1) = max(0, y_lim(1)); 
    
    % Define y coordinates for the shaded areas considering only positive y values
    y_shaded = [y_lim(1), y_lim(2), y_lim(2), y_lim(1)]; 

    fill_color = [0.7, 0.7, 0.7]; % Light gray color for the shading

    % Add shaded areas to the plot
    fill(x_shaded_left, y_shaded, fill_color, 'EdgeColor', 'none'); % Add left shaded area without border
    fill(x_shaded_right, y_shaded, fill_color, 'EdgeColor', 'none'); % Add right shaded area without border
    
    xlabel('Hour of Day (EST Time)');
    ylabel('Sum of PixelDifference');
    xlim([-0.5, 24.5]); % Adjust the x-axis limit to go from -0.5 to 24.5
    xtickangle(90);
    
    hold off;
end