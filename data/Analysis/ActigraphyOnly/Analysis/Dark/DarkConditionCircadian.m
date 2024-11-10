%% Analysis of Dark Condition Activity Over Time
% This script analyzes the normalized activity in the Dark/Dark condition,
% binning every 7 days, and plots the summed activity at each hour over a 48-hour period.
% Only animals AO5-8 are considered.

%% Parameters
animalIDs = {'AO5', 'AO6', 'AO7', 'AO8'};
conditions = {'FullDark'};

% Read the combined data table
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/AO1-8Dark_binned_data.csv');

%% Filter data for Dark/Dark condition and specific animals
dark_data = combined_data(strcmp(combined_data.Condition, 'FullDark') & ismember(combined_data.Animal, animalIDs), :);

%% Assign each data point a 7-day bin
dark_data.Bin = ceil(dark_data.RelativeDay / 7);

%% Exclude Week 6
dark_data(dark_data.Bin == 6, :) = [];

%% Summarize 'SelectedPixelDifference' by 'Hour' within each 7-day bin
bins = unique(dark_data.Bin);

figure('Name', 'Total Animal Circadian Sums Over 48 Hours', 'NumberTitle', 'off');
for i = 1:5
    bin = bins(i);
    % Filter data for the current bin
    bin_data = dark_data(dark_data.Bin == bin, :);
    
    % Extract hour from datetime data
    bin_data.Hour = hour(bin_data.Date);
    
    % Summarize 'SelectedPixelDifference' by 'Hour'
    hourlySum = groupsummary(bin_data, 'Hour', 'sum', 'SelectedPixelDifference');
    
    % Prepare data for 48-hour plot
    hours48 = [hourlySum.Hour; hourlySum.Hour + 24]; % Append hours 0-23 with 24-47
    sums48 = [hourlySum.sum_SelectedPixelDifference; hourlySum.sum_SelectedPixelDifference]; % Repeat the sums
    
    % Variables for plot titles and figure names
    weekTitle = sprintf('Week %d (Days %d-%d)', bin, (bin-1)*7 + 1, bin*7);
    
    % Create the subplot
    subplot(5, 1, i);
    b1 = bar(hours48, sums48, 'BarWidth', 1);
    addShadedAreaToPlotZT48Hour();
    title(weekTitle, 'FontSize', 16, 'FontWeight', 'bold');
    xlabel('Hour of the Day', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('PixelSum', 'FontSize', 14, 'FontWeight', 'bold');
    set(gca, 'FontSize', 12, 'FontWeight', 'bold'); % Increase font size and bold for axis labels
    
    % Ensure the bars are on top
    uistack(b1, 'top');
end

%% Functions

% Function to add a shaded area to the current plot for ZT 48-hour
function addShadedAreaToPlotZT48Hour()
    hold on;
    
    % Define x and y coordinates for the first shaded area (from ZT 12 to ZT 24)
    x_shaded1 = [12, 24, 24, 12];
    y_lim = ylim;
    y_shaded1 = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];
    
    % Define x and y coordinates for the second shaded area (from ZT 36 to ZT 48)
    x_shaded2 = [36, 48, 48, 36];
    y_shaded2 = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];
    
    fill_color = [0.7, 0.7, 0.7]; % Light gray color for the shading
    
    % Add shaded areas to the plot
    fill(x_shaded1, y_shaded1, fill_color, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    fill(x_shaded2, y_shaded2, fill_color, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    
    xlabel('Hour of Day (ZT Time)');
    ylabel('Sum of Selected Pixel Difference');
    xlim([-0.5, 47.5]);
    xticks(0:1:47);
    xtickangle(90);
    
    hold off;
end

function addShadedAreaToPlotZT24Hour()
    hold on;
    % Define x and y coordinates for the shaded area (from ZT 12 to ZT 24)
    x_shaded = [12, 24, 24, 12];
    y_lim = ylim;
    y_shaded = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];

    fill_color = [0.7, 0.7, 0.7]; % Light gray color for the shading

    % Add shaded areas to the plot with 'HandleVisibility', 'off' to exclude from the legend
    fill(x_shaded, y_shaded, fill_color, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    
    xlabel('Hour of Day (ZT Time)');
    ylabel('Sum of Selected Pixel Difference');
    xlim([-0.5, 23.5]);
    xticks(0:23);
    xtickangle(0);
    
    hold off;
end