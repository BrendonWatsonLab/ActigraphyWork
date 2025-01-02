%% Combining all rat data into one file

rootFolder = '/data/Jeremy/NoahJeremySharedFolder/Data_Files_Actig_Only';

animals = {'AO1', 'AO2', 'AO3', 'AO4', 'AO5', 'AO6', 'AO7', 'AO8'};

conditions = {'300Lux', '1000Lux'};

combined_data_total = Normalize_Combine(rootFolder, animals, conditions);

%% Adding relative days
combined_data_reldays = RelativeDayCalculator('/data/Jeremy/NoahJeremySharedFolder/Data_Files_Actig_Only');

%% Binning data

binned_data = Binner('/data/Jeremy/NoahJeremySharedFolder/Data_Files_Actig_Only/Combined_Normalized_Data_With_RelativeDays.csv', 5, true);

%% Cleaning data

rowsToDelete = binned_data.RelativeDay > 40;

daysDeleting = binned_data(rowsToDelete, :);
disp(daysDeleting);
new_binned = binned_data(~rowsToDelete, :);

writetable(new_binned, 'binned_data.csv');


