% Load data
data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyEphys/EphysActivityData.csv');
save_directory = '/Users/noahmuscat/Desktop';

% Ensure 'RelativeDay' is numeric and integer
if ~isnumeric(data.RelativeDay)
    data.RelativeDay = str2double(string(data.RelativeDay));
end
data.RelativeDay = floor(data.RelativeDay);

% Specify conditions for Ephys animals and their desired max days
conditions = {'300Lux', '1000Lux1', '1000Lux4', 'sleep_deprivation'};
validConditions = {'300Lux', '1000Lux1', '1000Lux4', 'sleepDeprivation'};
max_day_per_condition = zeros(1, length(conditions));

for i = 1:length(conditions)
    condition = conditions{i};
    max_day_per_condition(i) = floor(max(data.RelativeDay(strcmp(data.Condition, condition))));
end

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

% Perform aggregation for pooled Ephys animals
analyzedData = aggregate_data_by_day(data, conditions, max_day_per_condition);

% Convert the aggregated data into a table
analyzedTable = cell2table(analyzedData, 'VariableNames', {'Condition', 'Day', 'MeanNormalizedActivity', 'StdError'});

% Function to plot data and save the figure
function plot_data_and_save(groupName, analyzedTable, conditions, colors, max_day_per_condition, save_directory, validConditions)
    figure;
    hold on;
    
    plot_offset = 0;
    label_positions = [];
    legend_handles = [];
    x_tick_labels = [];
    x_tick_positions = [];
    
    for c = 1:length(conditions)
        condition = conditions{c};
        color = colors{c};
        max_day = max_day_per_condition(c);

        conditionData = analyzedTable(strcmp(analyzedTable.Condition, condition), :);
        x_values = plot_offset + (1:height(conditionData))';
        
        meanActivity = conditionData.MeanNormalizedActivity;
        stdError = conditionData.StdError;
        
        h = errorbar(x_values, meanActivity, stdError, 'o-', 'LineWidth', 1.5, 'MarkerSize', 6, ...
                     'MarkerFaceColor', color, 'Color', color);
        legend_handles = [legend_handles, h];
        
        fill([x_values; flipud(x_values)], ...
             [meanActivity - stdError; flipud(meanActivity + stdError)], ...
             color, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        
        % Update x_tick_labels and x_tick_positions to label every day
        x_tick_labels = [x_tick_labels, 1:1:max_day];
        x_tick_positions = [x_tick_positions, plot_offset + (1:1:max_day)];
        
        plot_offset = plot_offset + max_day;
        label_positions = [label_positions, plot_offset];
    end
    
    set(gca, 'XTick', x_tick_positions);  
    set(gca, 'XTickLabel', x_tick_labels);  
    
    for i = 1:length(label_positions)
        xline(label_positions(i), '--k', 'LineWidth', 1.5);
    end
    
    ylabel('Normalized Activity');
    title(sprintf('Activity Under Different Lighting Conditions - %s', groupName));
    xlim([0, plot_offset + 1]);
    legend(legend_handles, validConditions, 'Location', 'Best');
    grid on;

    % Save the figure
    save_filename = sprintf('%s--ActivityOverTime.png', groupName);
    saveas(gcf, fullfile(save_directory, save_filename));
end

% Define colors for conditions
colors = {'b', 'r', 'k', 'g'};

% Plot and save pooled data for all Ephys animals
plot_data_and_save('PooledEphys', analyzedTable, conditions, colors, max_day_per_condition, save_directory, validConditions);