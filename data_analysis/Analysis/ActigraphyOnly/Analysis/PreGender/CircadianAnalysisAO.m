%% Circadian Analysis of Pooled Data
% using data pulled from /data/Jeremy on Scatha
%% Reading in data
% reading in data, already in ZT form 
convertZT = false;
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/AOCohortData.csv');
%% Wrangling hourly bins and plotting bar graphs
% plots bars of ZT 0-10 and 15-24 as well as 10-14 vs rest

AnalyzeCircadianRunning(combined_data, false, 'All Rats');
%% plots bars of means at each hour of the day 
% Creating an 'Hour' column that represents just the hour part of 'DateZT'
combined_data.Hour = hour(combined_data.DateZT);

% Now summarize 'SelectedPixelDifference' by the 'Hour' column across all entries in dataTable
hourlyMean = groupsummary(combined_data, 'Hour', 'mean', 'SelectedPixelDifference');

% Prepare data for 48-hour plot
hours48 = [hourlyMean.Hour; hourlyMean.Hour + 24]; % Append hours 0-23 with 24-47
means48 = [hourlyMean.mean_SelectedPixelDifference; hourlyMean.mean_SelectedPixelDifference]; % Repeat the means

% Create the plot
figure;
b1 = bar(hours48, means48, 'BarWidth', 1);
addShadedAreaToPlotZT48Hour();
title('Total Animal Circadian Means Over 48 Hours', 'FontSize', 20, 'FontWeight', 'bold'); % Increase font size and bold
xlabel('Hour of the Day', 'FontSize', 18, 'FontWeight', 'bold'); % Add xlabel with increased font size and bold
ylabel('Means of Selected Pixel Difference', 'FontSize', 18, 'FontWeight', 'bold'); % Add ylabel with increased font size and bold
set(gca, 'FontSize', 14, 'FontWeight', 'bold'); % Increase font size and bold for axis labels

% Ensure the bars are on top
uistack(b1, 'top'); 

%% Finding what hour of the day accounts for the difference
% Extract rows for the 300Lux and 1000Lux4 conditions
data_300lux = combined_data(strcmp(combined_data.Condition, '300Lux'), :);
data_1000lux_week = combined_data(strcmp(combined_data.Condition, '1000Lux'), :);

% Create 'Hour' column for both subsets
data_300lux.Hour = hour(data_300lux.DateZT);
data_1000lux_week.Hour = hour(data_1000lux_week.DateZT);

% Summarize 'SelectedPixelDifference' by 'Hour' for both subsets
mean_300lux = groupsummary(data_300lux, 'Hour', 'mean', 'SelectedPixelDifference');
mean_1000lux = groupsummary(data_1000lux_week, 'Hour', 'mean', 'SelectedPixelDifference');

% Ensure both tables are sorted by 'Hour' for direct subtraction
mean_300lux = sortrows(mean_300lux, 'Hour');
mean_1000lux = sortrows(mean_1000lux, 'Hour');

% Subtract means: 1000Lux4 - 300Lux
difference = mean_1000lux.mean_SelectedPixelDifference - mean_300lux.mean_SelectedPixelDifference;

% Prepare data for 24-hour plot
hours = mean_300lux.Hour;

% Create the plot
figure;
b1 = bar(hours, difference, 'BarWidth', 1);

addShadedAreaToPlotZT24Hour();

% Set plot title and labels
title('Difference in SelectedPixelDifference: 1000 Lux - 300 Lux', 'FontSize', 20, 'FontWeight', 'bold'); % Increase font size and bold
xlabel('Hour of Day', 'FontSize', 18, 'FontWeight', 'bold'); % Increase font size and bold
ylabel('Difference in SelectedPixelDifference', 'FontSize', 18, 'FontWeight', 'bold'); % Increase font size and bold
set(gca, 'FontSize', 14, 'FontWeight', 'bold'); % Increase font size and bold for axis labels

% Ensure the bars are on top
uistack(b1, 'top');

% Display the figure
grid on;

%% Line Plots for Differences
% Extract rows for the 300Lux and 1000Lux4 conditions
data_300lux = combined_data(strcmp(combined_data.Condition, '300Lux'), :);
data_1000lux = combined_data(strcmp(combined_data.Condition, '1000Lux'), :);

% Create 'Hour' column for both subsets
data_300lux.Hour = hour(data_300lux.DateZT);
data_1000lux.Hour = hour(data_1000lux.DateZT);

% Summarize 'SelectedPixelDifference' by 'Hour' for both subsets
mean_300lux = groupsummary(data_300lux, 'Hour', 'mean', 'SelectedPixelDifference');
mean_1000lux = groupsummary(data_1000lux, 'Hour', 'mean', 'SelectedPixelDifference');

% Ensure both tables are sorted by 'Hour'
mean_300lux = sortrows(mean_300lux, 'Hour');
mean_1000lux = sortrows(mean_1000lux, 'Hour');

% Calculate the difference: 1000Lux4 - 300Lux
difference = mean_1000lux.mean_SelectedPixelDifference - mean_300lux.mean_SelectedPixelDifference;

% Prepare data for 24-hour plot
hours = mean_300lux.Hour;

% Create the plot
figure;
hold on;

% Plot mean activity for 300Lux
p1 = plot(hours, mean_300lux.mean_SelectedPixelDifference, '-o', 'DisplayName', '300 Lux', 'Color', 'b', 'LineWidth', 2);

% Plot mean activity for 1000 Lux Week 4
p2 = plot(hours, mean_1000lux.mean_SelectedPixelDifference, '-s', 'DisplayName', '1000 Lux', 'Color', 'r', 'LineWidth', 2);

% Plot the difference between the two conditions
p3 = plot(hours, difference, '-^', 'DisplayName', 'Difference (1000 Lux - 300 Lux)', 'Color', 'g', 'LineWidth', 2);

% Add shaded area if needed (uncomment the function call if you need shaded regions)
addShadedAreaToPlotZT24Hour();

% Add plot settings
title('Mean SelectedPixelDifference and Differences Over 24 Hours', 'FontSize', 20, 'FontWeight', 'bold'); % Increase font size and bold
xlabel('Hour of Day', 'FontSize', 18, 'FontWeight', 'bold'); % Increase font size and bold
ylabel('Mean SelectedPixelDifference', 'FontSize', 18, 'FontWeight', 'bold'); % Increase font size and bold
legend('show', 'Location', 'northeast', 'FontSize', 14, 'FontWeight', 'bold'); % Increase font size and bold for legend
set(gca, 'FontSize', 14, 'FontWeight', 'bold'); % Increase font size and bold for axis labels
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
    ylabel('Means of PixelDifference');
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
    ylabel('Means of PixelDifference');
    xlim([-0.5, 23.5]);
    xticks(0:23);
    xtickangle(0);
    
    hold off;
end