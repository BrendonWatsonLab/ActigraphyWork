%% Reading in table
fprintf('Reading in table\n');

% reads in data from .csv
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/AO1-8Dark_binned_data.csv');

%% Determine maximum number of days for each condition
conditions = {'300Lux', '1000Lux', 'FullDark', '300LuxEnd'};
max_day_per_condition = zeros(1, length(conditions));

for i = 1:length(conditions)
    condition = conditions{i};
    max_day_per_condition(i) = floor(max(combined_data.RelativeDay(strcmp(combined_data.Condition, condition))));
end

%% Plotting
fprintf('Aggregating and averaging data by relative day, condition, and animal...\n');
allAnimalData = {};
colors = {'b', 'r', 'k', 'g'}; % Colors for each condition, ensure to have at least 4 different colors

% Compute mean normalized activity for each animal per day per condition
for c = 1:length(conditions)
    condition = conditions{c};
    day_range = 1:2:max_day_per_condition(c); % Modify to plot every other day only
    for day = day_range % Up to max days per condition, every other day
        uniqueAnimals = unique(combined_data.Animal);
        for a = 1:length(uniqueAnimals)
            animal = uniqueAnimals{a};
            % Skip new conditions for AO1-4
            if ismember(animal, {'AO1', 'AO2', 'AO3', 'AO4'}) && ismember(condition, {'FullDark', '300LuxEnd'})
                continue;
            end
            
            % Use floor to categorize by the integer part of RelativeDay
            animalDayData = combined_data(strcmp(combined_data.Condition, condition) & ...
                                          floor(combined_data.RelativeDay) == day & ...
                                          strcmp(combined_data.Animal, animal), :);
            
            if isempty(animalDayData)
                continue; % Skip if there is no data for this animal, day, and condition
            end
            
            meanNormalizedActivity = mean(animalDayData.NormalizedActivity);
            % Append to result arrays
            allAnimalData = [allAnimalData; {condition, day, animal, meanNormalizedActivity}];
        end
    end
end

% Convert to table for easier processing
allAnimalDataTable = cell2table(allAnimalData, 'VariableNames', {'Condition', 'Day', 'Animal', 'MeanNormalizedActivity'});

% Initialize arrays for plot data
mean_activity = [];
std_error = [];
x_ticks = [];
x_tick_labels = {};

h = []; % Array to store plot handles for legend

figure;
hold on;

plot_offset = 0; % Keeps track of the x-axis offset for plotting
label_positions = [];

for c = 1:length(conditions)
    condition = conditions{c};
    color = colors{c};
    condition_mean_activity = [];
    condition_std_error = [];
    
    day_range = 1:2:max_day_per_condition(c); % Modify to plot every other day only for the current condition
    
    for d = day_range
        % Filter the table for the current condition and day
        dayConditionData = allAnimalDataTable(strcmp(allAnimalDataTable.Condition, condition) & allAnimalDataTable.Day == d, :);
        
        if isempty(dayConditionData)
            continue;
        end
        
        % Calculate the mean and standard error using the animal means
        meanActivityPerAnimal = dayConditionData.MeanNormalizedActivity;
        overallMean = mean(meanActivityPerAnimal);
        overallStdError = std(meanActivityPerAnimal) / sqrt(length(meanActivityPerAnimal));
        
        condition_mean_activity = [condition_mean_activity; overallMean];
        condition_std_error = [condition_std_error; overallStdError];
        x_ticks = [x_ticks, plot_offset + length(condition_mean_activity)]; % Track the positions for x-ticks
        x_tick_labels = [x_tick_labels, sprintf('%d', d)];
    end
    
    % Create the x-axis values specific to each condition
    x_values = plot_offset + (1:length(day_range)); % Adjust spacing for every other day
    
    % Plotting with color for the condition and adding error bars
    h(end+1) = errorbar(x_values, condition_mean_activity, condition_std_error, 'o-', ...
                        'LineWidth', 1.5, 'MarkerSize', 6, 'MarkerFaceColor', color, 'Color', color);
    
    % Store label positions for section dividers
    label_positions = [label_positions, plot_offset + length(day_range)];
    
    % Update the plot offset for the next condition
    plot_offset = plot_offset + length(day_range); % No extra space needed
    
    % Append results to overall arrays
    mean_activity = [mean_activity; condition_mean_activity];
    std_error = [std_error; condition_std_error];
end

hold off;

% Setting the sectioned x-axis
set(gca, 'XTick', 1:plot_offset);
set(gca, 'XTickLabel', x_tick_labels);

% Adding section dividers and labels below the graph
hold on;
for i = 1:length(label_positions)
    plot([label_positions(i) label_positions(i)], ylim, 'k--', 'LineWidth', 1.5);
end

% Labels and title
ylabel('Mean Normalized Activity', 'FontSize', 20, 'FontWeight', 'bold'); % Larger font size for the y-label
title('Activity Under Different Lighting Conditions', 'FontSize', 20, 'FontWeight', 'bold');
xlim([0, plot_offset]);

% Improving Visibility and Aesthetics
set(gca, 'FontSize', 20); % Set the axis tick labels font size
grid on;
legend(h, conditions, 'Location', 'Best', 'FontSize', 20);
hold off;