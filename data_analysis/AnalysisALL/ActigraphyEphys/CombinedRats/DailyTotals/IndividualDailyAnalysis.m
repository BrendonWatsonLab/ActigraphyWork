%% Overview
% This script analyzes normalized activity data for each animal, calculates the mean and standard error
% for each condition and day, and generates separate plots for each animal.

% Reading in table
fprintf('Reading in table\n');

% Reads in data from .csv
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyEphys/EphysCohortData.csv');
output_directory = '/Users/noahmuscat/Desktop';

% Define conditions and their corresponding day ranges
conditions = {'300Lux', '1000Lux1', '1000Lux4', 'sleep_deprivation'};
day_ranges = {1:7, 1:7, 1:7, 1:3}; % Day ranges for each condition
colors = {'b', 'r', 'k', 'g'}; % Colors for each condition

% Get a list of unique animals from the data
animals = unique(combined_data.Animal);

for a = 1:length(animals)
    animal = animals{a};
    
    fprintf('Processing animal: %s\n', animal);
    
    % Filter data for the current animal
    animal_data = combined_data(strcmp(combined_data.Animal, animal), :);

    % Initialize storage for aggregated data
    allData = {}; 
    mean_activity = [];
    std_error = [];
    x_ticks = {};
    x_tick_labels = {};
    h = []; % Array to store plot handles for legend

    % Aggregate and average the data by relative day and condition
    for c = 1:length(conditions)
        condition = conditions{c};
        day_range = day_ranges{c};
        
        for day = day_range
            % Filter data for the current condition, day, and animal
            dayData = animal_data(strcmp(animal_data.Condition, condition) & ...
                                  animal_data.RelativeDay >= day & ...
                                  animal_data.RelativeDay < day+1, :);
            
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

    if isempty(allData)
        fprintf('No data available for animal: %s\n', animal);
        continue; % Skip plotting if there is no data for this animal
    end

    % Convert to table for easier manipulation and plotting
    allDataTable = cell2table(allData, 'VariableNames', {'Condition', 'Day', 'MeanNormalizedActivity', 'StdError'});
    
    figure;
    hold on;

    for c = 1:length(conditions)
        condition = conditions{c};
        color = colors{c};
        condition_mean_activity = [];
        condition_std_error = [];
        day_range = day_ranges{c};

        for d = day_range
            % Filter the table for the current condition and day
            idx = strcmp(allDataTable.Condition, condition) & allDataTable.Day == d;
            if sum(idx) == 0
                continue; % Skip if the day is missing in this condition for the animal
            end
            condition_mean_activity = [condition_mean_activity; allDataTable.MeanNormalizedActivity(idx)];
            condition_std_error = [condition_std_error; allDataTable.StdError(idx)];
            x_ticks = [x_ticks; sprintf('%s Day %d', condition, d)];
            
            % Short x-tick label for plotting (Just the days)
            x_tick_labels = [x_tick_labels; num2str(d)];
        end

        if isempty(condition_mean_activity)
            continue; % Skip if there is no data for the entire condition
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

    % Add custom x-axis labels below the graph for each condition
    text(3.5, min(ylim)-0.05*range(ylim), '300Lux', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
    text(10.5, min(ylim)-0.05*range(ylim), '1000Lux1', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
    text(17.5, min(ylim)-0.05*range(ylim), '1000Lux4', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
    text(24.5, min(ylim)-0.05*range(ylim), 'sleep_deprivation', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');

    % Labels and title
    ylabel('Mean Normalized Activity', 'FontSize', 18, 'FontWeight', 'bold');
    title(sprintf('Activity for Animal %s Under Different Lighting Conditions', animal), 'FontSize', 20, 'FontWeight', 'bold');
    xlim([0, length(mean_activity)+1]);

    % Improve visibility and aesthetics
    grid on;
    legend(h, conditions, 'Location', 'Best', 'FontSize', 12);
    hold off;

    % Save the figure
    saveas(gcf, fullfile(output_directory, sprintf('%s--ActivityOverTime.png', animal)));
end