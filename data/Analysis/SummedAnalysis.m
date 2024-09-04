%% Combining and Normalizing Data
% List of rat IDs and conditions
ratIDs = {'Rollo', 'Canute', 'Harald', 'Gunnar', 'Egil', 'Sigurd', 'Olaf'}; % Add more rat IDs as needed
conditions = {'300Lux', '1000Lux1', '1000Lux4'};

dataDir = '/home/noahmu/Documents/JeremyData/ZT';
% Initialize variables to hold combined data for baseline-normalized z-scores
baselineNormalized300Lux = [];
baselineNormalized1000Lux1 = [];
baselineNormalized1000Lux4 = [];

animalID = [];
conditionID = [];
movementData = [];

% Loop over each rat and normalize to the 300 Lux condition
for i = 1:length(ratIDs)
    ratID = ratIDs{i};
    
    % Load 300 Lux data (baseline)
    baselineFilename = fullfile(dataDir, ratID, sprintf('%s_300Lux.csv', ratID));
    if isfile(baselineFilename)
        baselineTable = readtable(baselineFilename);
        
        if ismember('SelectedPixelDifference', baselineTable.Properties.VariableNames)
            baselineData = baselineTable.SelectedPixelDifference;
            baselineMean = mean(baselineData, 'omitnan');
            baselineStd = std(baselineData, 'omitnan');

            % Normalize each condition using the baseline mean and std
            for j = 1:length(conditions)
                condition = conditions{j};

                % Construct the filename and full path
                filename = sprintf('%s_%s.csv', ratID, condition);
                fullPath = fullfile(dataDir, ratID, filename);

                % Check if the file exists
                if isfile(fullPath)
                    % Load the data from the CSV file using readtable
                    fprintf('Analyzing: %s\n', fullPath);
                    dataTable = readtable(fullPath);
                    
                    % Check if the specified column exists
                    if ismember('SelectedPixelDifference', dataTable.Properties.VariableNames)
                        data = dataTable.SelectedPixelDifference;

                        % Normalize the data to the 300 Lux baseline
                        norm_data = (data - baselineMean) / baselineStd;

                        % Append data with identifiers to the combined vectors
                        animalID = [animalID; repmat({ratID}, length(norm_data), 1)];
                        conditionID = [conditionID; repmat({condition}, length(norm_data), 1)];
                        movementData = [movementData; norm_data];
                    else
                        fprintf('Column "SelectedPixelDifference" not found in file: %s\n', fullPath);
                    end
                else
                    fprintf('File not found: %s\n', fullPath);  % Log missing files
                end
            end
        else
            fprintf('Column "SelectedPixelDifference" not found in baseline file: %s\n', baselineFilename);
        end
    else
        fprintf('Baseline file not found: %s\n', baselineFilename);
    end
end

% Create a table to combine data from all conditions and animals
combinedData = table(animalID, conditionID, movementData, ...
                     'VariableNames', {'Animal', 'Condition', 'SelectedPixelDiff'});

% Define the directory where to save the combined CSV file
saveDir = '/home/noahmu/Documents/JeremyData'; % <-- Change this to your desired path

% Ensure the directory exists (create if it does not exist)
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end

% Define the filename and combine it with the save path
combinedFilename = 'combined_normalized_data.csv';
fullFilePath = fullfile(saveDir, combinedFilename);

% Write the combined table to a CSV file
writetable(combinedData, fullFilePath);

disp(['Done normalizing and pooling the data. Combined data saved to ', fullFilePath]);

%% Plotting
% List of conditions for plotting
conditions = {'300Lux', '1000Lux1', '1000Lux4'};

% Calculate mean and standard error for each condition
means = zeros(length(conditions), 1);
stderr = zeros(length(conditions), 1);

% Group data for each condition
data300Lux = combinedData.SelectedPixelDiff(strcmp(combinedData.Condition, '300Lux'));
data1000Lux1 = combinedData.SelectedPixelDiff(strcmp(combinedData.Condition, '1000Lux1'));
data1000Lux4 = combinedData.SelectedPixelDiff(strcmp(combinedData.Condition, '1000Lux4'));

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
saveas(gcf, fullfile(saveDir, 'Activity_Comparison_BarPlot_with_Significance.png'));

disp('Bar plot with statistical significance markers generated and saved.');


