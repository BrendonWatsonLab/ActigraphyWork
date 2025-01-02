%% Combining and Normalizing Data
% List of rat IDs and conditions
combinedData = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/AO1-8binned_data.csv');

%% Plotting
% List of conditions for plotting
conditions = {'300Lux', '1000Lux'};

% Calculate mean and standard error for each condition
means = zeros(length(conditions), 1);
stderr = zeros(length(conditions), 1);

% Group data for each condition
data300Lux = combinedData.SelectedPixelDifference(strcmp(combinedData.Condition, '300Lux'));
data1000Lux = combinedData.SelectedPixelDifference(strcmp(combinedData.Condition, '1000Lux'));

% Calculate means and standard errors
means(1) = mean(data300Lux);
means(2) = mean(data1000Lux);
stderr(1) = std(data300Lux) / sqrt(length(data300Lux)); % Standard error
stderr(2) = std(data1000Lux) / sqrt(length(data1000Lux)); % Standard error

% Perform independent t-tests between conditions
[h1, p1] = ttest2(data300Lux, data1000Lux);

% Define significance level
alpha = 0.05;

% Outputting values
fprintf('p-value for 300Lux vs 1000Lux: %f\n', p1);

% Create the bar plot
figure;
bar(means);
hold on;
errorbar(1:length(conditions), means, stderr, 'k', 'LineStyle', 'none');
set(gca, 'XTickLabel', conditions, 'FontSize', 14, 'FontWeight', 'bold');  % Increase font size and bold
ylabel('Normalized Activity (z-score)', 'FontSize', 18, 'FontWeight', 'bold');  % Increase font size and bold
title('Comparison of Activity Across Lighting Conditions', 'FontSize', 20, 'FontWeight', 'bold');  % Increase font size and bold

% Add significance markers
y_max = max([means(1) + stderr(1), means(2) + stderr(2)]) * 1.1; % Adjust these values as needed for clarity
line_y = y_max;

% Add asterisk and lines for the comparison (300 Lux vs 1000 Lux)
if p1 < 0.05
    plot([1, 2], [line_y, line_y], '-k', 'LineWidth', 1.5);
    plot([1 1], [line_y * 0.95, line_y], '-k', 'LineWidth', 1.5); % Left notch
    plot([2 2], [line_y * 0.95, line_y], '-k', 'LineWidth', 1.5); % Right notch
    text(1.5, line_y * 1.05, '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold'); % Increase font size and bold
end

ylim([-0.05, y_max * 1.3]); % Adjust the y-axis limits to accommodate the significance lines and asterisks

hold off;

% Save the figure if necessary
%saveas(gcf, fullfile(saveDir, 'Activity_Comparison_BarPlot_with_Significance.png'));

disp('Bar plot with statistical significance markers generated and saved.');


