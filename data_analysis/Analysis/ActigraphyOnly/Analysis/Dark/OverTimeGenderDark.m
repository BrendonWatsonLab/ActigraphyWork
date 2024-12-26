% Analysis for AO1-8, including dark conditions. Separated by male and
% female. 
%
% Average of SelectedPixelDifference
% 
% The stats are done by aggregating into daily means to ensure that
% the large amount of data points isn't skewing the data. Will output a
% line plot over time per day. 

% Reading in table
fprintf('Reading in table\n');

% Read in data from .csv
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/AOCohortData.csv');

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

% Aggregation and Averaging
maleData = combined_data(ismember(combined_data.Animal, maleAnimals), :);
femaleData = combined_data(ismember(combined_data.Animal, femaleAnimals), :);

% Separate data processing function
function analyzedData = aggregate_data_by_day(data, conditions, max_days)
    analyzedData = {};
    
    for c = 1:length(conditions)
        condition = conditions{c};
        max_day = max_days(c);
        
        % Aggregating data by day
        for day = 1:max_day
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

% Perform Aggregation
maleAnalyzedData = aggregate_data_by_day(maleData, conditions, max_day_per_condition);
femaleAnalyzedData = aggregate_data_by_day(femaleData, conditions, max_day_per_condition);

% Convert to tables for easier manipulation
maleAnalyzedTable = cell2table(maleAnalyzedData, 'VariableNames', {'Condition', 'Day', 'MeanSelectedPixelDifference', 'StdError'});
femaleAnalyzedTable = cell2table(femaleAnalyzedData, 'VariableNames', {'Condition', 'Day', 'MeanSelectedPixelDifference', 'StdError'});

% Plotting Function
function plot_data(groupName, analyzedTable, conditions, colors, max_day_per_condition)
    figure;
    hold on;
    
    plot_offset = 0;
    label_positions = [];
    legend_handles = [];
    x_tick_labels = [];
    x_tick_positions = []; % To store positions for the x-tick labels
    
    for c = 1:length(conditions)
        condition = conditions{c};
        color = colors{c};
        max_day = max_day_per_condition(c);
        
        conditionData = analyzedTable(strcmp(analyzedTable.Condition, condition), :);
        x_values = plot_offset + (1:height(conditionData))'; % X-values for plotting
        
        % Calculate mean, std, stderr
        meanActivity = conditionData.MeanSelectedPixelDifference;
        stdError = conditionData.StdError;
        
        % Plot with error bars
        h = errorbar(x_values, meanActivity, stdError, 'o-', 'LineWidth', 1.5, 'MarkerSize', 6, ...
                     'MarkerFaceColor', color, 'Color', color);
        legend_handles = [legend_handles, h];
        
        % Filling for std error
        fill([x_values; flipud(x_values)], ...
             [meanActivity - stdError; flipud(meanActivity + stdError)], ...
             color, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        
        % Add day labels for the x-axis
        x_tick_labels = [x_tick_labels, 1:max_day]; % Generate labels starting from 1 to max_day
        x_tick_positions = [x_tick_positions, plot_offset + (1:max_day)]; % Store their positions
        
        % Move the plot offset after the current condition
        plot_offset = plot_offset + max_day;        
        label_positions = [label_positions, plot_offset];
    end
    
    % Customize the x-axis labels to show days 1 to max_day per condition
    set(gca, 'XTick', x_tick_positions);
    set(gca, 'XTickLabel', x_tick_labels);
    
    for i = 1:length(label_positions)
        xline(label_positions(i), '--k', 'LineWidth', 1.5);
    end
    
    ylabel('Mean Selected Pixel Difference');
    title(sprintf('Activity Under Different Lighting Conditions - %s', groupName));
    xlim([0, plot_offset + 1]);
    legend(legend_handles, conditions, 'Location', 'Best');
    grid on;
end

% Define colors for conditions
colors = {'b', 'r', 'k', 'g'}; 

% Plotting data
plot_data('Males', maleAnalyzedTable, conditions, colors, max_day_per_condition);
plot_data('Females', femaleAnalyzedTable, conditions, colors, max_day_per_condition);