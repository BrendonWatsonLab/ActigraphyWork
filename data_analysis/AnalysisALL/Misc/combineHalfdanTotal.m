% Define file paths
combinedFile = '/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyEphys/binned_data_ephys.csv';
newRatFile = '/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyEphys/Halfdan_binned_data.csv';

% Define the full output file path (e.g., 'C:\Users\YourUsername\Documents\combined_updated.csv')
outputFile = fullfile('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyEphys/ephys_data.csv');

% Read the combined data
combinedData = readtable(combinedFile);

% Read the new rat data
newRatData = readtable(newRatFile);

% Rename the column 'Animal' to 'Rat' in the new rat data
newRatData.Properties.VariableNames{'Animal'} = 'Rat';

% Rename the conditions in the new rat data
newRatData.Condition = strrep(newRatData.Condition, '1000Lux_week4', '1000Lux4');
newRatData.Condition = strrep(newRatData.Condition, '1000Lux_week1', '1000Lux1');

% Concatenate the data tables
updatedData = [combinedData; newRatData];

% Write the updated table back to a new CSV file
writetable(updatedData, outputFile);

disp(['Data combined successfully and saved to: ' outputFile]);