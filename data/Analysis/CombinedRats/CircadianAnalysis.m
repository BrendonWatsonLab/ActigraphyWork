%% Circadian Analysis of Pooled Data
% using data pulled from /data/Jeremy on Scatha
%% Reading in data
% reading in data, already in ZT form 
convertZT = false;
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ZT/CombinedRelDaysBinned.csv');
%% Wrangling hourly bins and plotting bar graphs
% plots bars of ZT 0-10 and 15-24 as well as 10-14 vs rest

AnalyzeCircadianRunning(combined_data, false, 'All Rats');
%% plots bars of sums at each hour of the day 
% Creating an 'Hour' column that represents just the hour part of 'Date'
combined_data.Hour = hour(combined_data.Date);

% Now summarize 'SelectedPixelDifference' by the 'Hour' column across all entries in dataTable
hourlySum = groupsummary(combined_data, 'Hour', 'sum', 'SelectedPixelDifference');

% Prepare data for 48-hour plot
hours48 = [hourlySum.Hour; hourlySum.Hour + 24]; % Append hours 0-23 with 24-47
sums48 = [hourlySum.sum_SelectedPixelDifference; hourlySum.sum_SelectedPixelDifference]; % Repeat the sums

% Create the plot
figure;
b1 = bar(hours48, sums48, 'BarWidth', 1);
addShadedAreaToPlotZT();
title('Total Animal Circadian Sums Over 48 Hours');

% Ensure the bars are on top
uistack(b1, 'top'); 

%% functions
% Function to add a shaded area to the current plot
function addShadedAreaToPlotZT()
    hold on;
    
    % Define x and y coordinates for the first shaded area (from t=12 to t=24)
    x_shaded1 = [12, 24, 24, 12];
    y_lim = ylim;
    y_shaded1 = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];
    
    % Define x and y coordinates for the second shaded area (from t=36 to t=48)
    x_shaded2 = [36, 48, 48, 36];
    y_shaded2 = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];
    
    fill_color = [0.7, 0.7, 0.7]; % Light gray color for the shading
    
    % Add shaded areas to the plot
    fill(x_shaded1, y_shaded1, fill_color, 'EdgeColor', 'none');
    fill(x_shaded2, y_shaded2, fill_color, 'EdgeColor', 'none');
    
    % Additional Plot settings
    xlabel('Hour of Day (ZT Time)');
    ylabel('Sum of PixelDifference');
    xlim([-0.5, 47.5]);
    xticks(0:1:47);
    xtickangle(90);
    
    hold off;
end