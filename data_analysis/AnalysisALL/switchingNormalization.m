% Helper function to compute Z-score
function z_scores = compute_z_scores(data, mean_value, std_value)
    z_scores = (data - mean_value) / std_value;
end

%% For ActigraphyEphys
% Read the CSV file as a table
dataEphys = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyEphys/EphysActivityData.csv', 'PreserveVariableNames', true);

% Convert DateZT to a datetime format
dataEphys.DateZT = datetime(dataEphys.DateZT, 'InputFormat', 'MM/dd/yy HH:mm');

% Extract unique animals
animals = unique(dataEphys.Animal);

% Loop over each animal to calculate the baseline using the last 4 unique days
for i = 1:length(animals)
    % Select current animal
    currAnimal = animals{i};
    
    % Filter data for the current animal and 300Lux condition
    isCurrentAnimal = strcmp(dataEphys.Animal, currAnimal);
    is300LuxCondition = strcmp(dataEphys.Condition, '300Lux');
    currentEntries = isCurrentAnimal & is300LuxCondition;
    
    % Select data for these entries and sort by DateZT
    selectedData = dataEphys(currentEntries, :);
    
    % Extract unique dates
    uniqueDates = unique(dateshift(selectedData.DateZT, 'start', 'day'), 'sorted');
    
    % Check if there are at least 4 unique dates
    if length(uniqueDates) < 4
        warning('Insufficient unique days for animal %s in 300Lux condition. Skipping normalization.', currAnimal);
        continue;
    end
    
    % Get data for the last 4 unique days
    last4Dates = uniqueDates(end-3:end);
    last4DaysData = selectedData(ismember(dateshift(selectedData.DateZT, 'start', 'day'), last4Dates), :);
    
    % Calculate mean and standard deviation
    meanValue = mean(last4DaysData.SelectedPixelDifference);
    stdValue = std(last4DaysData.SelectedPixelDifference);
    
    % Apply Z-scoring normalization
    allCondIdx = isCurrentAnimal;
    dataEphys.NormalizedActivity(allCondIdx) = compute_z_scores(dataEphys.SelectedPixelDifference(allCondIdx), meanValue, stdValue);
end

% Save the modified table to a new CSV file
writetable(dataEphys, '/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyEphys/EphysActivityData.csv');

%% For ActigraphyOnly
% Read the CSV file as a table
dataAO = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyOnly/AOActivityData.csv', 'PreserveVariableNames', true);

% Convert DateZT to a datetime format
dataAO.DateZT = datetime(dataAO.DateZT, 'InputFormat', 'MM/dd/yy HH:mm');

% Extract unique animals
animals = unique(dataAO.Animal);

% Loop over each animal to calculate the baseline using the last 7 unique days
for i = 1:length(animals)
    % Select current animal
    currAnimal = animals{i};
    
    % Filter data for the current animal and 300Lux condition
    isCurrentAnimal = strcmp(dataAO.Animal, currAnimal);
    is300LuxCondition = strcmp(dataAO.Condition, '300Lux');
    currentEntries = isCurrentAnimal & is300LuxCondition;
    
    % Select data for these entries and sort by DateZT
    selectedData = dataAO(currentEntries, :);
    
    % Extract unique dates
    uniqueDates = unique(dateshift(selectedData.DateZT, 'start', 'day'), 'sorted');
    
    % Check if there are at least 7 unique dates
    if length(uniqueDates) < 7
        warning('Insufficient unique days for animal %s in 300Lux condition. Skipping normalization.', currAnimal);
        continue;
    end
    
    % Get data for the last 7 unique days
    last7Dates = uniqueDates(end-6:end);
    last7DaysData = selectedData(ismember(dateshift(selectedData.DateZT, 'start', 'day'), last7Dates), :);
    
    % Calculate mean and standard deviation
    meanValue = mean(last7DaysData.SelectedPixelDifference);
    stdValue = std(last7DaysData.SelectedPixelDifference);
    
    % Apply Z-scoring normalization
    allCondIdx = isCurrentAnimal;
    dataAO.NormalizedActivity(allCondIdx) = compute_z_scores(dataAO.SelectedPixelDifference(allCondIdx), meanValue, stdValue);
end

% Save the modified table to a new CSV file
writetable(dataAO, '/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyOnly/AOActivityData.csv');