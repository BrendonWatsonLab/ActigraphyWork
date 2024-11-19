%% Over Many Days Analysis
% Using data directly from .csv
% uses mean of NormalizedActivity

% Reading in table
fprintf('Reading in table\n');

% reads in data from .csv
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyEphys/EphysCohortData.csv');

% Define conditions and their corresponding day ranges
conditions = {'300Lux', '1000Lux1', '1000Lux4', 'sleep_deprivation'};
day_ranges = {1:7, 1:7, 1:7, 1:3}; % day ranges for each condition
% day_range = 1:7; % Obsolete

% Now, aggregate and average the data by relative day and condition
fprintf('Aggregating and averaging data by relative day and condition...\n');
allData = {};
conditionDayLabels = {};
colors = {'b', 'r', 'k', 'g'}; % Colors for each condition, adding 'g' for the fourth condition

for c = 1:length(conditions)
    condition = conditions{c};
    day_range = day_ranges{c}; % Get the specific day range for the current condition
    for day = day_range
        dayData = combined_data(strcmp(combined_data.Condition, condition) & ...
                                combined_data.RelativeDay >= day & ...
                                combined_data.RelativeDay < day+1, :);
        
        if isempty(dayData)
            continue; % Skip if there is no data for this day and condition
        end
        
        meanNormalizedActivity = mean(dayData.NormalizedActivity);
        stdError = std(dayData.NormalizedActivity) / sqrt(height(dayData));
        
        % Append to result arrays
        allData = [allData; {condition, day, meanNormalizedActivity, stdError}];
    end
end

% Convert to table for easier plotting
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
    x_values = (c-1)*7 + (1:length(condition_mean_activity)); % multiplied by 7 so that there are gaps between the conditions in the plot
    if strcmp(condition, 'sleep_deprivation')
        x_values = (3*7) + (1:length(condition_mean_activity)); % Place 'sleep_deprivation' condition correctly after previous 3 conditions
    end
    
    % Plotting with color for the condition and adding error bars
    h(end+1) = errorbar(x_values, condition_mean_activity, condition_std_error, 'o-', ...
                        'LineWidth', 1.5, 'MarkerSize', 6, 'MarkerFaceColor', color, 'Color', color);
    
    % Append results to overall arrays
    mean_activity = [mean_activity; condition_mean_activity];
    std_error = [std_error; condition_std_error];
end

hold off;

% Setting the sectioned x-axis
set(gca, 'XTick', 1:length(mean_activity));
set(gca, 'XTickLabel', x_tick_labels);

% Adding section dividers and labels below the graph
hold on;
section_boundaries = [7.5, 14.5, 21.5]; % Added an additional boundary for the 4th condition
for b = section_boundaries
    plot([b b], ylim, 'k--');
end

% Add custom x-axis labels below the graph
text(3.5, min(ylim)-0.05*range(ylim), '300Lux', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
text(10.5, min(ylim)-0.05*range(ylim), '1000Lux1', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
text(17.5, min(ylim)-0.05*range(ylim), '1000Lux4', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
text(24.5, min(ylim)-0.05*range(ylim), 'sleep_deprivation', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');

% Labels and title
ylabel('Mean Normalized Activity');
title('Activity Under Different Lighting Conditions');
xlim([0, length(mean_activity)+1]);

% Improving Visibility and Aesthetics
grid on;
legend(h, conditions, 'Location', 'Best');
hold off;