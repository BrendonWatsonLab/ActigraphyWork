%% Analysis of Dark Condition Activity Over Time
% This script analyzes the activity in the Dark/Dark and 300LuxEnd conditions,
% binning every 7 days, and plots the summed activity at each hour over a 48-hour period.
% Only animals AO5-8 are considered.

%% Parameters
animalIDs = {'AO5', 'AO6', 'AO7', 'AO8'};
maleAnimalID = 'AO7';
femaleAnimalIDs = {'AO5', 'AO6', 'AO8'};
conditions = {'FullDark', '300LuxEnd'};

% Read the combined data table
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/AOCohortData.csv');

%% Filter data for Dark/Dark and 300LuxEnd conditions and specific animals
condition_data = combined_data(ismember(combined_data.Condition, conditions) & ismember(combined_data.Animal, animalIDs), :);

%% Assign each data point a 7-day bin
condition_data.Bin = ceil(condition_data.RelativeDay / 7);

%% Split data by sex
male_data = condition_data(strcmp(condition_data.Animal, maleAnimalID), :);
female_data = condition_data(ismember(condition_data.Animal, femaleAnimalIDs), :);

%% Summarize and plot activity data for male and female animals
plotAnimalData(male_data, 'Male (AO7)');
plotAnimalData(female_data, 'Females (AO5, AO6, AO8)');

%% Functions

function plotAnimalData(data, titleText)
    bins = unique(data.Bin);
    
    % Add an artificial "Week 6" bin for '300LuxEnd' data, don't worry
    % about this lolololol
    lux300_data = data(strcmp(data.Condition, '300LuxEnd'), :);
    if ~isempty(lux300_data)
        lux300_data.Bin = repmat(6, height(lux300_data), 1);
        data = [data; lux300_data]; % Append the 300LuxEnd data with Bin=6
    end
    
    figure('Name', ['All Animal Circadian Means Over 48 Hours - ' titleText], 'NumberTitle', 'off');
    for i = 1:max(bins)
        % Filter data for the current bin
        bin_data = data(data.Bin == i, :);
        
        % Extract hour from datetime data
        bin_data.Hour = hour(bin_data.DateZT);
        
        % Summarize 'SelectedPixelDifference' by 'Hour'
        hourlyMean = groupsummary(bin_data, 'Hour', 'mean', 'SelectedPixelDifference');
        
        % Prepare data for 48-hour plot
        hours48 = [hourlyMean.Hour; hourlyMean.Hour + 24]; % Append hours 0-23 with 24-47
        means48 = [hourlyMean.mean_SelectedPixelDifference; hourlyMean.mean_SelectedPixelDifference]; % Repeat the means
        
        % Variables for plot titles and figure names
        if i == 6
            weekTitle = '300LuxEnd';
        else
            weekTitle = sprintf('Week %d (Days %d-%d)', i, (i-1)*7 + 1, i*7);
        end
        
        % Create the subplot
        subplot(6, 1, i);
        b1 = bar(hours48, means48, 'BarWidth', 1);
        addShadedAreaToPlotZT48Hour();
        title(weekTitle, 'FontSize', 16, 'FontWeight', 'bold');
        xlabel('Hour of the Day', 'FontSize', 14, 'FontWeight', 'bold');
        ylabel('PixelSum', 'FontSize', 14, 'FontWeight', 'bold');
        set(gca, 'FontSize', 12, 'FontWeight', 'bold'); % Increase font size and bold for axis labels
        sgtitle(titleText);
        % Ensure the bars are on top
        uistack(b1, 'top');
    end
end

function addShadedAreaToPlotZT48Hour()
    hold on;
    
    % Define x and y coordinates for the first shaded area (from ZT 0 to ZT 12)
    x_shaded1 = [0, 12, 12, 0];
    y_lim = ylim;
    y_shaded1 = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];
    
    % Define x and y coordinates for the second shaded area (from ZT 12 to ZT 24)
    x_shaded2 = [12, 24, 24, 12];
    y_shaded2 = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];
    
    % Define x and y coordinates for the third shaded area (from ZT 24 to ZT 36)
    x_shaded3 = [24, 36, 36, 24];
    y_shaded3 = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];
    
    % Define x and y coordinates for the fourth shaded area (from ZT 36 to ZT 48)
    x_shaded4 = [36, 48, 48, 36];
    y_shaded4 = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];
    
    % Define colors for shading
    light_gray = [0.7, 0.7, 0.7];
    dark_gray = [0.5, 0.5, 0.5];
    
    % Add shaded areas to the plot with light and dark gray
    fill(x_shaded1, y_shaded1, light_gray, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    fill(x_shaded2, y_shaded2, dark_gray, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    fill(x_shaded3, y_shaded3, light_gray, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    fill(x_shaded4, y_shaded4, dark_gray, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    
    xlabel('Hour of Day (ZT Time)');
    ylabel('Sum of Selected Pixel Difference');
    xlim([-0.5, 47.5]);
    xticks(0:1:47);
    xtickangle(90);
    
    hold off;
end
