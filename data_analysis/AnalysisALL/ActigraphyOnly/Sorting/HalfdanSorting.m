% Load data from the CSV file
filename = '/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/HalfdanData/HalfdanData_combined_data.csv'; % Replace with your actual filename
data = readtable(filename);

% Convert the 'Date' column to datetime type
data.Date = datetime(data.Date, 'InputFormat', 'MM.dd.yy HH:mm:ss');

% Define the condition boundaries
date_300Lux_end = datetime('09.21.24 06:00:00', 'InputFormat', 'MM.dd.yy HH:mm:ss');
date_1000Lux_wk1_start = datetime('09.21.24 06:00:00', 'InputFormat', 'MM.dd.yy HH:mm:ss');
date_1000Lux_wk1_end = datetime('09.27.24 23:59:59', 'InputFormat', 'MM.dd.yy HH:mm:ss');
date_1000Lux_wk4_start = datetime('10.11.24 06:00:00', 'InputFormat', 'MM.dd.yy HH:mm:ss');
date_1000Lux_wk4_end = datetime('10.18.24 05:59:59', 'InputFormat', 'MM.dd.yy HH:mm:ss');
date_sleep_deprivation_start = datetime('10.18.24 22:00:00', 'InputFormat', 'MM.dd.yy HH:mm:ss');

% Filter data based on conditions
data_300Lux = data(data.Date < date_300Lux_end, :);
data_1000Lux_wk1 = data((data.Date >= date_1000Lux_wk1_start) & (data.Date <= date_1000Lux_wk1_end), :);
data_1000Lux_wk4 = data((data.Date >= date_1000Lux_wk4_start) & (data.Date <= date_1000Lux_wk4_end), :);
data_sleep_deprivation = data(data.Date >= date_sleep_deprivation_start, :);

% Output filtered data to new CSV files
writetable(data_300Lux, 'Halfdan_300Lux.csv');
writetable(data_1000Lux_wk1, 'Halfdan_1000Lux_week1.csv');
writetable(data_1000Lux_wk4, 'Halfdan_1000Lux_week4.csv');
writetable(data_sleep_deprivation, 'Halfdan_sleep_deprivation.csv');

disp('CSV files for each condition created successfully.');

%% Combining and Normalizing

animals = {'Halfdan'};
conditions = {'300Lux', '1000Lux_week1', '1000Lux_week4', 'sleep_deprivation'};

%% Relative day

Halfdan_combined = Normalize_Combine('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/HalfdanData', animals, conditions);

combined_data_reldays = RelativeDayCalculator('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/HalfdanData');

binned_data = Binner('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/HalfdanData/Combined_Normalized_Data_With_RelativeDays.csv', 5, true);

rowsToDelete = binned_data.RelativeDay > 40;

daysDeleting = binned_data(rowsToDelete, :);
disp(daysDeleting);
new_binned = binned_data(~rowsToDelete, :);

writetable(new_binned, 'binned_data.csv');
