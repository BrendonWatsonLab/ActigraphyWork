%% Overview
% This script performs an analysis of activity data over multiple days using mean and standard error of NormalizedActivity.
% It reads the data from a CSV file, aggregates and averages the data by relative day and condition,
% and generates a plot of mean activity with error bars for different lighting conditions.
% The data is plotted with sectioned x-axis to clearly separate the conditions, and visual enhancements are added.

%% Over Many Days Analysis
% Using data directly from .csv
% Uses mean and standard error of NormalizedActivity

% Reading in table
fprintf('Reading in table\n');

% Reads in data from .csv
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyEphys/EphysActivityData.csv');
output_directory = '/Users/noahmuscat/Desktop';


% Define conditions and their corresponding day ranges
conditions = {'300Lux', '1000Lux1', '1000Lux4', 'sleep_deprivation'};
validConditions = {'300Lux', '1000Lux1', '1000Lux4', 'sleepDeprivation'};
day_ranges = {1:7, 1:7, 1:7, 1:3}; % Day ranges for each condition

% Aggregate and average the data by relative day and condition
fprintf('Aggregating and averaging data by relative day and condition...\n');
allData = {}; % Initialize cell array to hold aggregated data
conditionDayLabels = {}; % Initialize cell array for condition-day labels
colors = {'b', 'r', 'k', 'g'}; % Colors for each condition

for c = 1:length(conditions)
    condition = conditions{c};
    day_range = day_ranges{c}; % Get the specific day range for the current condition
    for day = day_range
        % Filter data for the current condition and day range
        dayData = combined_data(strcmp(combined_data.Condition, condition) & ...
                                combined_data.RelativeDay >= day & ...
                                combined_data.RelativeDay < day+1, :);
        
        if isempty(dayData)
            continue; % Skip if there is no data for this day and condition
        end
        
        % Calculate mean and standard error of NormalizedActivity
        meanNormalizedActivity = mean(dayData.NormalizedActivity);
        stdError = std(dayData.NormalizedActivity) / sqrt(height(dayData));
        
        % Append results to the data array
        allData = [allData; {condition, day, meanNormalizedActivity, stdError}];
    end
end

% Convert to table for easier manipulation and plotting
allDataTable = cell2table(allData, 'VariableNames', {'Condition', 'Day', 'MeanNormalizedActivity', 'StdError'});
data = allDataTable;

% Initialize arrays for plot data
mean_activity = [];
std_error = [];
x_ticks = {};
x_tick_labels = {};
h = []; % Array to store plot handles for legend

figure;
hold on;

for c = 1:length(conditions)
    condition = conditions{c};
    color = colors{c};
    condition_mean_activity = [];
    condition_std_error = [];
    day_range = day_ranges{c}; % Get the specific day range for the current condition
    
    for d = day_range
        % Filter the table for the current condition and day
        idx = strcmp(data.Condition, condition) & data.Day == d;
        condition_mean_activity = [condition_mean_activity; data.MeanNormalizedActivity(idx)];
        condition_std_error = [condition_std_error; data.StdError(idx)];
        x_ticks = [x_ticks; sprintf('%s Day %d', condition, d)];
        
        % Short x-tick label for plotting (Just the days)
        x_tick_labels = [x_tick_labels; num2str(d)];
    end
    
    % Create the x-axis values specific to each condition
    x_values = (c-1)*7 + (1:length(condition_mean_activity)); % Multiplied by 7 for gaps between conditions
    if strcmp(condition, 'sleep_deprivation')
        x_values = (3*7) + (1:length(condition_mean_activity)); % Adjust x_values for 'sleep_deprivation'
    end
    
    % Plot mean activity with error bars for each condition
    h(end+1) = errorbar(x_values, condition_mean_activity, condition_std_error, 'o-', ...
                        'LineWidth', 1.5, 'MarkerSize', 6, 'MarkerFaceColor', color, 'Color', color);
    
    % Append results to overall arrays
    mean_activity = [mean_activity; condition_mean_activity];
    std_error = [std_error; condition_std_error];
end

hold off;

% Set the sectioned x-axis
set(gca, 'XTick', 1:length(mean_activity));
set(gca, 'XTickLabel', x_tick_labels);

% Adding section dividers and labels below the graph
hold on;
section_boundaries = [7.5, 14.5, 21.5]; % Section boundaries for separating conditions
for b = section_boundaries
    plot([b b], ylim, 'k--');
end

% Labels and title
ylabel('Normalized Activity', 'FontSize', 18, 'FontWeight', 'bold'); % Increased font size and bold
title('Activity Under Different Lighting Conditions', 'FontSize', 20, 'FontWeight', 'bold'); % Increased font size and bold
xlim([0, length(mean_activity)+1]);

% Improve visibility and aesthetics
grid on;
legend(h, validConditions, 'Location', 'Best', 'FontSize', 12); % Improved font size for the legend
hold off;

saveas(gcf, fullfile(output_directory, sprintf('Pooled--ActivityOverTime.png')));
