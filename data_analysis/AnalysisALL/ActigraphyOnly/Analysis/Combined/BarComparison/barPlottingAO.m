% Load data
data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyOnly/AOActivityData.csv');
save_directory = '/Users/noahmuscat/Desktop';

% Ensure 'RelativeDay' is numeric and integer
if ~isnumeric(data.RelativeDay)
    data.RelativeDay = str2double(string(data.RelativeDay));
end
data.RelativeDay = floor(data.RelativeDay);

% Define male and female animals
maleAnimals = {'AO1', 'AO2', 'AO3', 'AO7'};
femaleAnimals = {'AO4', 'AO5', 'AO6', 'AO8'};

% Define the desired order of conditions
conditionOrder = {'300Lux', '1000Lux', 'FullDark', '300LuxEnd'};

% Convert 'Condition' and 'Animal' into categorical variables
data.Condition = categorical(data.Condition, conditionOrder, 'Ordinal', true);
data.Animal = categorical(data.Animal);

% Convert 'RelativeDay' to categorical
data.RelativeDay = categorical(data.RelativeDay);

% Function to plot data by gender with first and last 7 days logic
function plotByGender(data, animals, gender, conditionOrder, save_directory, includeStats)
    % Analyze data for the specified gender
    genderData = data(ismember(data.Animal, animals), :);
    
    % Initialize arrays to store means and errors
    means = [];
    stderr = [];
    labels = {};

    % Dictionary to keep last segments for comparison
    lastDataSegments = containers.Map('KeyType', 'char', 'ValueType', 'any');
    
    for condIdx = 1:length(conditionOrder)
        condition = conditionOrder{condIdx};
        thisConditionData = genderData(genderData.Condition == condition, :);
        
        uniqueDays = unique(thisConditionData.RelativeDay);
        numUniqueDays = length(uniqueDays);
        
        % First 7 days or all days if less than 14
        if numUniqueDays < 14
            selectedDaysFirst = uniqueDays;
            selectedDaysLast = uniqueDays;
            currentLabelFirst = [char(condition), ' (All days)'];
        else
            selectedDaysFirst = uniqueDays(1:7);
            selectedDaysLast = uniqueDays(end-6:end);
            currentLabelFirst = [char(condition), ' (First 7 days)'];
        end
        
        % Compute statistics for the first segment
        firstSegment = thisConditionData(ismember(thisConditionData.RelativeDay, selectedDaysFirst), :);
        meanFirst = mean(varfun(@mean, firstSegment, 'InputVariables', 'NormalizedActivity', ...
                                'GroupingVariables', 'RelativeDay').mean_NormalizedActivity);
        stderrFirst = std(varfun(@mean, firstSegment, 'InputVariables', 'NormalizedActivity', ...
                                 'GroupingVariables', 'RelativeDay').mean_NormalizedActivity) ...
                      / sqrt(height(varfun(@mean, firstSegment, 'InputVariables', 'NormalizedActivity', ...
                                           'GroupingVariables', 'RelativeDay')));
        if ~includeStats % Only add the first 7 days if we are not focusing on stats
            means(end+1) = meanFirst;
            stderr(end+1) = stderrFirst;
            labels{end+1} = currentLabelFirst;
        end
        
        % Compute statistics for the last segment
        lastSegment = thisConditionData(ismember(thisConditionData.RelativeDay, selectedDaysLast), :);
        meanLast = mean(varfun(@mean, lastSegment, 'InputVariables', 'NormalizedActivity', ...
                               'GroupingVariables', 'RelativeDay').mean_NormalizedActivity);
        stderrLast = std(varfun(@mean, lastSegment, 'InputVariables', 'NormalizedActivity', ...
                                'GroupingVariables', 'RelativeDay').mean_NormalizedActivity) ...
                     / sqrt(height(varfun(@mean, lastSegment, 'InputVariables', 'NormalizedActivity', ...
                                          'GroupingVariables', 'RelativeDay')));
        means(end+1) = meanLast;
        stderr(end+1) = stderrLast;
        labels{end+1} = [char(condition), ' (Last 7 days)'];
        
        if includeStats
            lastDataSegments(char(condition)) = lastSegment.NormalizedActivity;
        end
    end
    
    % Plot the data
    figure;
    colormap(jet(length(means))); % Use a colormap for distinct colors
    bar_handle = bar(means, 'FaceColor', 'flat');
    for k = 1:length(means)
        bar_handle.CData(k,:) = rand(1,3);  % Set color for each bar
    end
    hold on;
    errorbar(1:length(means), means, stderr, '.k', 'LineWidth', 1.5, 'CapSize', 10); % Larger caps on error bars
    set(gca, 'XTickLabel', labels, 'XTick', 1:length(labels));
    xtickangle(45);
    ylabel('Normalized Activity');
    if includeStats
        title(['Activity Comparison: Last 7 Days by Condition (', gender, ')']);
    else
        title(['Activity Comparison: First and Last 7 Days by Condition (', gender, ')']);
    end
    grid on; % Add grid
    
    % Run statistical tests and add significance bars (if needed)
    if includeStats
        sigPairs = {};
        pValues = [];
        conditionKeys = keys(lastDataSegments); % Rename the variable to avoid conflict
        for i = 1:length(conditionKeys)
            for j = i+1:length(conditionKeys)
                cond1 = conditionKeys{i};
                cond2 = conditionKeys{j};
                [~, p] = ttest2(lastDataSegments(cond1), lastDataSegments(cond2));
                if p < 0.05
                    sigPairs{end+1} = [i, j];
                    pValues(end+1) = p;
                end
            end
        end
    
        % Only add sigstar if sigPairs is available
        if exist('sigstar', 'file') && ~isempty(sigPairs)
            sigstar(sigPairs, pValues);
        end
    end
    
    if includeStats
        save_filename = sprintf('%s--LastDayComparisonWithErrorBars.png', gender);
    else
        save_filename = sprintf('%s--FirstLastComparisonWithErrorBars.png', gender);
    end
    saveas(gcf, fullfile(save_directory, save_filename));
    hold off;
end

% Example call without stats
plotByGender(data, maleAnimals, 'Males', conditionOrder, save_directory, false);

% Example call with stats
plotByGender(data, maleAnimals, 'Males', conditionOrder, save_directory, true);

% Add a similar call for females
plotByGender(data, femaleAnimals, 'Females', conditionOrder, save_directory, false);
plotByGender(data, femaleAnimals, 'Females', conditionOrder, save_directory, true);