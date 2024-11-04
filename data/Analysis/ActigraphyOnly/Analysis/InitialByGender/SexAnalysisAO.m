%% Parameters
% List of animal IDs, conditions, and genders
animalIDs = {'AO1', 'AO2', 'AO3', 'AO4', 'AO5', 'AO6', 'AO7', 'AO8'};
genders = {'Male', 'Male', 'Male', 'Female', 'Female', 'Female', 'Male', 'Female'};
conditions = {'300Lux', '1000Lux'};

% Read the combined data table
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/AO1-8binned_data.csv');

%% Analyze Circadian Running
AnalyzeCircadianRunningGender(combined_data, false, 'All Rats');

%% Peak Analysis AO

normalizedActivity = struct();

% Normalize condition names to be valid field names
validConditionNames = strcat('Cond_', conditions);

% Loop over each animal and condition
for i = 1:length(animalIDs)
    animalID = animalIDs{i};
    gender = genders{i};
    
    for j = 1:length(conditions)
        condition = conditions{j};   
        validCondition = validConditionNames{j};
        
        % Filter data for the current animal and condition
        dataTable = combined_data(strcmp(combined_data.Animal, animalID) & strcmp(combined_data.Condition, condition), :);

        % Check if there is data for this combination
        if ~isempty(dataTable)
            fprintf('Analyzing: Animal %s under %s\n', animalID, condition);
            
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
                
                % Store results for each gender and condition
                if ~isfield(normalizedActivity, gender)
                    normalizedActivity.(gender) = struct();
                end
                
                if ~isfield(normalizedActivity.(gender), validCondition)
                    normalizedActivity.(gender).(validCondition) = [];
                end
                
                normalizedActivity.(gender).(validCondition) = [normalizedActivity.(gender).(validCondition); zscoredActivity48'];
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

% Plot average activity for each gender and condition
legendEntries = {};

for j = 1:length(validConditionNames)
    validCondition = validConditionNames{j};
    
    % Ensure correct gender assignments
    genderList = {'Male', 'Female'};
    for genderIdx = 1:length(genderList)
        gender = genderList{genderIdx};  % Access 'Male' and 'Female' based on list elements
        
        if isfield(normalizedActivity, gender) && isfield(normalizedActivity.(gender), validCondition)
            % Calculate the mean activity over all animals for this gender and condition
            meanBinnedActivity48 = mean(normalizedActivity.(gender).(validCondition), 1, 'omitnan');
            
            % Assign colors based on gender
            if strcmp(gender, 'Male')
                color = 'b';  % Blue for Male
            elseif strcmp(gender, 'Female')
                color = 'r';  % Red for Female
            end

            % Plot the mean activity for this gender and condition
            plot(0:47, meanBinnedActivity48, 'DisplayName', sprintf('%s - %s', gender, conditions{j}), 'Color', color, 'LineWidth', 2);
            hold on;

            legendEntries{end+1} = sprintf('%s - %s', gender, conditions{j});
        end
    end
end

xlabel('Hour of the Day', 'FontSize', 20, 'FontWeight', 'bold');
ylabel('Normalized Activity', 'FontSize', 20, 'FontWeight', 'bold');
title('Normalized Activity Over 48 Hours by Gender', 'FontSize', 20, 'FontWeight', 'bold');
legend(legendEntries, 'Location', 'BestOutside', 'FontSize', 20);
hold off;

disp('48-hour z-score normalized activity analysis and plots generated and saved.');

%% Circadian Analysis AO
% Pool data by gender and plot sums at each hour of the day

% List of animal IDs and genders
animalIDs = {'AO1', 'AO2', 'AO3', 'AO4', 'AO5', 'AO6', 'AO7', 'AO8'};
genders = {'Male', 'Male', 'Male', 'Female', 'Female', 'Female', 'Male', 'Female'};

% Creating an 'Hour' column that represents just the hour part of 'Date'
combined_data.Hour = hour(combined_data.Date);

% Split data based on gender
combined_data.Gender = cell(size(combined_data, 1), 1);
for i = 1:length(animalIDs)
    combined_data.Gender(strcmp(combined_data.Animal, animalIDs{i})) = genders(i);
end

% Summarize 'SelectedPixelDifference' by 'Hour' and 'Gender'
hourlySumMale = groupsummary(combined_data(strcmp(combined_data.Gender, 'Male'), :), 'Hour', 'sum', 'SelectedPixelDifference');
hourlySumFemale = groupsummary(combined_data(strcmp(combined_data.Gender, 'Female'), :), 'Hour', 'sum', 'SelectedPixelDifference');

% Prepare data for 48-hour plot
hours48 = [hourlySumMale.Hour; hourlySumMale.Hour + 24]; % Append hours 0-23 with 24-47
sumsMale48 = [hourlySumMale.sum_SelectedPixelDifference; hourlySumMale.sum_SelectedPixelDifference]; % Repeat the sums
sumsFemale48 = [hourlySumFemale.sum_SelectedPixelDifference; hourlySumFemale.sum_SelectedPixelDifference]; % Repeat the sums

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
title('Total Animal Circadian Sums Over 48 Hours by Gender', 'FontSize', 20, 'FontWeight', 'bold');
xlabel('Hour of the Day', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Sum of Selected Pixel Difference', 'FontSize', 18, 'FontWeight', 'bold');
legend('Location', 'BestOutside');
set(gca, 'FontSize', 14, 'FontWeight', 'bold');

hold off;

% Split data by gender and condition and find difference

% Extract rows for the conditions and split by gender
data_300lux_male = combined_data(strcmp(combined_data.Condition, '300Lux') & strcmp(combined_data.Gender, 'Male'), :);
data_300lux_female = combined_data(strcmp(combined_data.Condition, '300Lux') & strcmp(combined_data.Gender, 'Female'), :);
data_1000lux_male = combined_data(strcmp(combined_data.Condition, '1000Lux') & strcmp(combined_data.Gender, 'Male'), :);
data_1000lux_female = combined_data(strcmp(combined_data.Condition, '1000Lux') & strcmp(combined_data.Gender, 'Female'), :);

% Create 'Hour' column for each subset
data_300lux_male.Hour = hour(data_300lux_male.Date);
data_300lux_female.Hour = hour(data_300lux_female.Date);
data_1000lux_male.Hour = hour(data_1000lux_male.Date);
data_1000lux_female.Hour = hour(data_1000lux_female.Date);

% Summarize 'NormalizedActivity' by 'Hour' for both gender subsets
mean_300lux_male = groupsummary(data_300lux_male, 'Hour', 'mean', 'NormalizedActivity');
mean_300lux_female = groupsummary(data_300lux_female, 'Hour', 'mean', 'NormalizedActivity');
mean_1000lux_male = groupsummary(data_1000lux_male, 'Hour', 'mean', 'NormalizedActivity');
mean_1000lux_female = groupsummary(data_1000lux_female, 'Hour', 'mean', 'NormalizedActivity');

% Ensure both tables are sorted by 'Hour' for direct subtraction
mean_300lux_male = sortrows(mean_300lux_male, 'Hour');
mean_300lux_female = sortrows(mean_300lux_female, 'Hour');
mean_1000lux_male = sortrows(mean_1000lux_male, 'Hour');
mean_1000lux_female = sortrows(mean_1000lux_female, 'Hour');

% Subtract means: 1000Lux - 300Lux
difference_male = mean_1000lux_male.mean_NormalizedActivity - mean_300lux_male.mean_NormalizedActivity;
difference_female = mean_1000lux_female.mean_NormalizedActivity - mean_300lux_female.mean_NormalizedActivity;

% Prepare data for 24-hour plot
hours = mean_300lux_male.Hour;

% Create the plot
figure;
hold on;
b3 = bar(hours, difference_male, 'b', 'BarWidth', 0.5, 'DisplayName', 'Male');
b4 = bar(hours, difference_female, 'r', 'BarWidth', 1, 'DisplayName', 'Female');
addShadedAreaToPlotZT24Hour();

% Ensure the bars are on top
uistack(b3, 'top'); 
uistack(b4, 'top'); 

% Set plot title and labels
title('Difference in NormalizedActivity: 1000 Lux - 300 Lux by Gender', 'FontSize', 20, 'FontWeight', 'bold');
xlabel('Hour of Day', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Difference in NormalizedActivity', 'FontSize', 18, 'FontWeight', 'bold');
legend('Location', 'BestOutside');
set(gca, 'FontSize', 14, 'FontWeight', 'bold');

hold off;

% Line Plots for Differences by Gender

data_300lux_male = combined_data(strcmp(combined_data.Condition, '300Lux') & strcmp(combined_data.Gender, 'Male'), :);
data_1000lux_male = combined_data(strcmp(combined_data.Condition, '1000Lux') & strcmp(combined_data.Gender, 'Male'), :);
data_300lux_female = combined_data(strcmp(combined_data.Condition, '300Lux') & strcmp(combined_data.Gender, 'Female'), :);
data_1000lux_female = combined_data(strcmp(combined_data.Condition, '1000Lux') & strcmp(combined_data.Gender, 'Female'), :);

% Create 'Hour' column for both subsets
data_300lux_male.Hour = hour(data_300lux_male.Date);
data_1000lux_male.Hour = hour(data_1000lux_male.Date);
data_300lux_female.Hour = hour(data_300lux_female.Date);
data_1000lux_female.Hour = hour(data_1000lux_female.Date);

% Summarize 'SelectedPixelDifference' by 'Hour' for both subsets
mean_300lux_male = groupsummary(data_300lux_male, 'Hour', 'mean', 'SelectedPixelDifference');
mean_1000lux_male = groupsummary(data_1000lux_male, 'Hour', 'mean', 'SelectedPixelDifference');
mean_300lux_female = groupsummary(data_300lux_female, 'Hour', 'mean', 'SelectedPixelDifference');
mean_1000lux_female = groupsummary(data_1000lux_female, 'Hour', 'mean', 'SelectedPixelDifference');

% Ensure both tables are sorted by 'Hour'
mean_300lux_male = sortrows(mean_300lux_male, 'Hour');
mean_1000lux_male = sortrows(mean_1000lux_male, 'Hour');
mean_300lux_female = sortrows(mean_300lux_female, 'Hour');
mean_1000lux_female = sortrows(mean_1000lux_female, 'Hour');

% Calculate the difference: 1000Lux - 300Lux
difference_male = mean_1000lux_male.mean_SelectedPixelDifference - mean_300lux_male.mean_SelectedPixelDifference;
difference_female = mean_1000lux_female.mean_SelectedPixelDifference - mean_300lux_female.mean_SelectedPixelDifference;

hours = mean_300lux_male.Hour;

% Create the plot
figure;
hold on;

% Plot mean activity for 300Lux by gender
p1 = plot(hours, mean_300lux_male.mean_SelectedPixelDifference, '-o', 'DisplayName', '300 Lux Male', 'Color', 'b', 'LineWidth', 2);
p2 = plot(hours, mean_300lux_female.mean_SelectedPixelDifference, '-o', 'DisplayName', '300 Lux Female', 'Color', 'r', 'LineWidth', 2);

% Plot mean activity for 1000 Lux by gender
p3 = plot(hours, mean_1000lux_male.mean_SelectedPixelDifference, '-s', 'DisplayName', '1000 Lux Male', 'Color', 'b', 'LineWidth', 2, 'LineStyle', '--');
p4 = plot(hours, mean_1000lux_female.mean_SelectedPixelDifference, '-s', 'DisplayName', '1000 Lux Female', 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--');

% Plot the difference between the two conditions by gender
p5 = plot(hours, difference_male, '-^', 'DisplayName', 'Difference Male', 'Color', 'g', 'LineWidth', 2);
p6 = plot(hours, difference_female, '-^', 'DisplayName', 'Difference Female', 'Color', 'm', 'LineWidth', 2);

addShadedAreaToPlotZT24Hour();

% Ensure the lines are visible
uistack(p1, 'top'); 
uistack(p2, 'top'); 
uistack(p3, 'top'); 
uistack(p4, 'top'); 
uistack(p5, 'top'); 
uistack(p6, 'top'); 

% Add plot settings
title('Mean SelectedPixelDifference and Differences Over 24 Hours by Gender', 'FontSize', 20, 'FontWeight', 'bold');
xlabel('Hour of Day', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Mean SelectedPixelDifference', 'FontSize', 18, 'FontWeight', 'bold');
legend('show', 'Location', 'northeast', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'FontSize', 14, 'FontWeight', 'bold');
grid on;

hold off;

disp('Done');

%% Functions
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