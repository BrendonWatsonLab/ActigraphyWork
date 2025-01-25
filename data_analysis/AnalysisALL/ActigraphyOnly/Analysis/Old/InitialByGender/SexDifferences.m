%% Analysis of Difference in Mean Activity Over Time
% This script analyzes and compares the difference in mean activity between 
% the start of 1000Lux and 300Lux, as well as the end of 1000Lux and 300Lux, 
% separated by gender (male and female). It visualizes the mean activity 
% differences at each hour of the day over a 48-hour period in bar plots.

%% Parameters
animalIDs = {'AO1', 'AO2', 'AO3', 'AO4', 'AO5', 'AO6', 'AO7', 'AO8'};
genders = {'Male', 'Male', 'Male', 'Female', 'Female', 'Female', 'Male', 'Female'};
conditions = {'300Lux', '1000LuxStart', '1000LuxEnd'};

% Read the combined data table
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyOnly/AOActivityData.csv');

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

%% Separate data by gender and condition
data_male_300Lux = combined_data(strcmp(combined_data.Gender, 'Male') & strcmp(combined_data.Subcondition, '300Lux'), :);
data_female_300Lux = combined_data(strcmp(combined_data.Gender, 'Female') & strcmp(combined_data.Subcondition, '300Lux'), :);

data_male_1000LuxStart = combined_data(strcmp(combined_data.Gender, 'Male') & strcmp(combined_data.Subcondition, '1000LuxStart'), :);
data_female_1000LuxStart = combined_data(strcmp(combined_data.Gender, 'Female') & strcmp(combined_data.Subcondition, '1000LuxStart'), :);

data_male_1000LuxEnd = combined_data(strcmp(combined_data.Gender, 'Male') & strcmp(combined_data.Subcondition, '1000LuxEnd'), :);
data_female_1000LuxEnd = combined_data(strcmp(combined_data.Gender, 'Female') & strcmp(combined_data.Subcondition, '1000LuxEnd'), :);

%% Create 'Hour' column that represents just the hour part of 'Date'
data_male_300Lux.Hour = hour(data_male_300Lux.DateZT);
data_female_300Lux.Hour = hour(data_female_300Lux.DateZT);

data_male_1000LuxStart.Hour = hour(data_male_1000LuxStart.DateZT);
data_female_1000LuxStart.Hour = hour(data_female_1000LuxStart.DateZT);

data_male_1000LuxEnd.Hour = hour(data_male_1000LuxEnd.DateZT);
data_female_1000LuxEnd.Hour = hour(data_female_1000LuxEnd.DateZT);

%% Summarize 'SelectedPixelDifference' by 'Hour'
mean_300Lux_male = groupsummary(data_male_300Lux, 'Hour', 'mean', 'SelectedPixelDifference');
mean_300Lux_female = groupsummary(data_female_300Lux, 'Hour', 'mean', 'SelectedPixelDifference');

mean_1000LuxStart_male = groupsummary(data_male_1000LuxStart, 'Hour', 'mean', 'SelectedPixelDifference');
mean_1000LuxStart_female = groupsummary(data_female_1000LuxStart, 'Hour', 'mean', 'SelectedPixelDifference');

mean_1000LuxEnd_male = groupsummary(data_male_1000LuxEnd, 'Hour', 'mean', 'SelectedPixelDifference');
mean_1000LuxEnd_female = groupsummary(data_female_1000LuxEnd, 'Hour', 'mean', 'SelectedPixelDifference');

% Ensure the tables are sorted by 'Hour' for direct comparison
mean_300Lux_male = sortrows(mean_300Lux_male, 'Hour');
mean_300Lux_female = sortrows(mean_300Lux_female, 'Hour');
mean_1000LuxStart_male = sortrows(mean_1000LuxStart_male, 'Hour');
mean_1000LuxStart_female = sortrows(mean_1000LuxStart_female, 'Hour');
mean_1000LuxEnd_male = sortrows(mean_1000LuxEnd_male, 'Hour');
mean_1000LuxEnd_female = sortrows(mean_1000LuxEnd_female, 'Hour');

%% Subtract mean activities
difference_male_start = mean_1000LuxStart_male.mean_SelectedPixelDifference - mean_300Lux_male.mean_SelectedPixelDifference;
difference_female_start = mean_1000LuxStart_female.mean_SelectedPixelDifference - mean_300Lux_female.mean_SelectedPixelDifference;

difference_male_end = mean_1000LuxEnd_male.mean_SelectedPixelDifference - mean_300Lux_male.mean_SelectedPixelDifference;
difference_female_end = mean_1000LuxEnd_female.mean_SelectedPixelDifference - mean_300Lux_female.mean_SelectedPixelDifference;

% Prepare data for 48-hour plots
hours = mean_300Lux_male.Hour;
hours48 = [hours; hours + 24];
difference_male_start_48 = [difference_male_start; difference_male_start];
difference_female_start_48 = [difference_female_start; difference_female_start];

difference_male_end_48 = [difference_male_end; difference_male_end];
difference_female_end_48 = [difference_female_end; difference_female_end];

%% Plot Differences for Start as Bar Plot
figure;
hold on;
b1 = bar(hours48, difference_male_start_48, 'FaceColor', 'b', 'BarWidth', 0.8, 'DisplayName', 'Male Start - 300Lux');
b2 = bar(hours48, difference_female_start_48, 'FaceColor', 'r', 'BarWidth', 0.4, 'DisplayName', 'Female Start - 300Lux');
addShadedAreaToPlotZT48Hour();

uistack(b1, 'top'); 
uistack(b2, 'top'); 

title('Difference in Activity: 1000 Lux Start - 300 Lux by Gender over 48 Hours', 'FontSize', 20, 'FontWeight', 'bold');
xlabel('Hour of the Day', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Difference in Activity', 'FontSize', 18, 'FontWeight', 'bold');
legend('Location', 'BestOutside', 'FontSize', 14);
set(gca, 'FontSize', 14, 'FontWeight', 'bold');
grid on;
hold off;

%% Plot Differences for End as Bar Plot
figure;
hold on;
b1 = bar(hours48, difference_male_end_48, 'FaceColor', 'b', 'BarWidth', 0.8, 'DisplayName', 'Male End - 300Lux');
b2 = bar(hours48, difference_female_end_48, 'FaceColor', 'r', 'BarWidth', 0.4, 'DisplayName', 'Female End - 300Lux');
addShadedAreaToPlotZT48Hour();

uistack(b1, 'top'); 
uistack(b2, 'top'); 

title('Difference in Activity: 1000 Lux End - 300 Lux by Gender over 48 Hours', 'FontSize', 20, 'FontWeight', 'bold');
xlabel('Hour of the Day', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Difference in Activity', 'FontSize', 18, 'FontWeight', 'bold');
legend('Location', 'BestOutside', 'FontSize', 14);
set(gca, 'FontSize', 14, 'FontWeight', 'bold');
grid on;
hold off;

%% Functions

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
    
    xlabel('Hour of Day (ZT Time)');
    ylabel('Sum of PixelDifference');
    xlim([-0.5, 47.5]);
    xticks(0:1:47);
    xtickangle(90);
    
    hold off;
end

function addShadedAreaToPlotZT24Hour()
    hold on;
    % Define x and y coordinates for the shaded area (from t=12 to t=24)
    x_shaded = [12, 24, 24, 12];
    y_lim = ylim;
    y_shaded = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];

    fill_color = [0.7, 0.7, 0.7]; % Light gray color for the shading

    % Add shaded areas to the plot with 'HandleVisibility', 'off' to exclude from the legend
    fill(x_shaded, y_shaded, fill_color, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    
    xlabel('Hour of Day (ZT Time)');
    ylabel('Sum of PixelDifference');
    xlim([-0.5, 23.5]);
    xticks(0:23);
    xtickangle(0);
    
    hold off;
end