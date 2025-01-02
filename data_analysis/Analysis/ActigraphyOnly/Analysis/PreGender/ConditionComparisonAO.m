%% Combining and Normalizing Data
% This script processes and analyzes activity data from multiple rats under different lighting conditions.
% Steps include reading in the combined data, calculating mean and standard error, performing t-tests,
% and plotting bar graphs with significance markers.

%% Synopsis
% This MATLAB script reads activity data from a CSV file, calculates the mean activity and standard error
% for different lighting conditions (300Lux and 1000Lux), performs t-tests to compare the conditions,
% and creates bar plots with significance markers.

% Read in the combined data table
combinedData = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/AO1-8binned_data.csv');

%% Plotting
% List of conditions for plotting
conditions = {'300Lux', '1000Lux'};

% Initialize arrays to store means and standard errors
means = zeros(length(conditions), 1);
stderr = zeros(length(conditions), 1);

% Group data for each condition
data300Lux = combinedData.SelectedPixelDifference(strcmp(combinedData.Condition, '300Lux'));
data1000Lux = combinedData.SelectedPixelDifference(strcmp(combinedData.Condition, '1000Lux'));

% Calculate means and standard errors for each condition
means(1) = mean(data300Lux);
means(2) = mean(data1000Lux);
stderr(1) = std(data300Lux) / sqrt(length(data300Lux)); % Standard error for 300Lux
stderr(2) = std(data1000Lux) / sqrt(length(data1000Lux)); % Standard error for 1000Lux

% Perform independent t-tests between conditions
[h1, p1] = ttest2(data300Lux, data1000Lux);

% Output the p-values
fprintf('p-value for 300Lux vs 1000Lux: %f\n', p1);

% Create the bar plot showing means and standard errors
figure;
bar(means);
hold on;
errorbar(1:length(conditions), means, stderr, 'k', 'LineStyle', 'none'); % Add error bars
set(gca, 'XTickLabel', conditions, 'FontSize', 14, 'FontWeight', 'bold'); % X-axis labels with increased font size and bold
ylabel('Normalized Activity (z-score)', 'FontSize', 18, 'FontWeight', 'bold'); % Y-axis label with increased font size and bold
title('Comparison of Activity Across Lighting Conditions', 'FontSize', 20, 'FontWeight', 'bold'); % Plot title with increased font size and bold

% Add significance markers if p-value < alpha
alpha = 0.05;
y_max = max([means(1) + stderr(1), means(2) + stderr(2)]) * 1.1; % Determine y-max for plotting significance lines
line_y = y_max; % Position for significance lines and markers

if p1 < alpha
    % Plot significance lines and asterisk for the comparison 300 Lux vs 1000 Lux
    plot([1, 2], [line_y, line_y], '-k', 'LineWidth', 1.5); % Horizontal line
    plot([1 1], [line_y * 0.95, line_y], '-k', 'LineWidth', 1.5); % Left notch
    plot([2 2], [line_y * 0.95, line_y], '-k', 'LineWidth', 1.5); % Right notch
    text(1.5, line_y * 1.05, '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold'); % Asterisk for significance
end

% Set y-axis limits
ylim([-0.05, y_max * 1.3]); % Adjust y-axis limits

hold off;

% Optional: Save the plot
% saveas(gcf, fullfile(saveDir, 'Activity_Comparison_BarPlot_with_Significance.png'));

disp('Bar plot with statistical significance markers generated and saved.');