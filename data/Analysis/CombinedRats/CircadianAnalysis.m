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
addShadedAreaToPlotZT48Hour();
title('Total Animal Circadian Sums Over 48 Hours');

% Ensure the bars are on top
uistack(b1, 'top'); 

%% Finding what hour of the day accounts for the difference
% Extract rows for the 300Lux and 1000Lux4 conditions
data_300lux = combined_data(strcmp(combined_data.Condition, '300Lux'), :);
data_1000lux_week4 = combined_data(strcmp(combined_data.Condition, '1000Lux4'), :);

% Create 'Hour' column for both subsets
data_300lux.Hour = hour(data_300lux.Date);
data_1000lux_week4.Hour = hour(data_1000lux_week4.Date);

% Summarize 'NormalizedActivity' by 'Hour' for both subsets
mean_300lux = groupsummary(data_300lux, 'Hour', 'mean', 'NormalizedActivity');
mean_1000lux_week4 = groupsummary(data_1000lux_week4, 'Hour', 'mean', 'NormalizedActivity');

% Ensure both tables are sorted by 'Hour' for direct subtraction
mean_300lux = sortrows(mean_300lux, 'Hour');
mean_1000lux_week4 = sortrows(mean_1000lux_week4, 'Hour');

% Subtract means: 1000Lux4 - 300Lux
difference = mean_1000lux_week4.mean_NormalizedActivity - mean_300lux.mean_NormalizedActivity;

% Prepare data for 24-hour plot
hours = mean_300lux.Hour;

% Create the plot
figure;
b1 = bar(hours, difference, 'BarWidth', 1);

addShadedAreaToPlotZT24Hour();

% Set plot title and labels
title('Difference in NormalizedActivity: 1000 Lux Week4 - 300 Lux');
xlabel('Hour of Day');
ylabel('Difference in NormalizedActivity');

% Ensure the bars are on top
uistack(b1, 'top');

% Display the figure
grid on;

%% Line Plots for Differences
% Extract rows for the 300Lux and 1000Lux4 conditions
% Extract rows for the 300Lux and 1000Lux4 conditions
data_300lux = combined_data(strcmp(combined_data.Condition, '300Lux'), :);
data_1000lux_week4 = combined_data(strcmp(combined_data.Condition, '1000Lux4'), :);

% Create 'Hour' column for both subsets
data_300lux.Hour = hour(data_300lux.Date);
data_1000lux_week4.Hour = hour(data_1000lux_week4.Date);

% Summarize 'SelectedPixelDifference' by 'Hour' for both subsets
mean_300lux = groupsummary(data_300lux, 'Hour', 'mean', 'SelectedPixelDifference');
mean_1000lux_week4 = groupsummary(data_1000lux_week4, 'Hour', 'mean', 'SelectedPixelDifference');

% Ensure both tables are sorted by 'Hour'
mean_300lux = sortrows(mean_300lux, 'Hour');
mean_1000lux_week4 = sortrows(mean_1000lux_week4, 'Hour');

% Calculate the difference: 1000Lux4 - 300Lux
difference = mean_1000lux_week4.mean_SelectedPixelDifference - mean_300lux.mean_SelectedPixelDifference;

% Prepare data for 24-hour plot
hours = mean_300lux.Hour;

% Create the plot
figure;
hold on;

% Plot mean activity for 300Lux
p1 = plot(hours, mean_300lux.mean_SelectedPixelDifference, '-o', 'DisplayName', '300 Lux', 'Color', 'b', 'LineWidth', 2);

% Plot mean activity for 1000 Lux Week 4
p2 = plot(hours, mean_1000lux_week4.mean_SelectedPixelDifference, '-s', 'DisplayName', '1000 Lux Week 4', 'Color', 'r', 'LineWidth', 2);

% Plot the difference between the two conditions
p3 = plot(hours, difference, '-^', 'DisplayName', 'Difference (1000 Lux Week 4 - 300 Lux)', 'Color', 'g', 'LineWidth', 2);

% Add shaded area if needed (uncomment the function call if you need shaded regions)
addShadedAreaToPlotZT24Hour();

% Add plot settings
title('Mean SelectedPixelDifference and Differences Over 24 Hours');
xlabel('Hour of Day');
ylabel('Mean SelectedPixelDifference');
legend('show', 'Location', 'northeast');
grid on;

% Ensure the bars are on top
uistack(p1, 'top');
uistack(p2, 'top');
uistack(p3, 'top');

hold off;
%% functions
% Function to add a shaded area to the current plot
function addShadedAreaToPlotZT48Hour()
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
    fill(x_shaded1, y_shaded1, fill_color, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    fill(x_shaded2, y_shaded2, fill_color, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    
    % Additional Plot settings
    xlabel('Hour of Day (ZT Time)');
    ylabel('Sum of PixelDifference');
    xlim([-0.5, 47.5]);
    xticks(0:1:47);
    xtickangle(90);
    
    hold off;
end

% Function to add a shaded area to the current plot
function addShadedAreaToPlotZT24Hour()
    hold on;
    % Define x and y coordinates for the shaded area (from t=12 to t=24)
    x_shaded = [12, 24, 24, 12];
    y_lim = ylim;
    y_shaded = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];

    fill_color = [0.7, 0.7, 0.7]; % Light gray color for the shading

    % Add shaded areas to the plot with 'HandleVisibility', 'off' to exclude from the legend
    fill(x_shaded, y_shaded, fill_color, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    
    % Additional Plot settings
    xlabel('Hour of Day (ZT Time)');
    ylabel('Sum of PixelDifference');
    xlim([-0.5, 23.5]);
    xticks(0:23);
    xtickangle(0);
    
    hold off;
end