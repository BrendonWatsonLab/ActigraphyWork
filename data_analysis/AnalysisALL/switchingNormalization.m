%% Redoing normalization
% this script is used to redo normalization of the animal activity

%% For actigraphyEphys
% normalizing to the last 4 days of the 300Lux condition

% Read the CSV file as a table
data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyEphys/EphysActivityData.csv', 'PreserveVariableNames', true);

% Extract unique animals
animals = unique(data.Animal);

% Loop over each animal to calculate the baseline and update NormalizedActivity
for i = 1:length(animals)
    % Select current animal
    currAnimal = animals{i};
    
    % Find rows corresponding to the current animal and 300Lux condition
    isCurrentAnimal = strcmp(data.Animal, currAnimal);
    is300LuxCondition = strcmp(data.Condition, '300Lux');
    
    % Combine conditions
    currentEntries = isCurrentAnimal & is300LuxCondition;
    
    % Select data for these entries
    selectedData = data(currentEntries, :);
    
    % Sort by RelativeDay to make sure we have the last 4 days
    selectedData = sortrows(selectedData, 'RelativeDay', 'descend');
    
    % Select the last 4 days
    last4DaysData = selectedData(1:4, :);
    
    % Calculate baseline
    baseline = mean(last4DaysData.SelectedPixelDifference);
    
    % Calculate NormalizedActivity as SelectedPixelDifference / baseline
    isCurrentAnimalAllCond = strcmp(data.Animal, currAnimal);
    data.NormalizedActivity(isCurrentAnimalAllCond) = data.SelectedPixelDifference(isCurrentAnimalAllCond) / baseline;
end

% Save the modified table to a new CSV file
writetable(data, '/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyEphys/EphysActivityData.csv');

%% For actigraphyOnly
% normalizing to the last week of the 300Lux condition

% Read the CSV file as a table
data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyOnly/AOActivityData.csv', 'PreserveVariableNames', true);

% Extract unique animals
animals = unique(data.Animal);

% Loop over each animal to calculate the baseline and update NormalizedActivity
for i = 1:length(animals)
    % Select current animal
    currAnimal = animals{i};
    
    % Find rows corresponding to the current animal and 300Lux condition
    isCurrentAnimal = strcmp(data.Animal, currAnimal);
    is300LuxCondition = strcmp(data.Condition, '300Lux');
    
    % Combine conditions
    currentEntries = isCurrentAnimal & is300LuxCondition;
    
    % Select data for these entries and sort by RelativeDay
    selectedData = data(currentEntries, :);
    selectedData = sortrows(selectedData, 'RelativeDay', 'descend');
    
    % Verify there are enough days to calculate the baseline
    if height(selectedData) < 7
        warning('Insufficient data for animal %s in 300Lux condition to compute baseline. Skipping normalization.', currAnimal);
        continue;
    end
    
    % Calculate baseline from the last 7 days
    last7DaysData = selectedData(1:7, :);
    baseline = mean(last7DaysData.SelectedPixelDifference);
    
    if baseline == 0
        warning('Baseline for animal %s is zero. Skipping normalization to avoid division by zero.', currAnimal);
        continue;
    end
    
    % Normalize activity for the animal across all conditions
    isCurrentAnimalAllCond = strcmp(data.Animal, currAnimal);
    data.NormalizedActivity(isCurrentAnimalAllCond) = data.SelectedPixelDifference(isCurrentAnimalAllCond) / baseline;
end

% Save the modified table to a new CSV file
writetable(data, '/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyOnly/AOActivityData.csv');