%% Analysis of Rat Activity Data
% This script analyzes activity data of 8 rats under different lighting conditions,
% accounting for gender differences. The main steps include:
% 1. Assigning gender to each data point.
% 2. Classifying 1000Lux data into 'Start' and 'End' conditions.
% 3. Performing circadian running analysis.
% 4. Plotting 48-hour and 24-hour activity profiles by gender and condition.
% 5. Calculating and plotting differences in activity between conditions.

%% Synopsis
% This MATLAB script processes and analyzes activity data for eight rats,
% divided by gender and under different lighting conditions (300Lux, 1000LuxStart, 1000LuxEnd).
% The analysis includes assigning gender, segmenting 1000Lux data into 'Start' and 'End',
% circadian running analysis, plotting activity profiles over 48-hour and 24-hour periods,
% and calculating differences in mean activities between conditions.

%% Parameters
animalIDs = {'AO1', 'AO2', 'AO3', 'AO4', 'AO5', 'AO6', 'AO7', 'AO8'}; % List of animal IDs
genders = {'Male', 'Male', 'Male', 'Female', 'Female', 'Female', 'Male', 'Female'}; % Corresponding genders
conditions = {'300Lux', '1000LuxStart', '1000LuxEnd'}; % Conditions to analyze

% Read the combined data table
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/AOCohortData.csv');

% Display the column names to verify
disp('Column names in the data:');
disp(combined_data.Properties.VariableNames);

% Correct column name for SelectedPixelDifference
selectedPixelDifferenceColumn = 'SelectedPixelDifference';

%% Assign each data point a gender
combined_data.Gender = cell(height(combined_data), 1); % Initialize Gender column
for i = 1:length(animalIDs)
    animalIndices = strcmp(combined_data.Animal, animalIDs{i});
    combined_data.Gender(animalIndices) = repmat({genders{i}}, sum(animalIndices), 1); % Use curly braces to encapsulate in a cell array
end

%% Segmentation of 1000Lux into Start and End conditions
combined_data.Subcondition = combined_data.Condition;
for i = 1:length(animalIDs)
    animalID = animalIDs{i};
    % Filter data for `1000Lux` condition
    animal_1000Lux_data = combined_data(strcmp(combined_data.Animal, animalID) & strcmp(combined_data.Condition, '1000Lux'), :);
    
    if ~isempty(animal_1000Lux_data)
        unique_days = unique(floor(animal_1000Lux_data.RelativeDay));
        if length(unique_days) >= 14
            % First 7 days
            start_days = unique_days(1:7);
            start_indices = strcmp(combined_data.Animal, animalID) & strcmp(combined_data.Condition, '1000Lux') & ismember(floor(combined_data.RelativeDay), start_days);
            combined_data.Subcondition(start_indices) = {'1000LuxStart'};
            
            % Last 7 days
            end_days = unique_days(end-6:end);
            end_indices = strcmp(combined_data.Animal, animalID) & strcmp(combined_data.Condition, '1000Lux') & ismember(floor(combined_data.RelativeDay), end_days);
            combined_data.Subcondition(end_indices) = {'1000LuxEnd'};
        end
    end
end

%% Analyze Circadian Running
% Utilize a custom function for circadian running analysis
AnalyzeCircadianRunningGender(combined_data, false, 'All Rats');

%% Peak Analysis AO
selectedPixelDifferenceActivity = struct();

% Create valid condition names for struct fields
validConditionNames = strcat('Cond', conditions);

for i = 1:length(animalIDs)
    animalID = animalIDs{i};
    gender = genders{i};

    for j = 1:length(conditions)
        subcondition = conditions{j};  
        validSubcondition = validConditionNames{j};
        
        dataTable = combined_data(strcmp(combined_data.Animal, animalID) & strcmp(combined_data.Subcondition, subcondition), :);
        
        if ~isempty(dataTable)
            fprintf('Analyzing: Animal %s under %s\n', animalID, subcondition);
            
            if ismember('DateZT', dataTable.Properties.VariableNames) && ismember('SelectedPixelDifference', dataTable.Properties.VariableNames)
                dateData = dataTable.DateZT; 
                activityData = dataTable.SelectedPixelDifference; 
                
                hours = hour(dateData);
                edges = 0:24;
                binIndices = discretize(hours, edges);
                validIndices = binIndices > 0;
                binIndices = binIndices(validIndices);
                activityData = activityData(validIndices);
                
                binnedActivity = accumarray(binIndices, activityData, [24, 1], @sum, NaN);
                
                meanActivity = mean(binnedActivity, 'omitnan');
                stdActivity = std(binnedActivity, 'omitnan');
                
                if stdActivity == 0
                    zscoredActivity = zeros(size(binnedActivity));
                else
                    zscoredActivity = (binnedActivity - meanActivity) / stdActivity;
                end

                zscoredActivity48 = [zscoredActivity; zscoredActivity];
                
                if ~isfield(selectedPixelDifferenceActivity, gender)
                    selectedPixelDifferenceActivity.(gender) = struct();
                end
                
                if ~isfield(selectedPixelDifferenceActivity.(gender), validSubcondition)
                    selectedPixelDifferenceActivity.(gender).(validSubcondition) = [];
                end
                
                selectedPixelDifferenceActivity.(gender).(validSubcondition) = [selectedPixelDifferenceActivity.(gender).(validSubcondition); zscoredActivity48'];
            else
                fprintf('Column "DateZT" or "SelectedPixelDifference" not found for Animal %s under %s\n', animalID, subcondition);
            end
        else
            fprintf('No data found for Animal %s under %s\n', animalID, subcondition);
        end
    end
end

figure;
hold on;
fill([12 23 23 12], [-3 -3 4 4], [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'HandleVisibility', 'off');
fill([36 47 47 36], [-3 -3 4 4], [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'HandleVisibility', 'off');

colors = lines(6);
legendEntries = {};

% Plot results for each valid condition and gender
for j = 1:length(validConditionNames)
    validSubcondition = validConditionNames{j};
    genderList = {'Male', 'Female'};
    for genderIdx = 1:length(genderList)
        gender = genderList{genderIdx};
        
        if isfield(selectedPixelDifferenceActivity, gender) && isfield(selectedPixelDifferenceActivity.(gender), validSubcondition)
            meanBinnedActivity48 = mean(selectedPixelDifferenceActivity.(gender).(validSubcondition), 1, 'omitnan');
            colorIdx = (j - 1) * 2 + genderIdx;
            
            plot(0:47, meanBinnedActivity48, 'DisplayName', sprintf('%s - %s', gender, validSubcondition), 'Color', colors(colorIdx, :), 'LineWidth', 2, 'MarkerSize', 4, 'Marker','.');
            hold on;

            legendEntries{end+1} = sprintf('%s - %s', gender, validSubcondition);
        end
    end
end

xlabel('Hour of the Day', 'FontSize', 20, 'FontWeight', 'bold');
ylabel('Activity', 'FontSize', 20, 'FontWeight', 'bold');
title('Activity Over 48 Hours by Gender', 'FontSize', 20, 'FontWeight', 'bold');
legend(legendEntries, 'Location', 'BestOutside', 'FontSize', 20);
grid on;
set(gca, 'LineWidth', 1.5, 'FontSize', 14);
hold off;

disp('48-hour z-score activity analysis and plots generated.');

%% Circadian Analysis AO
% Pool data by gender and plot means at each hour of the day
combined_data.Hour = hour(combined_data.DateZT);
hourlyMeanMale = groupsummary(combined_data(strcmp(combined_data.Gender, 'Male'), :), 'Hour', 'mean', 'SelectedPixelDifference');
hourlyMeanFemale = groupsummary(combined_data(strcmp(combined_data.Gender, 'Female'), :), 'Hour', 'mean', 'SelectedPixelDifference');

hours48 = [hourlyMeanMale.Hour; hourlyMeanMale.Hour + 24];
meansMale48 = [hourlyMeanMale.mean_SelectedPixelDifference; hourlyMeanMale.mean_SelectedPixelDifference];
meansFemale48 = [hourlyMeanFemale.mean_SelectedPixelDifference; hourlyMeanFemale.mean_SelectedPixelDifference];

figure;
hold on;
b1 = bar(hours48, meansMale48, 'FaceColor', 'b', 'BarWidth', 1, 'DisplayName', 'Male');
b2 = bar(hours48, meansFemale48, 'FaceColor', 'r', 'BarWidth', 0.5, 'DisplayName', 'Female');
addShadedAreaToPlotZT48Hour();

uistack(b1, 'top'); 
uistack(b2, 'top');

title('Animal Circadian Means Over 48 Hours by Gender', 'FontSize', 20, 'FontWeight', 'bold');
xlabel('Hour of the Day', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Mean of SelectedPixelDifference', 'FontSize', 18, 'FontWeight', 'bold');
legend('Location', 'BestOutside');
set(gca, 'FontSize', 14, 'FontWeight', 'bold');
hold off;

%% Functions

function addShadedAreaToPlotZT48Hour()
    % This function adds shaded areas to the plot to indicate dark phases
    hold on;
    
    % Define x and y coordinates for the shaded areas
    x_shaded1 = [12, 24, 24, 12];
    y_lim = ylim;
    y_shaded1 = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];
    x_shaded2 = [36, 48, 48, 36];
    y_shaded2 = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];
    
    fill_color = [0.7, 0.7, 0.7]; % Light gray color for shading
    
    % Add shaded areas to the plot
    fill(x_shaded1, y_shaded1, fill_color, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    fill(x_shaded2, y_shaded2, fill_color, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    
    xlabel('Hour of Day (ZT Time)');
    ylabel('Sum of PixelDifference');
    xlim([-0.5, 47.5]);
    xticks(0:1:47);
    xtickangle(90);
    hold off;
end

function addShadedAreaToPlotZT24Hour()
    % This function adds shaded areas to the plot to indicate dark phases
    hold on;
    
    % Define x and y coordinates for the shaded area
    x_shaded = [12, 24, 24, 12];
    y_lim = ylim;
    y_shaded = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];

    fill_color = [0.7, 0.7, 0.7]; % Light gray color for shading

    % Add shaded area to the plot without adding it to the legend
    fill(x_shaded, y_shaded, fill_color, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    
    xlabel('Hour of Day (ZT Time)');
    ylabel('Sum of PixelDifference');
    xlim([-0.5, 23.5]);
    xticks(0:23);
    xtickangle(0);
    hold off;
end

%% Summarize Data Functions
function aggregatedData = aggregate_daily_means(data, selectedPixelDifferenceColumn)
    % This function aggregates data to daily means
    aggregatedData = varfun(@mean, data, 'InputVariables', selectedPixelDifferenceColumn, 'GroupingVariables', {'Condition', 'Animal', 'RelativeDay'});
    
    meanColumnName = ['mean_' selectedPixelDifferenceColumn];
    if ismember(meanColumnName, aggregatedData.Properties.VariableNames)
        meanColumn = aggregatedData.(meanColumnName);
    else
        error('The column %s does not exist in aggregatedData.', meanColumnName);
    end
    
    stdError = varfun(@std, data, 'InputVariables', selectedPixelDifferenceColumn, 'GroupingVariables', {'Condition', 'Animal', 'RelativeDay'});
    stdErrorValues = stdError{:, ['std_' selectedPixelDifferenceColumn]} ./ sqrt(aggregatedData.GroupCount);

    % Add new columns for mean and standard error
    aggregatedData = addvars(aggregatedData, meanColumn, 'NewVariableNames', 'Mean_SelectedPixelDifference');
    aggregatedData = addvars(aggregatedData, stdErrorValues, 'NewVariableNames', 'StdError');
    aggregatedData.GroupCount = []; % Remove the GroupCount variable
end