%% Parameters
% List of animal IDs, conditions, and genders
animalIDs = {'AO1', 'AO2', 'AO3', 'AO4', 'AO5', 'AO6', 'AO7', 'AO8'};
genders = {'Male', 'Male', 'Male', 'Female', 'Female', 'Female', 'Male', 'Female'};
conditions = {'300Lux', '1000LuxStart', '1000LuxEnd'};  % Updated conditions to include start and end

% Read the combined data table
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/AO1-8binned_data.csv');

%% Assign each data point a gender

% Initialize Gender column to empty cell array of the same height as combined_data
combined_data.Gender = cell(height(combined_data), 1);

% Assign gender to each row based on animal ID
for i = 1:length(animalIDs)
    animalIndices = strcmp(combined_data.Animal, animalIDs{i});
    combined_data.Gender(animalIndices) = repmat(genders(i), sum(animalIndices), 1);
end

%% Separate Data for 1000LuxStart and 1000LuxEnd
% Add a `Subcondition` column to classify `1000Lux` into `1000LuxStart` and `1000LuxEnd`
combined_data.Subcondition = combined_data.Condition;  % Initialize with existing conditions

for i = 1:length(animalIDs)
    animalID = animalIDs{i};
    % Filter data for `1000Lux` condition
    animal_1000Lux_data = combined_data(strcmp(combined_data.Animal, animalID) & strcmp(combined_data.Condition, '1000Lux'), :);
    
    % Ensure there's data to classify
    if ~isempty(animal_1000Lux_data)
        unique_days = floor(min(animal_1000Lux_data.RelativeDay)):floor(max(animal_1000Lux_data.RelativeDay));
        
        % Ensure there are at least 14 unique days (days 0-6 and 7-13, inclusive)
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
AnalyzeCircadianRunningGender(combined_data, false, 'All Rats');

%% Peak Analysis AO

normalizedActivity = struct();

% Normalize condition names to be valid field names
validConditionNames = strcat('Cond', conditions);

% Loop over each animal and subcondition
for i = 1:length(animalIDs)
    animalID = animalIDs{i};
    gender = genders{i};

    for j = 1:length(conditions)
        subcondition = conditions{j};  
        validSubcondition = validConditionNames{j};
        
        % Filter data for the current animal and subcondition
        dataTable = combined_data(strcmp(combined_data.Animal, animalID) & strcmp(combined_data.Subcondition, subcondition), :);

        % Check if there is data for this combination
        if ~isempty(dataTable)
            fprintf('Analyzing: Animal %s under %s\n', animalID, subcondition);
            
            if ismember('Date', dataTable.Properties.VariableNames) && ismember('SelectedPixelDifference', dataTable.Properties.VariableNames)
                dateData = dataTable.Date; 
                activityData = dataTable.SelectedPixelDifference; 
                
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
                    zscoredActivity = zeros(size(binnedActivity));
                else
                    zscoredActivity = (binnedActivity - meanActivity) / stdActivity;
                end

                % Duplicate the 24-hour data to cover 48 hours
                zscoredActivity48 = [zscoredActivity; zscoredActivity];
                
                % Store results for each gender and subcondition
                if ~isfield(normalizedActivity, gender)
                    normalizedActivity.(gender) = struct();
                end
                
                if ~isfield(normalizedActivity.(gender), validSubcondition)
                    normalizedActivity.(gender).(validSubcondition) = [];
                end
                
                normalizedActivity.(gender).(validSubcondition) = [normalizedActivity.(gender).(validSubcondition); zscoredActivity48'];
            else
                fprintf('Column "Date" or "SelectedPixelDifference" not found for Animal %s under %s\n', animalID, subcondition);
            end
        else
            fprintf('No data found for Animal %s under %s\n', animalID, subcondition);
        end
    end
end

figure;
hold on;

% Add gray shading from ZT = 12 to ZT = 23
fill([12 23 23 12], [-3 -3 4 4], [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'HandleVisibility', 'off');
% Add gray shading from ZT = 36 to ZT = 47
fill([36 47 47 36], [-3 -3 4 4], [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'HandleVisibility', 'off');

% Define color scheme using a larger colormap
colors = lines(6); % MATLAB colormap for 6 conditions (3 conditions x 2 genders)
gender_colors = struct('Male', 'b', 'Female', 'r'); % Define blue for Male, red for Female

% Ensure there are enough colors
if size(colors, 1) < 6
    error('Not enough colors defined. Increase the size of the colors array.');
end

% Plot average activity for each gender and condition
legendEntries = {};

for j = 1:length(validConditionNames)
    validSubcondition = validConditionNames{j};
    
    genderList = {'Male', 'Female'};
    for genderIdx = 1:length(genderList)
        gender = genderList{genderIdx};
        
        if isfield(normalizedActivity, gender) && isfield(normalizedActivity.(gender), validSubcondition)
            
            meanBinnedActivity48 = mean(normalizedActivity.(gender).(validSubcondition), 1, 'omitnan');
            
            % Calculate the color index
            colorIdx = (j - 1) * 2 + genderIdx;
            
            % Plot the mean activity for this gender and condition
            plot(0:47, meanBinnedActivity48, 'DisplayName', sprintf('%s - %s', gender, validSubcondition), 'Color', colors(colorIdx, :), 'LineWidth', 2, 'MarkerSize', 4, 'Marker','.');
            hold on;

            legendEntries{end+1} = sprintf('%s - %s', gender, validSubcondition);
        end
    end
end

xlabel('Hour of the Day', 'FontSize', 20, 'FontWeight', 'bold');
ylabel('Normalized Activity', 'FontSize', 20, 'FontWeight', 'bold');
title('Normalized Activity Over 48 Hours by Gender', 'FontSize', 20, 'FontWeight', 'bold');
legend(legendEntries, 'Location', 'BestOutside', 'FontSize', 20);
grid on; % Add grid lines for better readability
set(gca, 'LineWidth', 1.5, 'FontSize', 14);
hold off;

disp('48-hour z-score normalized activity analysis and plots generated and saved.');

%% Circadian Analysis AO
% Pool data by gender and plot sums at each hour of the day

animalIDs = {'AO1', 'AO2', 'AO3', 'AO4', 'AO5', 'AO6', 'AO7', 'AO8'};
genders = {'Male', 'Male', 'Male', 'Female', 'Female', 'Female', 'Male', 'Female'};

% Creating an 'Hour' column that represents just the hour part of 'Date'
combined_data.Hour = hour(combined_data.Date);

% Summarize 'SelectedPixelDifference' by 'Hour' and 'Gender'
hourlyMeanMale = groupsummary(combined_data(strcmp(combined_data.Gender, 'Male'), :), 'Hour', 'mean', 'SelectedPixelDifference');
hourlyMeanFemale = groupsummary(combined_data(strcmp(combined_data.Gender, 'Female'), :), 'Hour', 'mean', 'SelectedPixelDifference');

% Prepare data for 48-hour plot
hours48 = [hourlyMeanMale.Hour; hourlyMeanMale.Hour + 24]; % Append hours 0-23 with 24-47
meansMale48 = [hourlyMeanMale.mean_SelectedPixelDifference; hourlyMeanMale.mean_SelectedPixelDifference]; % Repeat the sums
meansFemale48 = [hourlyMeanFemale.mean_SelectedPixelDifference; hourlyMeanFemale.mean_SelectedPixelDifference]; % Repeat the sums

% Create the plot
figure;
hold on;
b1 = bar(hours48, sumsMale48, 'FaceColor', 'b', 'BarWidth', 1, 'DisplayName', 'Male');
b2 = bar(hours48, sumsFemale48, 'FaceColor', 'r', 'BarWidth', 0.5, 'DisplayName', 'Female');
addShadedAreaToPlotZT48Hour();

% Ensure the bars are on top
uistack(b1, 'top'); 
uistack(b2, 'top'); 

% Set plot title and labels
title('Animal Circadian Means Over 48 Hours by Gender', 'FontSize', 20, 'FontWeight', 'bold');
xlabel('Hour of the Day', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Mean of Selected Pixel Difference', 'FontSize', 18, 'FontWeight', 'bold');
legend('Location', 'BestOutside');
set(gca, 'FontSize', 14, 'FontWeight', 'bold');

hold off;

% Split data by gender and subcondition and find differences

% Extract rows for the conditions and split by gender
data_300lux_male = combined_data(strcmp(combined_data.Subcondition, '300Lux') & strcmp(combined_data.Gender, 'Male'), :);
data_300lux_female = combined_data(strcmp(combined_data.Subcondition, '300Lux') & strcmp(combined_data.Gender, 'Female'), :);
data_1000luxstart_male = combined_data(strcmp(combined_data.Subcondition, '1000LuxStart') & strcmp(combined_data.Gender, 'Male'), :);
data_1000luxstart_female = combined_data(strcmp(combined_data.Subcondition, '1000LuxStart') & strcmp(combined_data.Gender, 'Female'), :);
data_1000luxend_male = combined_data(strcmp(combined_data.Subcondition, '1000LuxEnd') & strcmp(combined_data.Gender, 'Male'), :);
data_1000luxend_female = combined_data(strcmp(combined_data.Subcondition, '1000LuxEnd') & strcmp(combined_data.Gender, 'Female'), :);

% Create 'Hour' column for each subset
data_300lux_male.Hour = hour(data_300lux_male.Date);
data_300lux_female.Hour = hour(data_300lux_female.Date);
data_1000luxstart_male.Hour = hour(data_1000luxstart_male.Date);
data_1000luxstart_female.Hour = hour(data_1000luxstart_female.Date);
data_1000luxend_male.Hour = hour(data_1000luxend_male.Date);
data_1000luxend_female.Hour = hour(data_1000luxend_female.Date);

% Summarize 'NormalizedActivity' by 'Hour' for each subset
mean_300lux_male = groupsummary(data_300lux_male, 'Hour', 'mean', 'NormalizedActivity');
mean_300lux_female = groupsummary(data_300lux_female, 'Hour', 'mean', 'NormalizedActivity');
mean_1000luxstart_male = groupsummary(data_1000luxstart_male, 'Hour', 'mean', 'NormalizedActivity');
mean_1000luxstart_female = groupsummary(data_1000luxstart_female, 'Hour', 'mean', 'NormalizedActivity');
mean_1000luxend_male = groupsummary(data_1000luxend_male, 'Hour', 'mean', 'NormalizedActivity');
mean_1000luxend_female = groupsummary(data_1000luxend_female, 'Hour', 'mean', 'NormalizedActivity');

% Ensure the tables are sorted by 'Hour' for direct comparison
mean_300lux_male = sortrows(mean_300lux_male, 'Hour');
mean_300lux_female = sortrows(mean_300lux_female, 'Hour');
mean_1000luxstart_male = sortrows(mean_1000luxstart_male, 'Hour');
mean_1000luxstart_female = sortrows(mean_1000luxstart_female, 'Hour');
mean_1000luxend_male = sortrows(mean_1000luxend_male, 'Hour');
mean_1000luxend_female = sortrows(mean_1000luxend_female, 'Hour');

% Subtract means: 1000LuxStart/End - 300Lux
difference_male_start = mean_1000luxstart_male.mean_NormalizedActivity - mean_300lux_male.mean_NormalizedActivity;
difference_female_start = mean_1000luxstart_female.mean_NormalizedActivity - mean_300lux_female.mean_NormalizedActivity;
difference_male_end = mean_1000luxend_male.mean_NormalizedActivity - mean_300lux_male.mean_NormalizedActivity;
difference_female_end = mean_1000luxend_female.mean_NormalizedActivity - mean_300lux_female.mean_NormalizedActivity;

% Prepare data for 24-hour plots
hours = mean_300lux_male.Hour;

% Create the plot for start difference
figure;
hold on;
b3 = bar(hours, difference_male_start, 'FaceColor', colors(1,:), 'BarWidth', 0.5, 'DisplayName', 'Difference Male Start');
b4 = bar(hours, difference_female_start, 'FaceColor', colors(2,:), 'BarWidth', 0.5, 'DisplayName', 'Difference Female Start');

addShadedAreaToPlotZT24Hour();

% Ensure the bars are on top
uistack(b3, 'top'); 
uistack(b4, 'top'); 

% Set plot title and labels
title('Difference in NormalizedActivity: 1000 Lux Start - 300 Lux by Gender', 'FontSize', 20, 'FontWeight', 'bold');
xlabel('Hour of Day', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Difference in NormalizedActivity', 'FontSize', 18, 'FontWeight', 'bold');
legend('Location', 'BestOutside');
set(gca, 'FontSize', 14, 'FontWeight', 'bold');
grid on; % Add grid lines for better readability

hold off;

% Create the plot for end difference
figure;
hold on;
b5 = bar(hours, difference_male_end, 'FaceColor', colors(3,:), 'BarWidth', 0.5, 'DisplayName', 'Difference Male End');
b6 = bar(hours, difference_female_end, 'FaceColor', colors(4,:), 'BarWidth', 0.5, 'DisplayName', 'Difference Female End');

addShadedAreaToPlotZT24Hour();

% Ensure the bars are on top
uistack(b5, 'top'); 
uistack(b6, 'top'); 

% Set plot title and labels
title('Difference in NormalizedActivity: 1000 Lux End - 300 Lux by Gender', 'FontSize', 20, 'FontWeight', 'bold');
xlabel('Hour of Day', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Difference in NormalizedActivity', 'FontSize', 18, 'FontWeight', 'bold');
legend('Location', 'BestOutside');
set(gca, 'FontSize', 14, 'FontWeight', 'bold');
grid on; % Add grid lines for better readability

hold off;

% Line Plots for Differences by Gender

% Summarize 'SelectedPixelDifference' by 'Hour' for each subset
mean_300lux_male = groupsummary(data_300lux_male, 'Hour', 'mean', 'SelectedPixelDifference');
mean_1000luxstart_male = groupsummary(data_1000luxstart_male, 'Hour', 'mean', 'SelectedPixelDifference');
mean_1000luxend_male = groupsummary(data_1000luxend_male, 'Hour', 'mean', 'SelectedPixelDifference');
mean_300lux_female = groupsummary(data_300lux_female, 'Hour', 'mean', 'SelectedPixelDifference');
mean_1000luxstart_female = groupsummary(data_1000luxstart_female, 'Hour', 'mean', 'SelectedPixelDifference');
mean_1000luxend_female = groupsummary(data_1000luxend_female, 'Hour', 'mean', 'SelectedPixelDifference');

% Ensure tables sorted by 'Hour'
mean_300lux_male = sortrows(mean_300lux_male, 'Hour');
mean_1000luxstart_male = sortrows(mean_1000luxstart_male, 'Hour');
mean_1000luxend_male = sortrows(mean_1000luxend_male, 'Hour');
mean_300lux_female = sortrows(mean_300lux_female, 'Hour');
mean_1000luxstart_female = sortrows(mean_1000luxstart_female, 'Hour');
mean_1000luxend_female = sortrows(mean_1000luxend_female, 'Hour');

% Calculate the differences
difference_male_start = mean_1000luxstart_male.mean_SelectedPixelDifference - mean_300lux_male.mean_SelectedPixelDifference;
difference_female_start = mean_1000luxstart_female.mean_SelectedPixelDifference - mean_300lux_female.mean_SelectedPixelDifference;
difference_male_end = mean_1000luxend_male.mean_SelectedPixelDifference - mean_300lux_male.mean_SelectedPixelDifference;
difference_female_end = mean_1000luxend_female.mean_SelectedPixelDifference - mean_300lux_female.mean_SelectedPixelDifference;

hours = mean_300lux_male.Hour;

% Create the line plot for differences
figure;
hold on;

% Plot mean activity for 300Lux by gender
p1 = plot(hours, mean_300lux_male.mean_SelectedPixelDifference, '-o', 'DisplayName', '300 Lux Male', 'Color', colors(1,:), 'LineWidth', 2, 'MarkerSize', 4);
p2 = plot(hours, mean_300lux_female.mean_SelectedPixelDifference, '-o', 'DisplayName', '300 Lux Female', 'Color', colors(2,:), 'LineWidth', 2, 'MarkerSize', 4);

% Plot mean activity for 1000Lux Start by gender
p3 = plot(hours, mean_1000luxstart_male.mean_SelectedPixelDifference, '-s', 'DisplayName', '1000 Lux Start Male', 'Color', colors(3,:), 'LineWidth', 2, 'LineStyle', '--', 'MarkerSize', 4);
p4 = plot(hours, mean_1000luxstart_female.mean_SelectedPixelDifference, '-s', 'DisplayName', '1000 Lux Start Female', 'Color', colors(4,:), 'LineWidth', 2, 'LineStyle', '--', 'MarkerSize', 4);

% Plot mean activity for 1000Lux End by gender
p5 = plot(hours, mean_1000luxend_male.mean_SelectedPixelDifference, '-^', 'DisplayName', '1000 Lux End Male', 'Color', colors(5,:), 'LineWidth', 2, 'MarkerSize', 4);
p6 = plot(hours, mean_1000luxend_female.mean_SelectedPixelDifference, '-^', 'DisplayName', '1000 Lux End Female', 'Color', colors(6,:), 'LineWidth', 2, 'MarkerSize', 4);

addShadedAreaToPlotZT24Hour();

% Ensure the lines are visible
uistack(p1, 'top'); 
uistack(p2, 'top'); 
uistack(p3, 'top'); 
uistack(p4, 'top'); 
uistack(p5, 'top'); 
uistack(p6, 'top'); 

% Add plot settings
title('Mean SelectedPixelDifference Over 24 Hours by Gender', 'FontSize', 20, 'FontWeight', 'bold');
xlabel('Hour of Day', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Mean SelectedPixelDifference', 'FontSize', 18, 'FontWeight', 'bold');
legend('show', 'Location', 'northeast', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'FontSize', 14, 'FontWeight', 'bold', 'LineWidth', 1.5);
grid on;

hold off;

disp('Done');

%% Functions

% Function to add a shaded area to the current plot for ZT 48-hour
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

% Function to add a shaded area to the current plot for ZT 24-hour
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