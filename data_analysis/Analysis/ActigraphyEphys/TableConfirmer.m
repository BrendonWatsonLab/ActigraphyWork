%% Place the File HERE
filename = '/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyEphys/EphysCohortData.csv';

%% The Confirmer
% Read the CSV file into a table
dataTable = readtable(filename);

% Display the first few rows of the table to verify content
disp('First few rows of dataTable:');
disp(dataTable(1:10, :));

% Display unique animals and conditions to verify
disp('Unique animals and conditions:');
disp(unique(dataTable(:, {'Animal', 'Condition'})));

% Get unique combinations of 'Animal' and 'Condition'
uniqueCombinations = unique(dataTable(:, {'Animal', 'Condition'}));

% Initialize a table to hold start and end dates, and duration for each combination
startEndDates = table(cell(0, 1), cell(0, 1), datetime([], [], []), datetime([], [], []), duration([], [], []), ...
                      'VariableNames', {'Animal', 'Condition', 'StartDate', 'EndDate', 'Duration'});

% Loop through each unique combination of 'Animal' and 'Condition'
for i = 1:height(uniqueCombinations)
    % Extract current animal and condition
    currentAnimal = uniqueCombinations.Animal{i};
    currentCondition = uniqueCombinations.Condition{i};
    
    % Filter the rows matching current animal and condition
    currentRows = dataTable(strcmp(dataTable.Animal, currentAnimal) & strcmp(dataTable.Condition, currentCondition), :);
    
    % Get the start and end dates for the current group
    startDate = min(currentRows.Date);
    endDate = max(currentRows.Date);
    
    % Calculate the duration
    duration = endDate - startDate;
    
    % Append to the results table
    startEndDates = [startEndDates; {currentAnimal, currentCondition, startDate, endDate, duration}];
end

% Add a new column 'DurationInDays' to the results table with the duration in days
startEndDates.DurationInDays = days(startEndDates.Duration);

% Display the resulting table
disp('Resulting table:');
disp(startEndDates);