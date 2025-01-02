% Analysis for AO1-8, including dark conditions. Separated by male and
% female.
%
% This script analyzes the SelectedPixelDifference for different groups 
% of animals under various lighting conditions (300Lux, 1000Lux, FullDark, 
% 300LuxEnd). The data is processed by aggregating into daily means to 
% avoid skewing due to a large number of data points. The script will 
% output line plots showing the trend of SelectedPixelDifference over 
% time for both male and female groups.

% Reading in table
fprintf('Reading in table\n');

% Read in data from .csv
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/AOCohortData.csv');

% Determine maximum number of days for each condition
conditions = {'300Lux', '1000Lux', 'FullDark', '300LuxEnd'};
max_day_per_condition = zeros(1, length(conditions));

for i = 1:length(conditions)
    condition = conditions{i};
    % Calculate the maximum number of days for each condition in the dataset
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
        
        % Aggregating data by day for each condition
        for day = 1:max_day
            % Extract daily data for the current condition and day
            dailyData = data(strcmp(data.Condition, condition) & ...
                             floor(data.RelativeDay) == day, :);
            
            if isempty(dailyData)
                continue;
            end
            
            % Calculate daily mean and standard error
            meanSelectedPixelDifference = mean(dailyData.SelectedPixelDifference);
            stdError = std(dailyData.SelectedPixelDifference) / sqrt(height(dailyData));
            analyzedData = [analyzedData; {condition, day, meanSelectedPixelDifference, stdError}];
        end
    end
end

% Perform aggregation for males and females
maleAnalyzedData = aggregate_data_by_day(maleData, conditions, max_day_per_condition);
femaleAnalyzedData = aggregate_data_by_day(femaleData, conditions, max_day_per_condition);

% Convert the aggregated data into tables for easier manipulation
maleAnalyzedTable = cell2table(maleAnalyzedData, 'VariableNames', {'Condition', 'Day', 'MeanSelectedPixelDifference', 'StdError'});
femaleAnalyzedTable = cell2table(femaleAnalyzedData, 'VariableNames', {'Condition', 'Day', 'MeanSelectedPixelDifference', 'StdError'});

% Function to plot data
function plot_data(groupName, analyzedTable, conditions, colors, max_day_per_condition)
    figure;
    hold on;
    
    plot_offset = 0; % Offset for x-axis based on conditions
    label_positions = []; % Store positions for x-axis labels
    legend_handles = []; % Store legend handles for each condition
    x_tick_labels = []; % Store x-tick labels
    x_tick_positions = []; % Store positions for x-tick labels
    
    for c = 1:length(conditions)
        condition = conditions{c};
        color = colors{c};
        max_day = max_day_per_condition(c);
        
        % Extract data for the current condition
        conditionData = analyzedTable(strcmp(analyzedTable.Condition, condition), :);
        x_values = plot_offset + (1:height(conditionData))'; % X-values for plotting
        
        meanActivity = conditionData.MeanSelectedPixelDifference;
        stdError = conditionData.StdError;
        
        % Plot data with error bars
        h = errorbar(x_values, meanActivity, stdError, 'o-', 'LineWidth', 1.5, 'MarkerSize', 6, ...
                     'MarkerFaceColor', color, 'Color', color);
        legend_handles = [legend_handles, h];
        
        % Fill area for standard error
        fill([x_values; flipud(x_values)], ...
             [meanActivity - stdError; flipud(meanActivity + stdError)], ...
             color, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        
        % Generate labels and positions for x-axis
        x_tick_labels = [x_tick_labels, 1:max_day];
        x_tick_positions = [x_tick_positions, plot_offset + (1:max_day)];
        
        plot_offset = plot_offset + max_day; % Update plot offset
        label_positions = [label_positions, plot_offset];
    end
    
    % Customize the x-axis labels to show days 1 to max_day per condition
    set(gca, 'XTick', x_tick_positions);
    set(gca, 'XTickLabel', x_tick_labels);
    
    % Add vertical lines to separate conditions
    for i = 1:length(label_positions)
        xline(label_positions(i), '--k', 'LineWidth', 1.5);
    end
    
    % Set plot labels and title
    ylabel('Mean Selected Pixel Difference');
    title(sprintf('Activity Under Different Lighting Conditions - %s', groupName));
    xlim([0, plot_offset + 1]);
    legend(legend_handles, conditions, 'Location', 'Best');
    grid on;
end

% Define colors for conditions
colors = {'b', 'r', 'k', 'g'}; 

% Plot data for males and females
plot_data('Males', maleAnalyzedTable, conditions, colors, max_day_per_condition);
plot_data('Females', femaleAnalyzedTable, conditions, colors, max_day_per_condition);