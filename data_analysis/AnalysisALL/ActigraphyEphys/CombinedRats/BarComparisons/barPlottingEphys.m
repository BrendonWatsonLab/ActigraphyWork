% Load data
data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyEphys/EphysActivityData.csv');
save_directory = '/Users/noahmuscat/Desktop';

% Ensure 'RelativeDay' is numeric and integer
if ~isnumeric(data.RelativeDay)
    data.RelativeDay = str2double(string(data.RelativeDay));
end
data.RelativeDay = floor(data.RelativeDay);

% Define the desired order of conditions
conditionOrder = {'300Lux', '1000Lux1', '1000Lux4', 'sleep_deprivation'};
validConditionOrder = {'300Lux', '1000Lux1', '1000Lux4', 'sleepDeprivation'};


% Convert 'Condition' and 'Animal' into categorical variables
data.Condition = categorical(data.Condition, conditionOrder, 'Ordinal', true);
data.Animal = categorical(data.Animal);

% Convert 'RelativeDay' to categorical
data.RelativeDay = categorical(data.RelativeDay);

function plotAllAnimals(data, conditionOrder, save_directory, includeStats, validConditionOrder)
    % Convert 'Condition' and 'Animal' into categorical variables
    data.Condition = categorical(data.Condition, conditionOrder, 'Ordinal', true);
    data.Animal = categorical(data.Animal);

    % Initialize arrays to store means and errors
    means = [];
    stderr = [];
    labels = {};

    % Dictionary to keep last segments for comparison if including stats
    lastDataSegments = containers.Map('KeyType', 'char', 'ValueType', 'any');
    
    for condIdx = 1:length(conditionOrder)
        condition = conditionOrder{condIdx};
        validCondition = validConditionOrder{condIdx};
        thisConditionData = data(data.Condition == condition, :);
        
        uniqueDays = unique(thisConditionData.RelativeDay);
        numUniqueDays = length(uniqueDays);
        
        % Determine first 4 days or all days if < 8, and last 4 days
        if numUniqueDays < 8
            selectedDaysFirst = uniqueDays;
            selectedDaysLast = uniqueDays;
            currentLabelFirst = [char(validCondition), ' (All days)'];
        else
            selectedDaysFirst = uniqueDays(1:4);
            selectedDaysLast = uniqueDays(end-3:end);
            currentLabelFirst = [char(validCondition), ' (First 4 days)'];
        end

        % Compute statistics for the first segment
        firstSegment = thisConditionData(ismember(thisConditionData.RelativeDay, selectedDaysFirst), :);
        meanFirst = mean(varfun(@mean, firstSegment, 'InputVariables', 'NormalizedActivity', ...
                                'GroupingVariables', 'RelativeDay').mean_NormalizedActivity);
        stderrFirst = std(varfun(@mean, firstSegment, 'InputVariables', 'NormalizedActivity', ...
                                 'GroupingVariables', 'RelativeDay').mean_NormalizedActivity) ...
                      / sqrt(height(varfun(@mean, firstSegment, 'InputVariables', 'NormalizedActivity', ...
                                           'GroupingVariables', 'RelativeDay')));
        if ~includeStats % Only add the first or all days if we are not focusing on stats
            means(end+1) = meanFirst;
            stderr(end+1) = stderrFirst;
            labels{end+1} = currentLabelFirst;
        end
        
        % Compute statistics for the last segment (or use all days if < 8)
        if numUniqueDays >= 8 || includeStats
            lastSegment = thisConditionData(ismember(thisConditionData.RelativeDay, selectedDaysLast), :);
            meanLast = mean(varfun(@mean, lastSegment, 'InputVariables', 'NormalizedActivity', ...
                                   'GroupingVariables', 'RelativeDay').mean_NormalizedActivity);
            stderrLast = std(varfun(@mean, lastSegment, 'InputVariables', 'NormalizedActivity', ...
                                    'GroupingVariables', 'RelativeDay').mean_NormalizedActivity) ...
                         / sqrt(height(varfun(@mean, lastSegment, 'InputVariables', 'NormalizedActivity', ...
                                              'GroupingVariables', 'RelativeDay')));
            means(end+1) = meanLast;
            stderr(end+1) = stderrLast;
            if numUniqueDays < 8
                labels{end+1} = [char(validCondition), ' (All days)'];
            else
                labels{end+1} = [char(validCondition), ' (Last 4 days)'];
            end
        end
        
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
        title(['Activity Comparison: Last 4 Days by Condition']);
    else
        title(['Activity Comparison: First and Last 4 Days by Condition']);
    end
    grid on; % Add grid

    % Run statistical tests and add significance bars (if needed)
    if includeStats
        sigPairs = {};
        pValues = [];
        conditionKeys = keys(lastDataSegments); % Extract keys (condition names)
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
        save_filename = 'AllAnimals--LastDayComparisonWithErrorBars.png';
    else
        save_filename = 'AllAnimals--FirstLastComparisonWithErrorBars.png';
    end
    saveas(gcf, fullfile(save_directory, save_filename));
    hold off;
end

% Example call without stats
conditionOrder = {'300Lux', '1000Lux1', '1000Lux4', 'sleep_deprivation'};
validConditionOrder = {'300Lux', '1000Lux1', '1000Lux4', 'sleepDeprivation'};
plotAllAnimals(data, conditionOrder, save_directory, false, validConditionOrder);

% Example call with stats
plotAllAnimals(data, conditionOrder, save_directory, true, validConditionOrder);