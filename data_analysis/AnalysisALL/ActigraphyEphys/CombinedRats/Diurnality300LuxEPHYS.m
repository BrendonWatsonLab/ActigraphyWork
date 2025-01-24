% Read the combined data table
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyEphys/EphysActivityData.csv');
save_directory = '/Users/noahmuscat/Desktop';

% Ensure 'Condition' and 'DateZT' columns exist in the table
if ~all(ismember({'Condition', 'DateZT', 'NormalizedActivity'}, combined_data.Properties.VariableNames))
    error('The required columns are missing from the data table.');
end

% Filter only data for '300Lux' condition
combined_data = combined_data(strcmp(combined_data.Condition, '300Lux'), :);

% Perform Circadian Analysis
AnalyzeCircadianRunning(combined_data, false, 'All Rats', save_directory);

%% Circadian Analysis AO
% Pool data and plot means at each hour of the day
combined_data.Hour = hour(combined_data.DateZT);

% Calculate hourly means using NormalizedActivity
hourlyMean = groupsummary(combined_data, 'Hour', 'mean', 'NormalizedActivity');

% Extend to 48-hour format
hours48 = [hourlyMean.Hour; hourlyMean.Hour + 24];
means48 = [hourlyMean.mean_NormalizedActivity; hourlyMean.mean_NormalizedActivity];

% Plot the results
figure;
hold on;
b = bar(hours48, means48, 'FaceColor', 'b', 'BarWidth', 1, 'DisplayName', 'All Animals');
addShadedAreaToPlotZT48Hour();

uistack(b, 'top'); 

title('Animal Circadian Means Over 48 Hours (300Lux)', 'FontSize', 20, 'FontWeight', 'bold');
xlabel('Hour of the Day', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('NormalizedActivity', 'FontSize', 18, 'FontWeight', 'bold');
legend('Location', 'BestOutside');
set(gca, 'FontSize', 14, 'FontWeight', 'bold');
hold off;

% Save the figure
save_filename = 'Circadian48HourPlot.png';
saveas(gcf, fullfile(save_directory, save_filename)); % Consider path validation

% Add shaded area function
function addShadedAreaToPlotZT48Hour()
    % This function adds shaded areas to indicate dark phases
    hold on;
    
    % Define x and y coordinates for the shaded areas
    x_shaded1 = [12, 24, 24, 12];
    y_lim = ylim;
    y_shaded1 = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];
    x_shaded2 = [36, 48, 48, 36];
    y_shaded2 = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];
    
    fill_color = [0.7, 0.7, 0.7]; % Light gray color
    
    % Add shaded areas to the plot
    fill(x_shaded1, y_shaded1, fill_color, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    fill(x_shaded2, y_shaded2, fill_color, 'EdgeColor', 'none', 'HandleVisibility', 'off');

    xlim([-0.5, 47.5]);
    xticks(0:1:47);
    xtickangle(90);
    hold off;
end