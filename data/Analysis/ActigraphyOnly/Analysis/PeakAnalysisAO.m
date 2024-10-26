% List of animal IDs and conditions
animalIDs = {'AO1', 'AO2', 'AO3', 'AO4', 'AO5', 'AO6', 'AO7', 'AO8'};
conditions = {'300Lux', '1000Lux'};
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/binned_data.csv');

normalizedActivity = struct();

% Normalize condition names to be valid field names
validConditionNames = strcat('Cond_', conditions);

% Loop over each animal and condition
for i = 1:length(animalIDs)
    animalID = animalIDs{i};
    
    for j = 1:length(conditions)
        condition = conditions{j};   % Syntax fix: conditions{j}
        validCondition = validConditionNames{j};
        
        % Filter data for the current animal and condition
        dataTable = combined_data(strcmp(combined_data.Animal, animalID) & strcmp(combined_data.Condition, condition), :);

        % Check if there is data for this combination
        if ~isempty(dataTable)
            fprintf('Analyzing: Animal %s under %s\n', animalID, condition);
            
            % Assuming the data includes a 'Date' column in datetime format and a 'SelectedPixelDifference' column
            if ismember('Date', dataTable.Properties.VariableNames) && ismember('SelectedPixelDifference', dataTable.Properties.VariableNames)   % Change to 'NormalizedActivity' if required
                dateData = dataTable.Date; % Datetime data
                activityData = dataTable.SelectedPixelDifference; % Not sure whether it should be 'SelectedPixelDifference' or 'NormalizedActivity' - Please confirm
                
                % Extract hour from datetime data
                hours = hour(dateData);
                
                % Bin data by hour (1-hour bins)
                edges = 0:24;
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
                normalizedActivity.(animalID).(validCondition).binnedActivity = zscoredActivity48;
            else
                fprintf('Column "Date" or "SelectedPixelDifference" not found for Animal %s under %s\n', animalID, condition);
            end
        else
            fprintf('No data found for Animal %s under %s\n', animalID, condition);
        end
    end
end

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
    
    for i = 1:length(animalIDs)
        animalID = animalIDs{i};
        
        if isfield(normalizedActivity, animalID) && isfield(normalizedActivity.(animalID), validCondition)
            binnedActivity48 = normalizedActivity.(animalID).(validCondition).binnedActivity;
            
            % Plot each animal's z-score normalized activity data
            plot(0:47, binnedActivity48, 'DisplayName', sprintf('%s - %s', animalID, conditions{j}), 'Color', colors(j, :));
            hold on;
            
            legendEntries{end+1} = sprintf('%s - %s', animalID, conditions{j});
        end 
     end
end

xlabel('Hour of the Day', 'FontSize', 20, 'FontWeight', 'bold');
ylabel('Normalized Activity', 'FontSize', 20, 'FontWeight', 'bold');
title('Normalized Activity Over 48 Hours for All Animals', 'FontSize', 20, 'FontWeight', 'bold');
legend(legendEntries, 'Location', 'BestOutside', 'FontSize', 20);
hold off;

disp('48-hour z-score normalized activity analysis and plots generated and saved.');

normalizedActivity = struct();

% Normalize condition names to be valid field names
validConditionNames = strcat('Cond_', conditions);

% Loop over each animal and condition
for i = 1:length(animalIDs)
    animalID = animalIDs{i};
    
    for j = 1:length(conditions)
        condition = conditions{j};   % Syntax fix: conditions{j}
        validCondition = validConditionNames{j};
        
        % Filter data for the current animal and condition
        dataTable = combined_data(strcmp(combined_data.Animal, animalID) & strcmp(combined_data.Condition, condition), :);

        % Check if there is data for this combination
        if ~isempty(dataTable)
            fprintf('Analyzing: Animal %s under %s\n', animalID, condition);
            
            % Assuming the data includes a 'Date' column in datetime format and a 'SelectedPixelDifference' column
            if ismember('Date', dataTable.Properties.VariableNames) && ismember('SelectedPixelDifference', dataTable.Properties.VariableNames)   % Change to 'NormalizedActivity' if required
                dateData = dataTable.Date; % Datetime data
                activityData = dataTable.SelectedPixelDifference; % Not sure whether it should be 'SelectedPixelDifference' or 'NormalizedActivity' - Please confirm
                
                % Extract hour from datetime data
                hours = hour(dateData);
                
                % Bin data by hour (1-hour bins)
                edges = 0:24;
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
                normalizedActivity.(animalID).(validCondition).binnedActivity = zscoredActivity48;
            else
                fprintf('Column "Date" or "SelectedPixelDifference" not found for Animal %s under %s\n', animalID, condition);
            end
        else
            fprintf('No data found for Animal %s under %s\n', animalID, condition);
        end
    end
end

% Graphical representation of normalized activity
figure;
hold on;

% Add gray shading from ZT = 12 to ZT = 23
fill([12 23 23 12], [-1.5 -1.5 3 3], [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'HandleVisibility', 'off');
% Add gray shading from ZT = 36 to ZT = 47
fill([36 47 47 36], [-1.5 -1.5 3 3], [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'HandleVisibility', 'off');

% Plot the average activity for each condition
colors = lines(length(conditions));
legendEntries = {};

for j = 1:length(validConditionNames)
    validCondition = validConditionNames{j};
    allBinnedActivities = [];
    
    for i = 1:length(animalIDs)
        animalID = animalIDs{i};
        
        if isfield(normalizedActivity, animalID) && isfield(normalizedActivity.(animalID), validCondition)
            binnedActivity48 = normalizedActivity.(animalID).(validCondition).binnedActivity;
            allBinnedActivities = [allBinnedActivities; binnedActivity48'];
        end 
    end
    
    % Calculate the mean activity over all animals for this condition
    meanBinnedActivity48 = mean(allBinnedActivities, 1, 'omitnan');

    % Plot the mean activity for this condition
    plot(0:47, meanBinnedActivity48, 'DisplayName', conditions{j}, 'Color', colors(j, :), 'LineWidth', 2);
    hold on;
    
    legendEntries{end+1} = conditions{j};
end

xlabel('Hour of the Day', 'FontSize', 20, 'FontWeight', 'bold');
ylabel('Normalized Activity', 'FontSize', 20, 'FontWeight', 'bold');
title('Normalized Activity Over 48 Hours for All Conditions', 'FontSize', 20, 'FontWeight', 'bold');
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
    
    % Additional Plot settings
    xlabel('Hour of Day (ZT Time)');
    ylabel('Sum of PixelDifference');
    xlim([-0.5, 47.5]);
    xticks(0:1:47);
    xtickangle(90);
    
    hold off;
end

% Function to add a shaded area to the current plot
function addShadedAreaToPlotZT24Hour()
    hold on;
    % Define x and y coordinates for the shaded area (from t=12 to t=24)
    x_shaded = [12, 24, 24, 12];
    y_lim = ylim;
    y_shaded = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];

    fill_color = [0.7, 0.7, 0.7]; % Light gray color for the shading

    % Add shaded areas to the plot with 'HandleVisibility', 'off' to exclude from the legend
    fill(x_shaded, y_shaded, fill_color, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    
    % Additional Plot settings
    xlabel('Hour of Day (ZT Time)');
    ylabel('Sum of PixelDifference');
    xlim([-0.5, 23.5]);
    xticks(0:23);
    xtickangle(0);
    
    hold off;
end