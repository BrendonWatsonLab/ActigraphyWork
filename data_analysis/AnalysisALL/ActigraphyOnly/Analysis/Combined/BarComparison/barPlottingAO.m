% Load data
data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyOnly/AOActivityData.csv');
save_directory = '/Users/noahmuscat/Desktop';

% Ensure 'RelativeDay' is numeric
if ~isnumeric(data.RelativeDay)
    data.RelativeDay = str2double(string(data.RelativeDay));
end

% Define male and female animals
maleAnimals = {'AO1', 'AO2', 'AO3', 'AO7'};
femaleAnimals = {'AO4', 'AO5', 'AO6', 'AO8'};

% Define the desired order of conditions
conditionOrder = {'300Lux', '1000Lux', 'FullDark', '300LuxEnd'};

% Convert 'Condition' and 'Animal' into categorical variables
data.Condition = categorical(data.Condition, conditionOrder, 'Ordinal', true);
data.Animal = categorical(data.Animal);

% Use floor to group by integer days based on 'RelativeDay'
data.RelativeDay = floor(data.RelativeDay);

% Convert 'RelativeDay' to categorical
data.RelativeDay = categorical(data.RelativeDay);

% Function to plot data by gender
function plotByGender(data, animals, gender, conditionOrder, save_directory)
    % Filter data for the specified gender
    genderData = data(ismember(data.Animal, animals), :);

    % Initialize cell arrays to store data for each condition
    condData = cell(length(conditionOrder), 1);
    
    % Aggregate data for each condition
    for condIdx = 1:length(conditionOrder)
        condition = conditionOrder{condIdx};
        thisConditionData = genderData(genderData.Condition == condition, :);
        dailyMeans = varfun(@mean, thisConditionData, 'InputVariables', 'NormalizedActivity', ...
                            'GroupingVariables', 'RelativeDay');
        condData{condIdx} = dailyMeans.mean_NormalizedActivity;
    end

    % Combine data and create group variable for ANOVA
    allData = vertcat(condData{:});
    group = arrayfun(@(i) repmat(conditionOrder(i), size(condData{i})), 1:length(conditionOrder), 'UniformOutput', false);
    group = categorical(vertcat(group{:}));

    % Perform one-way ANOVA
    [~, tbl, stats] = anova1(allData, group, 'off');

    % Post-hoc multiple comparisons
    comparisons = multcompare(stats, 'CType', 'tukey-kramer', 'Display', 'off');

    % Calculate mean and standard error for each condition
    means = cellfun(@mean, condData);
    stderr = cellfun(@(x) std(x) / sqrt(length(x)), condData);

    % Plot the data
    figure;
    bar(means, 'FaceColor', [0.7 0.7 0.7]); % Gray bars
    hold on;
    errorbar(1:length(conditionOrder), means, stderr, 'k', 'LineStyle', 'none');
    set(gca, 'XTickLabel', conditionOrder)
    ylabel('Normalized Activity');
    title(['Comparison of Normalized Activity Across Conditions (', gender, ')']);

    % Mark significance using sigstar
    significanceGroups = {};
    significancePValues = [];
    sigThreshold = 0.05;

    for i = 1:size(comparisons, 1)
        if comparisons(i, 6) < sigThreshold % Only consider significant comparisons
            significanceGroups{end + 1} = comparisons(i, 1:2); 
            significancePValues(end + 1) = comparisons(i, 6); 
        end
    end

    % Add significance stars
    if exist('sigstar', 'file') == 2 && ~isempty(significanceGroups)
        numSigs = length(significanceGroups);
        sigYOffset = 0.05 * (max(means + stderr) - min(means - stderr));
        yMax = max(means + stderr) + numSigs * sigYOffset;
        ylim([min(0, min(means - stderr)), yMax]);

        for k = 1:numSigs
            sigstar(significanceGroups(k), significancePValues(k));
        end
    else
        warning('sigstar function is not available. Please ensure sigstar is added to the path or that there are significant comparisons.');
    end

    save_filename = sprintf('%s--BarComparison.png', gender); % Construct the filename
    saveas(gcf, fullfile(save_directory, save_filename)); % Save the figure

    hold off;
end

% Plot data for males
plotByGender(data, maleAnimals, 'Males', conditionOrder, save_directory);

% Plot data for females
plotByGender(data, femaleAnimals, 'Females', conditionOrder, save_directory);