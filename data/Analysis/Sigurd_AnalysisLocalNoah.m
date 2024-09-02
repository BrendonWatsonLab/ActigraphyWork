% Sigurd 5/7 Day Video Analysis
% Noah Muscat
% data ran from /data/Jeremy/Sigurd using actigraphy_v5.py
%% 300 vs 1000 Lux (or sleepdep)
% Define datafile paths
datafile300 = 'Sigurd_240705_Videos_combined_data.csv';
datafile1000wk1 = 'Sigurd_240712_Videos_combined_data.csv';
datafile1000wk4 = 'Sigurd_240802_Videos_combined_data.csv';
datafilesleepdep = 'Sigurd_240809_Videos_combined_data.csv';

% Compare movements between the two lighting conditions and plot results
CompareLightingConditions(datafile300, datafile1000wk1, datafile1000wk4, true);
CompareSleepDep(datafile300, datafile1000wk4, datafilesleepdep, true);

%% Circadian Comparisons
datafile300 = 'Sigurd_240705_Videos_combined_data.csv';
datafile1000wk1 = 'Sigurd_240712_Videos_combined_data.csv';
datafile1000wk4 = 'Sigurd_240802_Videos_combined_data.csv';
datafilesleepdep = 'Sigurd_240809_Videos_combined_data.csv';

AnalyzeCircadianRunning(datafile300, true, 'Sigurd300Lux');
AnalyzeCircadianRunning(datafile1000wk1, true, 'Sigurd1000LuxWk1');
AnalyzeCircadianRunning(datafile1000wk4, true, 'Sigurd1000LuxWk4');
AnalyzeCircadianRunning(datafilesleepdep, true, 'SigurdSleepDep');

%% Sigurd 240705
make_ZT_bool = true;
Per_Day_Analysis('Sigurd_240705_Videos_combined_data.csv','300 Lux', 'Sigurd',make_ZT_bool)
data = readtable('Sigurd_240705_Videos_combined_data.csv');

% Set this to true to convert times in the datasets to Zeitgeber time
convert_ZT = true;

if convert_ZT
    data = make_ZT(data, 5);
end

% Creating an 'Hour' column that represents just the hour part of 'Date'
data.Hour = hour(data.Date);

% Now summarize 'SelectedPixelDifference' by the 'Hour' column across all entries in dataTable
hourlySum = groupsummary(data, 'Hour', 'sum', 'SelectedPixelDifference');

figure;

b1 = bar(hourlySum.Hour, hourlySum.sum_SelectedPixelDifference, 'BarWidth', 1);
addShadedAreaToPlotZT();
title('Sigurd 300 Lux');

uistack(b1, 'top'); 

%% Sigurd 240712
make_ZT_bool = true;
Per_Day_Analysis('Sigurd_240712_Videos_combined_data.csv','1000 Lux Week 1', 'Sigurd',make_ZT_bool)
data = readtable('Sigurd_240712_Videos_combined_data.csv');

% Set this to true to convert times in the datasets to Zeitgeber time
convert_ZT = true;

if convert_ZT
    data = make_ZT(data, 5);
end

% Creating an 'Hour' column that represents just the hour part of 'Date'
data.Hour = hour(data.Date);

% Now summarize 'SelectedPixelDifference' by the 'Hour' column across all entries in dataTable
hourlySum = groupsummary(data, 'Hour', 'sum', 'SelectedPixelDifference');

figure;
b1 = bar(hourlySum.Hour, hourlySum.sum_SelectedPixelDifference, 'BarWidth', 1);
addShadedAreaToPlotZT();
title('Sigurd 1000 Lux Week 1');

uistack(b1, 'top');  

%% Sigurd 240802
make_ZT_bool = true;
Per_Day_Analysis('Sigurd_240802_Videos_combined_data.csv','1000 Lux Week 4', 'Sigurd',make_ZT_bool)
data = readtable('Sigurd_240802_Videos_combined_data.csv');

% Set this to true to convert times in the datasets to Zeitgeber time
convert_ZT = true;

if convert_ZT
    data = make_ZT(data, 5);
end

% Creating an 'Hour' column that represents just the hour part of 'Date'
data.Hour = hour(data.Date);

% Now summarize 'SelectedPixelDifference' by the 'Hour' column across all entries in dataTable
hourlySum = groupsummary(data, 'Hour', 'sum', 'SelectedPixelDifference');

figure;
b1 = bar(hourlySum.Hour, hourlySum.sum_SelectedPixelDifference, 'BarWidth', 1);
addShadedAreaToPlotZT();
title('Sigurd 1000 Lux Week 4');

uistack(b1, 'top');  
%% Sigurd 240809
make_ZT_bool = true;
Per_Day_Analysis('Sigurd_240809_Videos_combined_data.csv','1000 Lux SleepDep', 'Sigurd',make_ZT_bool)
data = readtable('Sigurd_240809_Videos_combined_data.csv');

% Set this to true to convert times in the datasets to Zeitgeber time
convert_ZT = true;

if convert_ZT
    data = make_ZT(data, 5);
end

% Creating an 'Hour' column that represents just the hour part of 'Date'
data.Hour = hour(data.Date);

% Now summarize 'SelectedPixelDifference' by the 'Hour' column across all entries in dataTable
hourlySum = groupsummary(data, 'Hour', 'sum', 'SelectedPixelDifference');

figure;
b1 = bar(hourlySum.Hour, hourlySum.sum_SelectedPixelDifference, 'BarWidth', 1);
addShadedAreaToPlotZT();
title('Sigurd 1000 Lux SleepDep');

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