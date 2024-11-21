function [combined_data] = Normalizer(rootFolder, rats, conditions)

% Initialize a table to store the combined normalized data with predefined column names
combined_data = table('Size', [0, 5], ...
                      'VariableTypes', {'double', 'double', 'cell', 'cell', 'datetime'}, ...
                      'VariableNames', {'SelectedPixelDifference', 'NormalizedActivity', 'Rat', 'Condition', 'Date'});

for r = 1:length(rats)
    rat = rats{r};
    ratFolder = fullfile(rootFolder, rat);
    
    fprintf('Processing data for rat: %s\n', rat);
    
    % Initialize variables to store 300Lux data for this rat
    selectedPixelDiff_300Lux = [];
    
    % Load the 300Lux data first to compute mean and std
    file_300Lux = fullfile(ratFolder, [rat '_300Lux_ZT.csv']);
    if ~isfile(file_300Lux)
        fprintf('300Lux data file not found for rat: %s. Skipping this rat.\n', rat);
        continue;  % Skip this rat if the 300Lux file does not exist
    end
    fprintf('Loading 300Lux data from: %s\n', file_300Lux);
    ratData_300Lux = readtable(file_300Lux);
    selectedPixelDiff_300Lux = ratData_300Lux.SelectedPixelDifference;
    
    % Calculate mean and std for 300Lux condition
    mean_300Lux = mean(selectedPixelDiff_300Lux);
    std_300Lux = std(selectedPixelDiff_300Lux);
    fprintf('Calculated mean = %.2f, std = %.2f for 300Lux condition of rat: %s\n', mean_300Lux, std_300Lux, rat);
    
    % Now normalize and combine all conditions for this rat
    for c = 1:length(conditions)
        condition = conditions{c};
        file_condition = fullfile(ratFolder, [rat '_' condition '_ZT.csv']);
        
        if ~isfile(file_condition)
            fprintf('%s data file not found for rat: %s. Skipping this condition.\n', condition, rat);
            continue;  % Skip this condition if the file does not exist
        end
        
        fprintf('Loading %s data from: %s\n', condition, file_condition);
        ratData_condition = readtable(file_condition);
        
        % Normalize the SelectedPixelDifference column using the 300Lux mean and std
        ratData_condition.NormalizedActivity = (ratData_condition.SelectedPixelDifference - mean_300Lux) / std_300Lux;
        fprintf('Normalized %s data for rat: %s\n', condition, rat);
        
        % Add columns for rat name and condition
        ratData_condition.Rat = repmat({rat}, height(ratData_condition), 1);
        ratData_condition.Condition = repmat({condition}, height(ratData_condition), 1);
        
        % Ensure the table has correct columns before concatenation
        ratData_condition = ratData_condition(:, {'SelectedPixelDifference', 'NormalizedActivity', 'Rat', 'Condition', 'Date'});
        
        % Append to the combined data table
        combined_data = [combined_data; ratData_condition]; %#ok<AGROW>
    end
end

% Output the combined normalized data to a CSV file
outputFile = fullfile(rootFolder, 'Combined_Normalized_Data.csv');
writetable(combined_data, outputFile);
fprintf('Combined normalized data saved to: %s\n', outputFile);
end

