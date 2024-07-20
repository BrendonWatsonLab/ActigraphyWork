% Rollo 5-Day Video Analysis
% Noah Muscat
% data ran from /data/Jeremy/Rollo using actigraphy_v4.py

%% Combines all csv files for all folders under 'data'
% Set the parent directory where the 'data' folder is located.
parentDir = '/Users/noahmuscat/Desktop/Actigraphy Stuff/data';
folder_name = 'Rollo220131';
% combines and sorts the csv files
Combine_Sort_csv(parentDir, folder_name);
%% Per Day Analysis
make_ZT_bool = true;
Per_Day_Analysis('Most_Movement_Data_combined_data.csv','Most Movement', 'Rollo',make_ZT_bool)
Per_Day_Analysis('Medium_Movement_Data_combined_data.csv','Medium Movement', 'Rollo',make_ZT_bool)
Per_Day_Analysis('Only_Large_Movement_Data_combined_data.csv','Only Large Movement', 'Rollo',make_ZT_bool)

%% Total Hourly Analysis
Most_Mov = readtable('Most_Movement_Data_combined_data.csv');
Med_Mov = readtable('Medium_Movement_Data_combined_data.csv');
Only_Large_Mov = readtable('Only_Large_Movement_Data_combined_data.csv');

% Set this to true to convert times in the datasets to Zeitgeber time
convert_ZT = true;

if convert_ZT
    Most_Mov = make_ZT(Most_Mov, 5);
    Med_Mov = make_ZT(Med_Mov, 5);
    Only_Large_Mov = make_ZT(Only_Large_Mov, 5);
end

% Creating an 'Hour' column that represents just the hour part of 'Date'
Most_Mov.Hour = hour(Most_Mov.Date);
Med_Mov.Hour = hour(Med_Mov.Date);
Only_Large_Mov.Hour = hour(Only_Large_Mov.Date);

% Now summarize 'SelectedPixelDifference' by the 'Hour' column across all entries in dataTable
hourlySumMostMov = groupsummary(Most_Mov, 'Hour', 'sum', 'SelectedPixelDifference');
hourlySumMedMov = groupsummary(Med_Mov, 'Hour', 'sum', 'SelectedPixelDifference');
hourlySumOnlyLargeMov = groupsummary(Only_Large_Mov, 'Hour', 'sum', 'SelectedPixelDifference');

figure;

% Most Movement
subplot(3,1,1);
b1 = bar(hourlySumMostMov.Hour, hourlySumMostMov.sum_SelectedPixelDifference, 'BarWidth', 1);
addShadedAreaToPlot();
title('Most Movement');

% Medium Movement
subplot(3,1,2);
b2 = bar(hourlySumMedMov.Hour, hourlySumMedMov.sum_SelectedPixelDifference, 'BarWidth', 1);
addShadedAreaToPlot();
title('Medium Movement');

% Only Large Movement
subplot(3,1,3);
b3 = bar(hourlySumOnlyLargeMov.Hour, hourlySumOnlyLargeMov.sum_SelectedPixelDifference, 'BarWidth', 1);
addShadedAreaToPlot();
title('Only Large Movement');

uistack(b1, 'top'); 
uistack(b2, 'top'); 
uistack(b3, 'top'); 

% Function to add a shaded area to the current plot
function addShadedAreaToPlot()
    hold on;
    % Define x and y coordinates for the shaded area (from t=12 to t=24)
    x_shaded = [12, 24, 24, 12];
    y_lim = ylim;
    y_shaded = [y_lim(1), y_lim(1), y_lim(2), y_lim(2)];
    
    fill_color = [0.7, 0.7, 0.7]; % Light gray color for the shading
    fill(x_shaded, y_shaded, fill_color, 'EdgeColor', 'none');
    
    % Additional Plot settings
    xlabel('Hour of Day (ZT Time)');
    ylabel('Sum of PixelDifference');
    xlim([-0.5, 23.5]);
    xticks(0:23);
    xtickangle(0);
    
    hold off;
end

function [dataset] = make_ZT(dataset, lights_on_hour)
    % This function assumes that the dataset has a datetime column named 'Date'
    % Adjust the 'Date' column in the dataset to zeitgeber time with the given lights on hour.

    % Check if the 'Date' column exists in the dataset
    if ~any(strcmp('Date', dataset.Properties.VariableNames))
        error('The dataset does not contain a ''Date'' column.');
    end

    % Determine the "lights on" time (e.g., 5 AM as ZT0)
    lightsOn = hours(lights_on_hour);

    % Extract the 'Date' column from the dataset
    datetimeCol = dataset.Date;

    % Subtract 'lights on' time from each datetime entry to get Zeitgeber time
    zt_datetimes = datetimeCol - lightsOn;

    % Wrap negative times to the previous day (e.g., if before ZT0, then it is ZT>0 of the previous day)
    isBeforeLightsOn = hours(timeofday(zt_datetimes)) < 0;
    zt_datetimes(isBeforeLightsOn) = zt_datetimes(isBeforeLightsOn) + hours(24);

    % Update the 'Date' column in the dataset with adjusted Zeitgeber time
    dataset.Date = zt_datetimes;
end