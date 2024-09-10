function [combined_data] = RelativeDayCalculator(rootFolder)

% Load the combined CSV file
fprintf('Loading combined data file...\n');
combinedFile = fullfile(rootFolder, 'Combined_Normalized_Data.csv');
combined_data = readtable(combinedFile);

% Convert 'Date' to datetime format if it's not already
if ~isdatetime(combined_data.Date)
    fprintf('Converting Date column to datetime format...\n');
    combined_data.Date = datetime(combined_data.Date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SS');
end

% Calculate the relative day for each rat and condition
fprintf('Calculating relative days for each rat and condition...\n');
combined_data.RelativeDay = zeros(height(combined_data), 1);

rats = unique(combined_data.Rat);
conditions = unique(combined_data.Condition);

for r = 1:length(rats)
    rat = rats{r};
    disp(['Analyzing rat: ', rat]); % Print the current rat being analyzed
    for c = 1:length(conditions)
        condition = conditions{c};
        disp(['  Analyzing condition: ', condition]); % Print the current condition being analyzed
        
        ratConditionData = combined_data(strcmp(combined_data.Rat, rat) & strcmp(combined_data.Condition, condition), :);
        
        if isempty(ratConditionData)
            disp('    No data available for this rat and condition. Skipping...'); % Inform about skipping
            continue; % Skip if there is no data for this rat and condition
        end
        
        % Find the earliest date for this rat and condition
        minDate = min(ratConditionData.Date);
        
        % Calculate relative days
        relativeDays = days(ratConditionData.Date - minDate) + 1;
        
        % Update the combined_data 'RelativeDay' column
        indices = strcmp(combined_data.Rat, rat) & strcmp(combined_data.Condition, condition);
        combined_data.RelativeDay(indices) = relativeDays;
        
        disp('    Completed relative day calculation for this condition.'); % Inform about the completion of this condition analysis
    end
end

% Save the modified data with RelativeDay to a new CSV file
outputModifiedFile = fullfile(rootFolder, 'Combined_Normalized_Data_With_RelativeDays.csv');
fprintf('Saving the modified data with RelativeDay to: %s\n', outputModifiedFile);
writetable(combined_data, outputModifiedFile);

end

