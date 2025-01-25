% Load data
data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyEphys/EphysActivityData.csv');
save_directory = '/Users/noahmuscat/Desktop';

% Ensure 'RelativeDay' is numeric and integer
if ~isnumeric(data.RelativeDay)
    data.RelativeDay = str2double(string(data.RelativeDay));
end
data.RelativeDay = floor(data.RelativeDay);

% Define the desired order of conditions
conditionOrder = {'300Lux', '1000Lux1', '1000Lux4', 'sleep_deprivation'};
validConditionOrder = {'300Lux', '1000Lux1', '1000Lux4', 'sleepDeprivation'};


% Convert 'Condition' and 'Animal' into categorical variables
data.Condition = categorical(data.Condition, conditionOrder, 'Ordinal', true);
data.Animal = categorical(data.Animal);

% Convert 'RelativeDay' to categorical
data.RelativeDay = categorical(data.RelativeDay);

function plotZTActivity48Hours(data, conditionOrder, save_directory, validConditionOrder)
    % Convert 'ZT_Time' to categorical if not already
    if ~iscategorical(data.ZT_Time)
        data.ZT_Time = categorical(data.ZT_Time, 0:23, 'Ordinal', true);
    end

    % Prepare the figure for stacked subplots
    figure;
    total_hours = 0:47; % 48-hour range for the plot
    
    for condIdx = 1:length(conditionOrder)
        condition = conditionOrder{condIdx};
        validCondition = validConditionOrder{condIdx};
        
        % Filter the data for this specific condition
        thisConditionData = data(data.Condition == condition, :);
        
        % Determine days, and select last 4 or all days if < 8 unique days
        uniqueDays = unique(thisConditionData.RelativeDay);
        numUniqueDays = length(uniqueDays);
        
        if numUniqueDays < 8
            selectedDays = uniqueDays;
        else
            selectedDays = uniqueDays(end-3:end); % Select last 4 days
        end
        
        % Filter data for the selected days
        filteredData = thisConditionData(ismember(thisConditionData.RelativeDay, selectedDays), :);
        
        % Calculate mean NormalizedActivity for each ZT hour
        hourlyMeans = varfun(@mean, filteredData, 'InputVariables', 'NormalizedActivity', ...
                             'GroupingVariables', 'ZT_Time');
                         
        % Duplicate the 24-hour data to create a 48-hour cycle
        activity48Hours = [hourlyMeans.mean_NormalizedActivity; hourlyMeans.mean_NormalizedActivity];

        % Prepare vertically stacked subplot
        subplot(length(conditionOrder), 1, condIdx);
        
        % Plot the 48-hour cycle
        plot(total_hours, activity48Hours, 'b-', 'LineWidth', 2);
        hold on;
        
        % Highlight min and max for each 24-hour cycle
        [minVal1, minIdx1] = min(activity48Hours(1:24));
        [maxVal1, maxIdx1] = max(activity48Hours(1:24));
        [minVal2, minIdx2] = min(activity48Hours(25:48));
        [maxVal2, maxIdx2] = max(activity48Hours(25:48));
        
        plot(total_hours(minIdx1), minVal1, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
        plot(total_hours(maxIdx1), maxVal1, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
        plot(total_hours(minIdx2 + 24), minVal2, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
        plot(total_hours(maxIdx2 + 24), maxVal2, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
        
        xlabel('ZT Hour');
        ylabel('Normalized Activity', 'FontSize', 8);
        title(['Activity Over 48 Hours - ', char(validCondition)]);
        xticks(0:6:48);
        xlim([-0.5, 47.5]); % Ensure all 48 hours are visible
        grid on;

        % Force the y-axis to auto-scale to fit all plot elements
        ylim([-1 1.5]);
        
        % Retrieve y-axis limits after plotting and auto-scaling
        yLimit = ylim;
        
        % Add gray shading from ZT 12 to ZT 23 and from ZT 36 to ZT 47
        fill([12 23 23 12], [yLimit(1) yLimit(1) yLimit(2) yLimit(2)], [0.7 0.7 0.7], ...
             'EdgeColor', 'none', 'FaceAlpha', 0.5);
        fill([36 47 47 36], [yLimit(1) yLimit(1) yLimit(2) yLimit(2)], [0.7 0.7 0.7], ...
             'EdgeColor', 'none', 'FaceAlpha', 0.5);
        hold off;
    end

    % Assign filename and save
    save_filename = 'ZTActivity48HoursByCondition.png';
    saveas(gcf, fullfile(save_directory, save_filename));
end

% Example call to the function
plotZTActivity48Hours(data, conditionOrder, save_directory, validConditionOrder);
