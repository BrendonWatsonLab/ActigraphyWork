%%% Halfdan 5/7 Day Video Analysis
% Noah Muscat
% Data ran from /data/Jeremy/Halfdan using actigraphy_v5.py

%% Define datafile paths
datafile_combined = '/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/Halfdan_binned_data.csv';

%% Compare movements between the different lighting conditions and plot results
CompareLightingConditions(datafile_combined, datafile_combined, datafile_combined, false);

%% Circadian Comparisons
datafile = readtable(datafile_combined);
conditions = {'300Lux', '1000Lux_week1', '1000Lux_week4', 'sleep_deprivation'};
conditionTitles = {'Halfdan 300 Lux', 'Halfdan 1000 Lux Week 1', 'Halfdan 1000 Lux Week 4', 'Halfdan Sleep Deprivation'};

for i = 1:length(conditions)
    AnalyzeCircadianRunning(datafile, false, conditionTitles{i});
end

%% Per-day analysis and plotting for each condition
for i = 1:length(conditions)
    cond = conditions{i};
    titleText = conditionTitles{i};
    
    Per_Day_Analysis(datafile_combined, cond, 'Halfdan', false);
    
    % Reading data for the current condition
    data = readtable(datafile_combined);
    data = data(strcmp(data.Condition, cond), :);

    % Set this to true to convert times in the datasets to Zeitgeber time

    % Create an 'Hour' column that represents just the hour part of 'Date'
    data.Hour = hour(data.Date);

    % Summarize 'SelectedPixelDifference' by the 'Hour' column across all entries in dataTable
    hourlySum = groupsummary(data, 'Hour', 'sum', 'SelectedPixelDifference');

    % Create the plot
    figure('Name', titleText, 'NumberTitle', 'off');
    b1 = bar(hourlySum.Hour, hourlySum.sum_SelectedPixelDifference, 'BarWidth', 1);
    addShadedAreaToPlotZT();
    title(titleText, 'FontSize', 20, 'FontWeight', 'bold');
    xlabel('Hour of the Day', 'FontSize', 18, 'FontWeight', 'bold');
    ylabel('Sum of Selected Pixel Difference', 'FontSize', 18, 'FontWeight', 'bold');
    set(gca, 'FontSize', 14, 'FontWeight', 'bold'); % Increase font size and bold for axis labels
    
    % Ensure the bars are on top
    uistack(b1, 'top');
end

%% Functions

% Function to add a shaded area to the current plot
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
    ylabel('Sum of Selected Pixel Difference');
    xlim([-0.5, 23.5]);
    xticks(0:23);
    xtickangle(90);
    
    hold off;
end

