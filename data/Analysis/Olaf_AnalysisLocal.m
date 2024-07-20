% Olaf 5/7 Day Video Analysis
% Noah Muscat
% data ran from /data/Jeremy/Olaf using actigraphy_v5.py
%% Combines all csv files for all folders under 'data'
% Set the parent directory where the 'data' folder is located.
parentDir = '/Volumes/data/Jeremy/Olaf';
folder_name = 'Olaf_240419_Videos';
% combines and sorts the csv files
Combine_Sort_csv(parentDir, folder_name);

%% Olaf240419
make_ZT_bool = true;
Per_Day_Analysis('Olaf_240419_Videos_Most_combined_data.csv','Most Movement', 'Olaf',make_ZT_bool)

% analysis for totals
Most_Mov = readtable('Olaf_240419_Videos_Most_combined_data.csv');
convert_ZT = true;
if convert_ZT
    Most_Mov = make_ZT(Most_Mov, 5);
end

Most_Mov.Hour = hour(Most_Mov.Date);
hourlySumMostMov = groupsummary(Most_Mov, 'Hour', 'sum', 'SelectedPixelDifference');

figure;
b1 = bar(hourlySumMostMov.Hour, hourlySumMostMov.sum_SelectedPixelDifference, 'BarWidth', 1);
addShadedAreaToPlotZT();
title('Most Movement');
uistack(b1, 'top'); 

%% Functions
% Function to add a shaded area to the current plot
function addShadedAreaToPlotZT()
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
    xtickangle(90);
    
    hold off;
end

% Restatement of make_ZT, weird error reasons idk... 
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