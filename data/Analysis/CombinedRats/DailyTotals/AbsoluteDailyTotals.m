% Same as dailytotalanalysis.m, but using SelectedPixelDifference instead
% of NormalizedActivity
%% Reading in table
% fprintf('Reading in table');

% reads in data from .csv
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyEphys/ZT/CombinedRelDaysBinned.csv');

%% Plotting Combined Stuff
conditions = {'300Lux', '1000Lux1', '1000Lux4'};
day_range = 1:7;
colors = {'b', 'r', 'k'}; % Colors for each condition

% Calculate mean and standard error for each rat per day per condition
allRatData = {};

for c = 1:length(conditions)
    condition = conditions{c};
    for day = 1:7 % Maximum of 7 days per condition
        uniqueRats = unique(combined_data.Rat);
        for a = 1:length(uniqueRats)
            rat = uniqueRats{a};
            ratDayData = combined_data(strcmp(combined_data.Condition, condition) & ...
                                       combined_data.RelativeDay >= day & ...
                                       combined_data.RelativeDay < day+1 & ...
                                       strcmp(combined_data.Rat, rat), :);
            
            if isempty(ratDayData)
                continue; % Skip if there is no data for this rat, day, and condition
            end
            
            meanSelectedPixelDifference = mean(ratDayData.SelectedPixelDifference);
            
            % Append to result arrays
            allRatData = [allRatData; {condition, day, rat, meanSelectedPixelDifference}];
        end
    end
end

% Convert to table for easier processing
allRatDataTable = cell2table(allRatData, 'VariableNames', {'Condition', 'Day', 'Rat', 'MeanSelectedPixelDifference'});

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
        dayConditionData = allRatDataTable(strcmp(allRatDataTable.Condition, condition) & allRatDataTable.Day == d, :);

        if isempty(dayConditionData)
            continue;
        end
        
        % Calculate the mean and standard error using the rat means
        meanActivityPerRat = dayConditionData.MeanSelectedPixelDifference;
        overallMean = mean(meanActivityPerRat);
        overallStdError = std(meanActivityPerRat) / sqrt(length(meanActivityPerRat));
        
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
    plot([b b], ylim, 'k--');
end

% Add custom x-axis labels below the graph
text(3.5, min(ylim)-0.05*range(ylim), '300Lux', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
text(10.5, min(ylim)-0.05*range(ylim), '1000Lux1', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
text(17.5, min(ylim)-0.05*range(ylim), '1000Lux4', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');

% Labels and title
ylabel('Mean Selected Pixel Difference');
title('Activity Under Different Lighting Conditions');
xlim([0, length(mean_activity)+1]);

% Improving Visibility and Aesthetics
grid on;
legend(h, conditions, 'Location', 'Best');
hold off;

%% Plotting Individuals

conditions = {'300Lux', '1000Lux1', '1000Lux4'};
day_range = 1:7;
colors = {'b', 'r', 'k'}; % Colors for each condition

% Unique rats in the dataset
uniqueRats = unique(combined_data.Rat);

for a = 1:length(uniqueRats)
    rat = uniqueRats{a};
    fprintf('Generating plot for rat: %s\n', rat);
    
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
            % Filter the data for the current rat, condition, and day
            dayConditionData = combined_data(strcmp(combined_data.Condition, condition) & ...
                                             combined_data.RelativeDay >= d & ...
                                             combined_data.RelativeDay < d+1 & ...
                                             strcmp(combined_data.Rat, rat), :);

            if isempty(dayConditionData)
                continue;
            end
            
            % Calculate the mean and standard error for the current day and condition
            meanActivity = mean(dayConditionData.SelectedPixelDifference);
            stdError = std(dayConditionData.SelectedPixelDifference) / sqrt(height(dayConditionData));
            
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
        ylabel('Mean Selected Pixel Difference');
        title(['Activity Under Different Lighting Conditions for Rat: ', rat]);
        xlim([0, length(mean_activity)+1]);
    end

    % Improving Visibility and Aesthetics
    grid on;
    legend(h, conditions, 'Location', 'Best');
    hold off;
end