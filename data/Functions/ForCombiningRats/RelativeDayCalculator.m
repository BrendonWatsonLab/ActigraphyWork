function [combined_data] = RelativeDayCalculator(rootFolder)

% Load the combined CSV file
fprintf('Loading combined data file...\n');
combinedFile = fullfile(rootFolder, 'Combined_Normalized_Data.csv');
combined_data = readtable(combinedFile);

% Convert 'Date' to datetime format if it's not already
if ~isdatetime(combined_data.Date)
    fprintf('Converting Date column to datetime format...\n');
    combined_data.Date = datetime(combined_data.Date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSSSSS');
end

% Calculate the relative day for each animal and condition
fprintf('Calculating relative days for each animal and condition...\n');
combined_data.RelativeDay = zeros(height(combined_data), 1);

animals = unique(combined_data.Animal);
conditions = unique(combined_data.Condition);

for a = 1:length(animals)
    animal = animals{a};
    disp(['Analyzing animal: ', animal]); % Print the current animal being analyzed
    for c = 1:length(conditions)
        condition = conditions{c};
        disp(['  Analyzing condition: ', condition]); % Print the current condition being analyzed
        
        animalConditionData = combined_data(strcmp(combined_data.Animal, animal) & strcmp(combined_data.Condition, condition), :);
        
        if isempty(animalConditionData)
            disp('    No data available for this animal and condition. Skipping...'); % Inform about skipping
            continue; % Skip if there is no data for this animal and condition
        end
        
        % Find the earliest date for this animal and condition
        minDate = min(animalConditionData.Date);
        
        % Calculate relative days
        relativeDays = days(animalConditionData.Date - minDate) + 1;
        
        % Update the combined_data 'RelativeDay' column
        indices = strcmp(combined_data.Animal, animal) & strcmp(combined_data.Condition, condition);
        combined_data.RelativeDay(indices) = relativeDays;
        
        disp('    Completed relative day calculation for this condition.'); % Inform about the completion of this condition analysis
    end
end

% Save the modified data with RelativeDay to a new CSV file
outputModifiedFile = fullfile(rootFolder, 'Combined_Normalized_Data_With_RelativeDays.csv');
fprintf('Saving the modified data with RelativeDay to: %s\n', outputModifiedFile);
writetable(combined_data, outputModifiedFile);

end


