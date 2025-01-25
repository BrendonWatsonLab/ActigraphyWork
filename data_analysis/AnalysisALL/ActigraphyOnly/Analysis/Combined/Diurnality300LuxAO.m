% Read the combined data table
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyOnly/AOActivityData.csv');
save_directory = '/Users/noahmuscat/Desktop';

% Filter only data for '300Lux' condition
combined_data = combined_data(strcmp(combined_data.Condition, '300Lux'), :);

animalIDs = {'AO1', 'AO2'}

% Assign each data point a gender
combined_data.Gender = cell(height(combined_data), 1); % Initialize Gender column
for i = 1:length(animalIDs)
    animalIndices = strcmp(combined_data.Animal, animalIDs{i});
    combined_data.Gender(animalIndices) = repmat({genders{i}}, sum(animalIndices), 1);
end

AnalyzeCircadianRunningGender(combined_data, false, 'All Rats', save_directory);

%% Circadian Analysis AO
% Pool data by gender and plot means at each hour of the day
combined_data.Hour = hour(combined_data.DateZT);

% Calculate hourly means using NormalizedActivity
hourlyMeanMale = groupsummary(combined_data(strcmp(combined_data.Gender, 'Male'), :), 'Hour', 'mean', 'NormalizedActivity');
hourlyMeanFemale = groupsummary(combined_data(strcmp(combined_data.Gender, 'Female'), :), 'Hour', 'mean', 'NormalizedActivity');

hours48 = [hourlyMeanMale.Hour; hourlyMeanMale.Hour + 24];
meansMale48 = [hourlyMeanMale.mean_NormalizedActivity; hourlyMeanMale.mean_NormalizedActivity];
meansFemale48 = [hourlyMeanFemale.mean_NormalizedActivity; hourlyMeanFemale.mean_NormalizedActivity];

figure;
hold on;
b1 = bar(hours48, meansMale48, 'FaceColor', 'b', 'BarWidth', 1, 'DisplayName', 'Male');
b2 = bar(hours48, meansFemale48, 'FaceColor', 'r', 'BarWidth', 0.5, 'DisplayName', 'Female');
addShadedAreaToPlotZT48Hour();

uistack(b1, 'top'); 
uistack(b2, 'top');

title('Animal Circadian Means Over 48 Hours by Gender (300Lux)', 'FontSize', 20, 'FontWeight', 'bold');
xlabel('Hour of the Day', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('NormalizedActivity', 'FontSize', 18, 'FontWeight', 'bold');
legend('Location', 'BestOutside');
set(gca, 'FontSize', 14, 'FontWeight', 'bold');
hold off;

save_filename = sprintf('Circadian48HourPlot.png'); % Construct the filename
saveas(gcf, fullfile(save_directory, save_filename)); % Save the figure

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

    xlim([-0.5, 47.5]);
    xticks(0:1:47);
    xtickangle(90);
    hold off;
end