%% Overall analysis of circadian 24-hour activity
% calculates movement peaks PER animal, so just looking at peak time
% binned per hour (out of 24 hours) and summed

% Read in the combined data
combinedData = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyEphys/EphysCohortData.csv');

% List of rat IDs and conditions
ratIDs = unique(combinedData.Animal); % Automatically get unique rat IDs from the data
conditions = {'300Lux', '1000Lux1', '1000Lux4', 'sleep_deprivation'};

% Normalize condition names to be valid field names
validConditionNames = strcat('Cond_', conditions);

normalizedActivity = struct();
meanActivity48Hours = struct();

% Initialize structure to hold combined data for each condition
combinedActivity = struct();
for j = 1:length(validConditionNames)
    combinedActivity.(validConditionNames{j}) = [];
end

% Loop over each rat and condition to process data
for i = 1:length(ratIDs)
    ratID = ratIDs{i};
    
    for j = 1:length(conditions)
        condition = conditions{j};
        validCondition = validConditionNames{j};
        
        % Filter data for current rat and condition
        ratConditionData = combinedData(strcmp(combinedData.Animal, ratID) & strcmp(combinedData.Condition, condition), :);
        
        if ~isempty(ratConditionData)
            dateData = ratConditionData.Date; % Datetime data
            activityData = ratConditionData.NormalizedActivity;
            
            % Extract hour from datetime data
            hours = hour(dateData);
            
            % Bin data by hour (1-hour bins)
            edges = 0:24; % Correct edges to include 24 for completeness
            binIndices = discretize(hours, edges);
            
            % Remove NaN and zero indices
            validIndices = binIndices > 0;
            binIndices = binIndices(validIndices);
            activityData = activityData(validIndices);
            
            % Calculate sum of activity for each bin
            binnedActivity = accumarray(binIndices, activityData, [24, 1], @sum, NaN);
            
            % Calculate z-score normalization for the binned activity
            meanActivity = mean(binnedActivity, 'omitnan');
            stdActivity = std(binnedActivity, 'omitnan');
            
            if stdActivity == 0
                zscoredActivity = zeros(size(binnedActivity)); % Avoid division by zero
            else
                zscoredActivity = (binnedActivity - meanActivity) / stdActivity;
            end
            
            % Duplicate the 24-hour data to cover 48 hours
            zscoredActivity48 = [zscoredActivity; zscoredActivity];
            
            % Store results for each animal and condition
            normalizedActivity.(ratID).(validCondition).binnedActivity = zscoredActivity48;
            
            % Collect data for mean plot
            combinedActivity.(validCondition) = [combinedActivity.(validCondition); zscoredActivity48'];
            fprintf('Data added for Rat: %s, Condition: %s\n', ratID, condition);
        else
            fprintf('No data found for Rat: %s, Condition: %s\n', ratID, condition);
        end
    end
end

% Graphical representation of normalized activity for all rats and conditions
figure;
hold on;

% Add gray shading from ZT = 12 to ZT = 23
fill([12 23 23 12], [-3 -3 4 4], [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'HandleVisibility', 'off');
% Add gray shading from ZT = 36 to ZT = 47
fill([36 47 47 36], [-3 -3 4 4], [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'HandleVisibility', 'off');

% Plot all conditions together for comparison
colors = lines(length(conditions));
legendEntries = {};

for j = 1:length(validConditionNames)
    validCondition = validConditionNames{j};
    conditionPlotted = false;
    
    for i = 1:length(ratIDs)
        ratID = ratIDs{i};
        
        if isfield(normalizedActivity, ratID) && isfield(normalizedActivity.(ratID), validCondition)
            binnedActivity48 = normalizedActivity.(ratID).(validCondition).binnedActivity;
            
            % Plot each rat's z-score normalized activity data
            plot(0:47, binnedActivity48, 'DisplayName', sprintf('%s - %s', ratID, conditions{j}), 'Color', colors(j, :));
            conditionPlotted = true;
            legendEntries{end+1} = sprintf('%s - %s', ratID, conditions{j});
        end 
    end
    
    % Debug: Check if condition was plotted
    if ~conditionPlotted
        fprintf('Condition %s was not plotted for any rat.\n', validCondition);
    end
end

xlabel('Hour of the Day', 'FontSize', 20, 'FontWeight', 'bold');
ylabel('Normalized Activity', 'FontSize', 20, 'FontWeight', 'bold');
title('Normalized Activity Over 48 Hours for All Rats', 'FontSize', 20, 'FontWeight', 'bold');
legend(legendEntries, 'Location', 'BestOutside', 'FontSize', 20);
hold off;

disp('48-hour z-score normalized activity analysis and plots generated and saved.');

%% functions
% Function to add a shaded area to the current plot
function addShadedAreaToPlotZT48Hour()
    hold on;
    
    % Define x and y coordinates for the first shaded area (from t=12 to t=24)
    x_shaded1 = [12, 24, 24, 12];
    y_lim = ylim;
    y_shaded1 = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];
    
    % Define x and y coordinates for the second shaded area (from t=36 to t=48)
    x_shaded2 = [36, 48, 48, 36];
    y_shaded2 = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];
    
    fill_color = [0.7, 0.7, 0.7]; % Light gray color for the shading
    
    % Add shaded areas to the plot
    fill(x_shaded1, y_shaded1, fill_color, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    fill(x_shaded2, y_shaded2, fill_color, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    
    hold off;
end