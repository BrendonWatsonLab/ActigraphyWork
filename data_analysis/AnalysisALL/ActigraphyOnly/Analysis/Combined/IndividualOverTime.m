% Reading in table
fprintf('Reading in table\n');

% Read in data from .csv
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyOnly/AOActivityData.csv');
save_directory = '/Users/noahmuscat/Desktop';


% Determine maximum number of days for each condition
conditions = {'300Lux', '1000Lux', 'FullDark', '300LuxEnd'};
max_day_per_condition = zeros(1, length(conditions));

for i = 1:length(conditions)
    condition = conditions{i};
    max_day_per_condition(i) = floor(max(combined_data.RelativeDay(strcmp(combined_data.Condition, condition))));
end

% Define male and female animals
maleAnimals = {'AO1', 'AO2', 'AO3', 'AO7'};
femaleAnimals = {'AO4', 'AO5', 'AO6', 'AO8'};

% Separate data for males and females
maleData = combined_data(ismember(combined_data.Animal, maleAnimals), :);
femaleData = combined_data(ismember(combined_data.Animal, femaleAnimals), :);

% Function to aggregate data by day
function analyzedData = aggregate_data_by_day(data, conditions, max_days)
    analyzedData = {};
    
    for c = 1:length(conditions)
        condition = conditions{c};
        max_day = max_days(c);
        
        for day = 1:max_day
            dailyData = data(strcmp(data.Condition, condition) & ...
                             floor(data.RelativeDay) == day, :);
            
            if isempty(dailyData)
                continue;
            end
            
            % Calculate daily mean and standard error for NormalizedActivity
            meanNormalizedActivity = mean(dailyData.NormalizedActivity);
            stdError = std(dailyData.NormalizedActivity) / sqrt(height(dailyData));
            analyzedData = [analyzedData; {condition, day, meanNormalizedActivity, stdError}];
        end
    end
end

% Perform aggregation for males and females
maleAnalyzedData = aggregate_data_by_day(maleData, conditions, max_day_per_condition);
femaleAnalyzedData = aggregate_data_by_day(femaleData, conditions, max_day_per_condition);

% Convert the aggregated data into tables for easier manipulation
maleAnalyzedTable = cell2table(maleAnalyzedData, 'VariableNames', {'Condition', 'Day', 'MeanNormalizedActivity', 'StdError'});
femaleAnalyzedTable = cell2table(femaleAnalyzedData, 'VariableNames', {'Condition', 'Day', 'MeanNormalizedActivity', 'StdError'});

% List of all unique animals in the data
allAnimals = unique(combined_data.Animal);

% Desired order of conditions
desiredOrder = {'300Lux', '1000Lux', 'FullDark', '300LuxEnd'};

% Define colors for each condition consistently
colorMap = containers.Map;
colorMap('300Lux') = 'b';   % Blue
colorMap('1000Lux') = 'r';  % Red
colorMap('FullDark') = 'k'; % Black
colorMap('300LuxEnd') = 'g'; % Green

% Function to plot data and save the figure for individual animals
function plot_individual_animal(animal, data, save_directory, desiredOrder, colorMap)
    % Get conditions for this animal in desired order, if present
    conditions = intersect(desiredOrder, unique(data.Condition), 'stable');
    max_day_per_condition = zeros(1, length(conditions));
    
    % Calculate maximum days for each (existing) condition
    for i = 1:length(conditions)
        condition = conditions{i};
        max_day_per_condition(i) = floor(max(data.RelativeDay(strcmp(data.Condition, condition))));
    end

    analyzedData = aggregate_data_by_day(data, conditions, max_day_per_condition);
    analyzedTable = cell2table(analyzedData, 'VariableNames', {'Condition', 'Day', 'MeanNormalizedActivity', 'StdError'});

    % Plotting
    figure;
    hold on;

    plot_offset = 0;
    label_positions = [];
    legend_handles = [];
    x_tick_labels = [];
    x_tick_positions = [];

    for c = 1:length(conditions)
        condition = conditions{c};
        color = colorMap(condition);  % Use predefined color map
        max_day = max_day_per_condition(c);

        conditionData = analyzedTable(strcmp(analyzedTable.Condition, condition), :);
        x_values = plot_offset + (1:height(conditionData))';

        if ~isempty(conditionData)
            meanActivity = conditionData.MeanNormalizedActivity;
            stdError = conditionData.StdError;

            h = errorbar(x_values, meanActivity, stdError, 'o-', 'LineWidth', 1.5, 'MarkerSize', 6, ...
                         'MarkerFaceColor', color, 'Color', color);
            legend_handles = [legend_handles, h];

            fill([x_values; flipud(x_values)], ...
                 [meanActivity - stdError; flipud(meanActivity + stdError)], ...
                 color, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

            x_tick_labels = [x_tick_labels, 1:3:max_day];
            x_tick_positions = [x_tick_positions, plot_offset + (1:3:max_day)];

            plot_offset = plot_offset + max_day;
            label_positions = [label_positions, plot_offset];
        end
    end

    set(gca, 'XTick', x_tick_positions);
    set(gca, 'XTickLabel', x_tick_labels);

    for i = 1:length(label_positions)
        xline(label_positions(i), '--k', 'LineWidth', 1.5);
    end

    ylabel('Normalized Activity');
    title(sprintf('Activity Over Time - %s', animal));
    xlim([0, plot_offset + 1]);
    legend(legend_handles, conditions, 'Location', 'Best');
    grid on;

    % Save the figure
    save_filename = sprintf('%s--ActivityOverTime.png', animal); % Construct the filename
    saveas(gcf, fullfile(save_directory, save_filename)); % Save the figure

    hold off;
end

% Loop through each animal to generate and save plots
for i = 1:length(allAnimals)
    animal = allAnimals{i};
    animalData = combined_data(strcmp(combined_data.Animal, animal), :);
    plot_individual_animal(animal, animalData, save_directory, desiredOrder, colorMap);
end