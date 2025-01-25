% Load data
data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyEphys/EphysActivityData.csv');
save_directory = '/Users/noahmuscat/Desktop';

% Ensure 'RelativeDay' is numeric and integer
if ~isnumeric(data.RelativeDay)
    data.RelativeDay = str2double(string(data.RelativeDay));
end
data.RelativeDay = floor(data.RelativeDay);

% Define conditions for Ephys animals
conditions = {'300Lux', '1000Lux1', '1000Lux4', 'sleep_deprivation'};
validConditions = {'300Lux', '1000Lux1', '1000Lux4', 'sleepDeprivation'};


% Function to aggregate data by day and by animal
function individualData = aggregate_data_by_day_and_animal(data, conditions)
    individualData = containers.Map;

    for c = 1:length(conditions)
        condition = conditions{c};
        condData = data(strcmp(data.Condition, condition), :);
        
        uniqueAnimals = unique(condData.Animal);

        for i = 1:length(uniqueAnimals)
            animal = uniqueAnimals{i};
            animalData = condData(strcmp(condData.Animal, animal), :);
            uniqueDays = unique(animalData.RelativeDay);

            for day = uniqueDays'
                dailyData = animalData(animalData.RelativeDay == day, :);

                animalMean = mean(dailyData.NormalizedActivity);

                if isKey(individualData, animal)
                    individualData(animal) = [individualData(animal); {condition, day, animalMean}];
                else
                    individualData(animal) = {condition, day, animalMean};
                end
            end
        end
    end
end

% Perform aggregation for individual Ephys animals
individualData = aggregate_data_by_day_and_animal(data, conditions);

% Function to plot data for each animal
function plot_individual_data(animalName, animalData, conditions, colors, save_directory, validConditions)
    figure;
    hold on;
    
    plot_offset = 0;
    legend_handles = [];

    for c = 1:length(conditions)
        condition = conditions{c};
        color = colors{c};
        
        % Extract relevant data for this condition
        conditionMask = strcmp(animalData(:, 1), condition);
        conditionDays = cell2mat(animalData(conditionMask, 2));
        conditionMeans = cell2mat(animalData(conditionMask, 3));
        
        if isempty(conditionDays)
            continue;
        end
        
        x_values = plot_offset + conditionDays;
        
        % Plot the data for this animal
        h = plot(x_values, conditionMeans, 'o-', 'LineWidth', 1.5, 'MarkerSize', 6, ...
                 'MarkerFaceColor', color, 'Color', color);
        legend_handles = [legend_handles, h];
        
        plot_offset = plot_offset + max(conditionDays);
        
        % Draw separation line for conditions
        xline(plot_offset + 0.5, '--k', 'LineWidth', 1.5);
    end
    
    ylabel('Normalized Activity');
    title(sprintf('Activity Under Different Lighting Conditions - %s', animalName));
    xlim([0, plot_offset + 1]);
    grid on;
    
    % Create a legend
    legend(legend_handles, validConditions, 'Location', 'Best');

    % Save the figure
    save_filename = sprintf('%s--ActivityOverTime.png', animalName);
    saveas(gcf, fullfile(save_directory, save_filename));
    hold off;
end

% Define colors for conditions
colors = {'b', 'r', 'k', 'g'};

% Plot and save data for each individual animal
animalKeys = keys(individualData);
for k = 1:length(animalKeys)
    animalName = animalKeys{k};
    animalData = individualData(animalName);
    plot_individual_data(animalName, animalData, conditions, colors, save_directory, validConditions);
end