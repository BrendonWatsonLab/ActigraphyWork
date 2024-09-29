%% Combining and Normalizing Data
% List of rat IDs and conditions
ratIDs = {'Rollo', 'Canute', 'Harald', 'Gunnar', 'Egil', 'Sigurd', 'Olaf'}; % Add more rat IDs as needed
conditions = {'300Lux', '1000Lux1', '1000Lux4'};

dataDir = '/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyEphys/ZT';

combinedData = Normalizer(dataDir, ratIDs, conditions);

%% Plotting
% List of conditions for plotting
conditions = {'300Lux', '1000Lux1', '1000Lux4'};

% Calculate mean and standard error for each condition
means = zeros(length(conditions), 1);
stderr = zeros(length(conditions), 1);

% Group data for each condition
data300Lux = combinedData.SelectedPixelDifference(strcmp(combinedData.Condition, '300Lux'));
data1000Lux1 = combinedData.SelectedPixelDifference(strcmp(combinedData.Condition, '1000Lux1'));
data1000Lux4 = combinedData.SelectedPixelDifference(strcmp(combinedData.Condition, '1000Lux4'));

% Calculate means and standard errors
means(1) = mean(data300Lux);
means(2) = mean(data1000Lux1);
means(3) = mean(data1000Lux4);
stderr(1) = std(data300Lux) / sqrt(length(data300Lux)); % Standard error
stderr(2) = std(data1000Lux1) / sqrt(length(data1000Lux1)); % Standard error
stderr(3) = std(data1000Lux4) / sqrt(length(data1000Lux4)); % Standard error

% Perform independent t-tests between conditions
[h1, p1] = ttest2(data300Lux, data1000Lux1);
[h2, p2] = ttest2(data300Lux, data1000Lux4);
[h3, p3] = ttest2(data1000Lux1, data1000Lux4);

% Define significance level
alpha = 0.05;

% Outputting values
fprintf('p-value for 300Lux vs 1000LuxWeek1: %f\n', p1);
fprintf('p-value for 300Lux vs 1000LuxWeek4: %f\n', p2);
fprintf('p-value for 1000LuxWeek1 vs 1000LuxWeek4: %f\n', p3);

% Create the bar plot
figure;
bar(means);
hold on;
errorbar(1:length(conditions), means, stderr, 'k', 'LineStyle', 'none');
set(gca, 'XTickLabel', conditions);
ylabel('Normalized Activity (z-score)');
title('Comparison of Activity Across Lighting Conditions');

% Add significance markers
y_max = max([means(1) + stderr(1),means(2) + stderr(2), means(3) + stderr(3)]) * 1.1; % Adjust these values as needed for clarity
line_y = y_max;

% Add asterisk and lines for first comparison (300 Lux Week 1 vs 1000 Lux Week 1)
    if p1 < 0.05
        plot([1, 2], [line_y, line_y], '-k', 'LineWidth', 1.5);
        plot([1 1], [line_y * 0.95, line_y], '-k', 'LineWidth', 1.5); % Left notch
        plot([2 2], [line_y * 0.95, line_y], '-k', 'LineWidth', 1.5); % Right notch
        text(1.5, line_y * 1.05, '*', 'FontSize', 20, 'HorizontalAlignment', 'center');
    end
    
    % Add asterisk and lines for second comparison (300 Lux Week 1 vs 1000 Lux Week 4)
    if p2 < 0.05
        y_max2 = line_y * 1.15;
        plot([1, 3], [y_max2, y_max2], '-k', 'LineWidth', 1.5);
        plot([1 1], [y_max2 * 0.95, y_max2], '-k', 'LineWidth', 1.5); % Left notch
        plot([3 3], [y_max2 * 0.95, y_max2], '-k', 'LineWidth', 1.5); % Right notch
        text(2, y_max2 * 1.05, '*', 'FontSize', 20, 'HorizontalAlignment', 'center');
        y_max = y_max2; % Update y_max to the new height
    end

    % Add asterisk and lines for third comparison (1000 Lux Week 1 vs 1000 Lux Week 4)
    if p3 < 0.05
        plot([2, 3], [line_y, line_y], '-k', 'LineWidth', 1.5);
        plot([2 2], [line_y * 0.95, line_y], '-k', 'LineWidth', 1.5); % Left notch
        plot([3 3], [line_y * 0.95, line_y], '-k', 'LineWidth', 1.5); % Right notch
        text(2.5, line_y * 1.05, '*', 'FontSize', 20, 'HorizontalAlignment', 'center');
    end
    
    ylim([-0.05, y_max * 1.3]); % Adjust the y-axis limits to accommodate the significance lines and asterisks

hold off;

% Save the figure if necessary
%saveas(gcf, fullfile(saveDir, 'Activity_Comparison_BarPlot_with_Significance.png'));

disp('Bar plot with statistical significance markers generated and saved.');


