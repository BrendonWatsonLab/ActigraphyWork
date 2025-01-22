%% Redoing normalization
% this script is used to redo normalization of the animal activity based on
% the last 4 days of 300Lux condition per animal

%% For actigraphyEphys
% Read the CSV file as a table
data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyEphys/EphysCohortData.csv', 'PreserveVariableNames', true);

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
% Read the CSV file as a table
data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyOnly/AOCohortData.csv', 'PreserveVariableNames', true);

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
writetable(data, '/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyOnly/AOActivityData.csv');