% Rollo 5-Day Video Analysis
% Noah Muscat
% data ran from /data/Jeremy/Rollo using actigraphy_v4.py

%% Combines all csv files for all folders under 'data'
% Set the parent directory where the 'data' folder is located.
parentDir = '/Users/noahmuscat/Desktop/Actigraphy Stuff';
folder_name = 'data';
% combines and sorts the csv files
Combine_Sort_csv(parentDir, folder_name);
%% Per Day Analysis
Per_Day_Analysis('Most_Movement_Data_combined_data.csv','Most Movement', 'Rollo')
Per_Day_Analysis('Medium_Movement_Data_combined_data.csv','Medium Movement', 'Rollo')
Per_Day_Analysis('Only_Large_Movement_Data_combined_data.csv','Medium Movement', 'Rollo')

%% Total Hourly Analysis
Most_Mov = readtable('Most_Movement_Data_combined_data.csv');
Med_Mov = readtable('Medium_Movement_Data_combined_data.csv');
Only_Large_Mov = readtable('Only_Large_Movement_Data_combined_data.csv');

% Creating an 'Hour' column that represents just the hour part of 'Date'
Most_Mov.Hour = hour(Most_Mov.Date);
Med_Mov.Hour = hour(Med_Mov.Date);
Only_Large_Mov.Hour = hour(Only_Large_Mov.Date);

% Now summarize 'SelectedPixelDifference' by the 'Hour' column across all entries in dataTable
hourlySumMostMov = groupsummary(Most_Mov, 'Hour', 'sum', 'SelectedPixelDifference');
hourlySumMedMov = groupsummary(Med_Mov, 'Hour', 'sum', 'SelectedPixelDifference');
hourlySumOnlyLargeMov = groupsummary(Only_Large_Mov, 'Hour', 'sum', 'SelectedPixelDifference');

figure;

% Most movement
subplot(3,1,1);
bar(hourlySumMostMov.Hour, hourlySumMostMov.sum_SelectedPixelDifference, 'BarWidth', 1);

title('Most Movement');
xlabel('Hour of Day');
ylabel('Sum of Selected Pixel Difference');

xlim([-0.5, 23.5]);
xticks(0:23);
xtickangle(0);

% Medium movement
subplot(3,1,2);
bar(hourlySumMedMov.Hour, hourlySumMedMov.sum_SelectedPixelDifference, 'BarWidth', 1);

title('Medium Movement');
xlabel('Hour of Day');
ylabel('Sum of Selected Pixel Difference');

xlim([-0.5, 23.5]);
xticks(0:23);
xtickangle(0);

% Only large movement
subplot(3,1,3);
bar(hourlySumOnlyLargeMov.Hour, hourlySumOnlyLargeMov.sum_SelectedPixelDifference, 'BarWidth', 1);

title('Only Large Movement');
xlabel('Hour of Day');
ylabel('Sum of Selected Pixel Difference');

xlim([-0.5, 23.5]);
xticks(0:23);
xtickangle(0);

sgtitle('Total Hourly Sums - Rollo')