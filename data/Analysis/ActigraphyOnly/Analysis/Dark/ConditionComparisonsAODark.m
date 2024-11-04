%% Combining and Normalizing Data
% List of rat IDs and conditions
combinedData = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/AO1-8Dark_binned_data.csv');

% Filter out AO1-4 from the data for 'FullDark' and '300LuxEnd'
combinedData_AO5_8 = combinedData(~(ismember(combinedData.Animal, {'AO1', 'AO2', 'AO3', 'AO4'}) & ismember(combinedData.Condition, {'FullDark', '300LuxEnd'})), :);

%% Plotting: 300Lux vs 1000Lux
% List of conditions for plotting
conditions1 = {'300Lux', '1000Lux'};

% Calculate mean and standard error for each condition
means1 = zeros(length(conditions1), 1);
stderr1 = zeros(length(conditions1), 1);

% Group data for each condition
data300Lux = combinedData_AO5_8.NormalizedActivity(strcmp(combinedData_AO5_8.Condition, '300Lux'));
data1000Lux = combinedData_AO5_8.NormalizedActivity(strcmp(combinedData_AO5_8.Condition, '1000Lux'));

% Calculate means and standard errors
means1(1) = mean(data300Lux);
means1(2) = mean(data1000Lux);
stderr1(1) = std(data300Lux) / sqrt(length(data300Lux)); % Standard error
stderr1(2) = std(data1000Lux) / sqrt(length(data1000Lux)); % Standard error

% Perform independent t-test between 300Lux and 1000Lux
[h1, p1] = ttest2(data300Lux, data1000Lux);

% Outputting values
fprintf('p-value for 300Lux vs 1000Lux: %f\n', p1);

% Create the bar plot for 300Lux vs 1000Lux
figure;
bar(means1);
hold on;
errorbar(1:length(conditions1), means1, stderr1, 'k', 'LineStyle', 'none');
set(gca, 'XTickLabel', conditions1, 'FontSize', 14, 'FontWeight', 'bold');  % Increase font size and bold
ylabel('Normalized Activity (z-score)', 'FontSize', 18, 'FontWeight', 'bold');  % Increase font size and bold
title('Comparison of Activity: 300Lux vs 1000Lux', 'FontSize', 20, 'FontWeight', 'bold');  % Increase font size and bold

% Determine the y-limits considering both positive and negative values
max_y1 = max(means1 + stderr1); % Maximum value for y-axis scaling
min_y1 = min(means1 - stderr1); % Minimum value for y-axis scaling
line_y1 = max_y1 + 0.05 * abs(max_y1 - min_y1); % Initial line position for significance marker (adjusted above max value)
line_y1_neg = min_y1 - 0.05 * abs(max_y1 - min_y1); % Initial line position for significance marker (adjusted below min value)

% Add significance markers adjusted for negative values
if p1 < 0.05
    if max_y1 > 0 % For positive y-values
        plot([1, 2], [line_y1, line_y1], '-k', 'LineWidth', 1.5);
        text(1.5, line_y1 + 0.02 * abs(max_y1 - min_y1), '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    else % For negative y-values
        plot([1, 2], [line_y1_neg, line_y1_neg], '-k', 'LineWidth', 1.5);
        text(1.5, line_y1_neg + 0.02 * abs(max_y1 - min_y1), '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    end
end

ylim([min_y1 - 0.3 * abs(max_y1 - min_y1), max_y1 + 0.3 * abs(max_y1 - min_y1)]); % Adjust y-axis limits to provide extra space

hold off;

%% Plotting: 300Lux vs FullDark vs 300LuxEnd
% List of conditions for plotting
conditions2 = {'300Lux', 'FullDark', '300LuxEnd'};

% Calculate mean and standard error for each condition
means2 = zeros(length(conditions2), 1);
stderr2 = zeros(length(conditions2), 1);

% Group data for each condition
dataFullDark = combinedData_AO5_8.NormalizedActivity(strcmp(combinedData_AO5_8.Condition, 'FullDark'));
data300LuxEnd = combinedData_AO5_8.NormalizedActivity(strcmp(combinedData_AO5_8.Condition, '300LuxEnd'));

% Calculate means and standard errors
means2(1) = mean(data300Lux);
means2(2) = mean(dataFullDark);
means2(3) = mean(data300LuxEnd);
stderr2(1) = std(data300Lux) / sqrt(length(data300Lux)); % Standard error
stderr2(2) = std(dataFullDark) / sqrt(length(dataFullDark)); % Standard error
stderr2(3) = std(data300LuxEnd) / sqrt(length(data300LuxEnd)); % Standard error

% Perform independent t-tests between conditions
[h2, p2] = ttest2(data300Lux, dataFullDark);
[h3, p3] = ttest2(data300Lux, data300LuxEnd);
[h6, p6] = ttest2(dataFullDark, data300LuxEnd);

% Outputting values
fprintf('p-value for 300Lux vs FullDark: %f\n', p2);
fprintf('p-value for 300Lux vs 300LuxEnd: %f\n', p3);
fprintf('p-value for FullDark vs 300LuxEnd: %f\n', p6);

% Create the bar plot for 300Lux vs FullDark vs 300LuxEnd
figure;
bar(means2);
hold on;
errorbar(1:length(conditions2), means2, stderr2, 'k', 'LineStyle', 'none');
set(gca, 'XTickLabel', conditions2, 'FontSize', 14, 'FontWeight', 'bold');  % Increase font size and bold
ylabel('Normalized Activity (z-score)', 'FontSize', 18, 'FontWeight', 'bold');  % Increase font size and bold
title('Comparison of Activity: 300Lux vs FullDark vs 300LuxEnd', 'FontSize', 20, 'FontWeight', 'bold');  % Increase font size and bold

% Determine the y-limits considering both positive and negative values
max_y2 = max(means2 + stderr2); % Maximum value for y-axis scaling
min_y2 = min(means2 - stderr2); % Minimum value for y-axis scaling
line_y2 = max_y2 + 0.05 * abs(max_y2 - min_y2); % Initial line position for significance marker (adjusted above max value)
line_y2_neg = min_y2 - 0.05 * abs(max_y2 - min_y2); % Initial line position for significance marker (adjusted below min value)

% Add significance markers adjusted for negative values
increment_y = max_y2 * 0.05; % Small increment for stacking significance lines
increment_y_neg = min_y2 * 0.05; % Small increment for stacking significance lines negative values
if p2 < 0.05
    if max_y2 > 0 % For positive y-values
        plot([1, 2], [line_y2, line_y2], '-k', 'LineWidth', 1.5);
        text(1.5, line_y2 + increment_y, '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        line_y2 = line_y2 + 1.2 * increment_y;
    else % For negative y-values
        plot([1, 2], [line_y2_neg, line_y2_neg], '-k', 'LineWidth', 1.5);
        text(1.5, line_y2_neg + increment_y_neg, '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        line_y2_neg = line_y2_neg + 1.2 * increment_y_neg;
    end
end
if p3 < 0.05
    if max_y2 > 0 % For positive y-values
        plot([1, 3], [line_y2, line_y2], '-k', 'LineWidth', 1.5);
        text(2, line_y2 + increment_y, '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        line_y2 = line_y2 + 1.2 * increment_y;
    else % For negative y-values
        plot([1, 3], [line_y2_neg, line_y2_neg], '-k', 'LineWidth', 1.5);
        text(2, line_y2_neg + increment_y_neg, '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        line_y2_neg = line_y2_neg + 1.2 * increment_y_neg;
    end
end
if p6 < 0.05
    if max_y2 > 0 % For positive y-values
        plot([2, 3], [line_y2, line_y2], '-k', 'LineWidth', 1.5);
        text(2.5, line_y2 + increment_y, '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        line_y2 = line_y2 + 1.2 * increment_y;
    else % For negative y-values
        plot([2, 3], [line_y2_neg, line_y2_neg], '-k', 'LineWidth', 1.5);
        text(2.5, line_y2_neg + increment_y_neg, '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        line_y2_neg = line_y2_neg + 1.2 * increment_y_neg;
    end   
end

ylim([min_y2 - 0.3 * abs(max_y2 - min_y2), max_y2 + 0.3 * abs(max_y2 - min_y2)]); % Adjust y-axis limits to provide extra space

hold off;

% Save the figures if necessary
% saveas(gcf, fullfile(saveDir, 'Activity_Comparison_300Lux_vs_1000Lux.png'));
% saveas(gcf, fullfile(saveDir, 'Activity_Comparison_300Lux_vs_FullDark_vs_300LuxEnd.png'));

disp('Bar plots with statistical significance markers generated and saved.');