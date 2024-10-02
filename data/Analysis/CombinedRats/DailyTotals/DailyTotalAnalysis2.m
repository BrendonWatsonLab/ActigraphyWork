% Almost the same code as DailyTotalAnalysis, but instead calculates means per day per animal and uses that to create error bars. 

%% Reading in table
fprintf('Reading in table');

% reads in data from .csv
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyEphys/ZT/CombinedRelDaysBinned.csv');

%% Plotting
conditions = {'300Lux', '1000Lux1', '1000Lux4'};
day_range = 1:7;
% Now, aggregate and average the data by relative day and condition
fprintf('Aggregating and averaging data by relative day, condition, and animal...\n');
allAnimalData = {};
conditionDayLabels = {};
colors = {'b', 'r', 'k'}; % Colors for each condition

% Compute mean normalized activity for each animal per day per condition
for c = 1:length(conditions)
    condition = conditions{c};
    for day = 1:7 % Maximum of 7 days per condition
        uniqueAnimals = unique(combined_data.Rat);
        for a = 1:length(uniqueAnimals)
            animal = uniqueAnimals{a};
            animalDayData = combined_data(strcmp(combined_data.Condition, condition) & ...
                                          combined_data.RelativeDay >= day & ...
                                          combined_data.RelativeDay < day+1 & ...
                                          strcmp(combined_data.Rat, animal), :);
            
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
allAnimalDataTable = cell2table(allAnimalData, 'VariableNames', {'Condition', 'Day', 'Rat', 'MeanNormalizedActivity'});

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
        x_ticks = [x_ticks; sprintf('%s Day %d', condition, d)];
        
        % Short x-tick label for plotting (Just the days)
        x_tick_labels = [x_tick_labels; num2str(d)];
    end
    
    % Create the x-axis values specific to each condition
    x_values = (c-1)*7 + (1:length(condition_mean_activity));
    
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
section_boundaries = [7.5, 14.5]; % Middle points between day groups
for b = section_boundaries
    plot([b b], ylim, 'k--', 'LineWidth', 1.5);
end

% Adjust custom x-axis labels below the graph
text_y_pos = min(ylim)-0.1*range(ylim); % Adjusted y position to avoid overlap
text(3.5, text_y_pos, '300Lux', 'HorizontalAlignment', 'center', 'FontSize', 20, 'FontWeight', 'bold');
text(10.5, text_y_pos, '1000Lux1', 'HorizontalAlignment', 'center', 'FontSize', 20, 'FontWeight', 'bold');
text(17.5, text_y_pos, '1000Lux4', 'HorizontalAlignment', 'center', 'FontSize', 20, 'FontWeight', 'bold');

% Labels, title, and x-axis adjustment
ylabel('Mean Normalized Activity', 'FontSize', 20, 'FontWeight', 'bold'); % Larger font size for the y-label
title('Activity Under Different Lighting Conditions', 'FontSize', 20, 'FontWeight', 'bold');
xlim([0, length(mean_activity)+1]);

% Improving Visibility and Aesthetics
set(gca, 'FontSize', 20); % Set the axis tick labels font size
grid on;
legend(h, conditions, 'Location', 'Best', 'FontSize', 20);
hold off;
%% Creating Per Day Plots
% Unique animals in the dataset
uniqueAnimals = unique(combined_data.Rat);

for a = 1:length(uniqueAnimals)
    animal = uniqueAnimals{a};
    fprintf('Generating plot for animal: %s\n', animal);
    
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
        
        for d = day_range
            % Filter the data for the current animal, condition, and day
            dayConditionData = combined_data(strcmp(combined_data.Condition, condition) & ...
                                             combined_data.RelativeDay >= d & ...
                                             combined_data.RelativeDay < d+1 & ...
                                             strcmp(combined_data.Rat, animal), :);

            if isempty(dayConditionData)
                continue;
            end
            
            % Calculate the mean and standard error for the current day and condition
            meanActivity = mean(dayConditionData.NormalizedActivity);
            stdError = std(dayConditionData.NormalizedActivity) / sqrt(height(dayConditionData));
            
            % Store mean and error values
            condition_mean_activity = [condition_mean_activity; meanActivity];
            condition_std_error = [condition_std_error; stdError];
            x_ticks = [x_ticks; sprintf('%s Day %d', condition, d)];
            
            % Short x-tick label for plotting (Just the days)
            x_tick_labels = [x_tick_labels; num2str(d)];
        end
        
        % Only plot if there's data for the condition
        if ~isempty(condition_mean_activity)
            % Create the x-axis values specific to each condition
            x_values = (c-1)*7 + (1:length(condition_mean_activity));
            
            % Plotting with color for the condition and adding error bars
            h(end+1) = errorbar(x_values, condition_mean_activity, condition_std_error, 'o-', ...
                                'LineWidth', 1.5, 'MarkerSize', 6, 'MarkerFaceColor', color, 'Color', color);
            
            % Append results to overall arrays
            mean_activity = [mean_activity; condition_mean_activity];
            std_error = [std_error; condition_std_error];
        end
    end

    hold off;

    % Only set the sectioned x-axis if there is mean activity to plot
    if ~isempty(mean_activity)
        set(gca, 'XTick', 1:length(mean_activity));
        set(gca, 'XTickLabel', x_tick_labels);

        % Adding section dividers and labels below the graph
        hold on;
        section_boundaries = [7.5, 14.5]; % Middle points between day groups
        for b = section_boundaries
            plot([b b], ylim, 'k--');
        end

        % Add custom x-axis labels below the graph
        text(3.5, min(ylim)-0.05*range(ylim), '300Lux', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
        text(10.5, min(ylim)-0.05*range(ylim), '1000Lux1', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
        text(17.5, min(ylim)-0.05*range(ylim), '1000Lux4', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');

        % Labels and title
        ylabel('Mean Normalized Activity');
        title(['Activity Under Different Lighting Conditions for Animal: ', animal]);
        xlim([0, length(mean_activity)+1]);
    end

    % Improving Visibility and Aesthetics
    grid on;
    legend(h, conditions, 'Location', 'Best');
    hold off;
end