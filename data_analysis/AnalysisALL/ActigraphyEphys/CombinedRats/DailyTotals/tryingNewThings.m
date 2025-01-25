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
max_day_per_condition = [36, 32, 35, 4];

% Function to aggregate data by day and by animal
function [pooledData, individualData] = aggregate_data_by_day_and_animal(data, conditions, max_days)
    pooledData = {};
    individualData = containers.Map();
    
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
            pooledData = [pooledData; {condition, day, meanNormalizedActivity, stdError}];
            
            % Calculate mean for each animal and store in a map
            uniqueAnimals = unique(dailyData.Animal);
            for i = 1:length(uniqueAnimals)
                animal = uniqueAnimals{i};
                animalData = dailyData(strcmp(dailyData.Animal, animal), :);  % Use strcmp for string comparison
                animalMean = mean(animalData.NormalizedActivity);
                
                if isKey(individualData, animal)
                    individualData(animal) = [individualData(animal); {condition, day, animalMean}];
                else
                    individualData(animal) = {condition, day, animalMean};
                end
            end
        end
    end
end

% Perform aggregation for pooled and individual Ephys animals
[pooledData, individualData] = aggregate_data_by_day_and_animal(data, conditions, max_day_per_condition);

% Convert the aggregated data into a table
pooledTable = cell2table(pooledData, 'VariableNames', {'Condition', 'Day', 'MeanNormalizedActivity', 'StdError'});

% Function to plot data and save the figure
function plot_data_and_save(groupName, pooledTable, individualData, conditions, colors, max_day_per_condition, save_directory)
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

        conditionPooledData = pooledTable(strcmp(pooledTable.Condition, condition), :);
        x_values = plot_offset + (1:height(conditionPooledData))';
        
        meanActivity = conditionPooledData.MeanNormalizedActivity;
        stdError = conditionPooledData.StdError;
        
        % Plot the pooled means
        h_pooled = errorbar(x_values, meanActivity, stdError, 'o-', 'LineWidth', 2, 'MarkerSize', 6, ...
                            'MarkerFaceColor', color, 'Color', color);
        legend_handles = [legend_handles, h_pooled];
        
        fill([x_values; flipud(x_values)], ...
             [meanActivity - stdError; flipud(meanActivity + stdError)], ...
             color, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        
        % Plot individual animal lines
        animalKeys = keys(individualData);
        for k = 1:length(animalKeys)
            animal = animalKeys{k};
            animalData = cell2mat(individualData(animal));
            animalConditionData = animalData(strcmp(animalData(:,1), condition), :);
            
            if isempty(animalConditionData)
                continue;
            end
            
            animalXValues = plot_offset + cell2mat(animalConditionData(:,2));
            animalMeans = cell2mat(animalConditionData(:,3));
            
            plot(animalXValues, animalMeans, 'LineWidth', 1, 'Color', [0.7 0.7 0.7]);  % Lighter line for individual animals
        end
        
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
    legend(legend_handles, conditions, 'Location', 'Best');
    grid on;

    % Save the figure
    save_filename = sprintf('%s--ActivityOverTime.png', groupName);
    saveas(gcf, fullfile(save_directory, save_filename));
end

% Define colors for conditions
colors = {'b', 'r', 'k', 'g'};

% Plot and save pooled data for all Ephys animals
plot_data_and_save('PooledEphys', pooledTable, individualData, conditions, colors, max_day_per_condition, save_directory);