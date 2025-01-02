% Load the CSV data into a table
filename = '/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyEphys/EphysCohort_Data.csv';
data = readtable(filename);

% Display the first few rows of the 'Date' column for debugging
disp('Original Date column:');
disp(data.Date(1:10));  % Display the first 10 entries as a sample

% Check if 'Date' column exists in the data
if any(strcmp(data.Properties.VariableNames, 'Date'))
    % Initialize a variable to store fixed dates
    fixedDates = strings(height(data), 1); 
    
    % Iterate over the rows of the Date column
    for i = 1:height(data)
        dateStr = char(data.Date(i));
        if length(dateStr) == 16
            if strcmp(dateStr(7:10), '0023')
                % Replace '0023' with '2023'
                fixedYearStr = [dateStr(1:6), '2023', dateStr(11:end)];
                fixedDates(i) = fixedYearStr;
            elseif strcmp(dateStr(7:10), '0024')
                % Replace '0024' with '2024'
                fixedYearStr = [dateStr(1:6), '2024', dateStr(11:end)];
                fixedDates(i) = fixedYearStr;
            elseif strcmp(dateStr(7:10), '0022')
                % Replace '0022' with '2022'
                fixedYearStr = [dateStr(1:6), '2022', dateStr(11:end)];
                fixedDates(i) = fixedYearStr;
            else
                fixedDates(i) = dateStr; % Keep the original date if no change is needed
            end
        else
            fixedDates(i) = dateStr; % Keep the original date if it doesn't match the length
        end
    end
    
    % Update the 'Date' column in the original data
    data.Date = fixedDates;

    % Display the first few rows of the 'Date' column after modification
    disp('Modified Date column:');
    disp(data.Date(1:10));  % Display the first 10 entries as a sample

    % Save the corrected table back to a new CSV file
    newFilename = '/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyEphys/EphysCohortData.csv'; % Specify a new filename
    writetable(data, newFilename);
    disp(['Corrected file saved as ', newFilename]);
else
    disp('Error: ''Date'' column not found in the CSV file.');
end