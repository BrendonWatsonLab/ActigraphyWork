function [combined_data] = Normalize_Combine(rootFolder, animals, conditions)

% Initialize a table to store the combined normalized data with predefined column names
combined_data = table('Size', [0, 5], ...
                      'VariableTypes', {'double', 'double', 'cell', 'cell', 'datetime'}, ...
                      'VariableNames', {'SelectedPixelDifference', 'NormalizedActivity', 'Animal', 'Condition', 'Date'});

for a = 1:length(animals)
    animal = animals{a};
    animalFile_300Lux = fullfile(rootFolder, [animal '_300Lux_combined_data.csv']);
    
    fprintf('Processing data for animal: %s\n', animal);
    
    % Load the 300Lux data to compute mean and std for the first 7 days
    if ~isfile(animalFile_300Lux)
        fprintf('300Lux data file not found for animal: %s. Skipping this animal.\n', animal);
        continue;  % Skip this animal if the 300Lux file does not exist
    end
    fprintf('Loading 300Lux data from: %s\n', animalFile_300Lux);
    animalData_300Lux = readtable(animalFile_300Lux);
    
    % Extract the first 7 days of data
    startDate = min(animalData_300Lux.Date);
    endDate = startDate + days(7);
    first7DaysData = animalData_300Lux(animalData_300Lux.Date >= startDate & animalData_300Lux.Date < endDate, :);
    
    % Calculate mean and std for the first 7 days of the 300Lux condition
    mean_300Lux = mean(first7DaysData.SelectedPixelDifference);
    std_300Lux = std(first7DaysData.SelectedPixelDifference);
    fprintf('Calculated mean = %.2f, std = %.2f for the first 7 days of 300Lux condition for animal: %s\n', mean_300Lux, std_300Lux, animal);
    
    % Now normalize and combine all conditions for this animal
    for c = 1:length(conditions)
        condition = conditions{c};
        conditionFile = fullfile(rootFolder, [animal '_' condition '_combined_data.csv']);
        
        if ~isfile(conditionFile)
            fprintf('%s data file not found for animal: %s. Skipping this condition.\n', condition, animal);
            continue;  % Skip this condition if the file does not exist
        end
        
        fprintf('Loading %s data from: %s\n', condition, conditionFile);
        animalData_condition = readtable(conditionFile);
        
        % Normalize the SelectedPixelDifference column using the mean and std of the first 7 days of 300Lux
        animalData_condition.NormalizedActivity = (animalData_condition.SelectedPixelDifference - mean_300Lux) / std_300Lux;
        fprintf('Normalized %s data for animal: %s\n', condition, animal);
        
        % Add columns for animal name and condition
        animalData_condition.Animal = repmat({animal}, height(animalData_condition), 1);
        animalData_condition.Condition = repmat({condition}, height(animalData_condition), 1);
        
        % Ensure the table has correct columns before concatenation
        animalData_condition = animalData_condition(:, {'SelectedPixelDifference', 'NormalizedActivity', 'Animal', 'Condition', 'Date'});
        
        % Append to the combined data table
        combined_data = [combined_data; animalData_condition]; %#ok<AGROW>
    end
end

% Output the combined normalized data to a CSV file
outputFile = fullfile(rootFolder, 'Combined_Normalized_Data.csv');
writetable(combined_data, outputFile);
fprintf('Combined normalized data saved to: %s\n', outputFile);
end

