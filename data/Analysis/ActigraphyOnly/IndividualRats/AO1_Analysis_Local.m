% AO1 Video Analysis
% Noah Muscat
% data ran from Scatha /data/Jeremy/Grass Rat Data/ActigraphyOnly_GR_Videos/Cohort1/ using actigraphy_v5.py

%% Combines all csv files for all folders under 'data'
% Set the parent directory where the 'data' folder is located.
parentDir = '/data/Jeremy/NoahJeremySharedFolder/ActigraphyData/Cohort1';

Lux300 = 'AO1_300Lux';
Lux1000 = 'AO1_1000Lux';

% combines and sorts the csv files
CombineSortScatha(parentDir, Lux1000);

%% Ensures ZT time
Lux300Data = readtable('/data/Jeremy/NoahJeremySharedFolder/ActigraphyData/Cohort1/AO1_300Lux/AO1_300Lux_combined_data.csv');
Lux1000Data = readtable('/data/Jeremy/NoahJeremySharedFolder/ActigraphyData/Cohort1/AO1_1000Lux/AO1_1000Lux_combined_data.csv');
Lux300DataZT = make_ZT(Lux300Data, 5);
Lux1000DataZT = make_ZT(Lux1000Data, 5);

outputpath300 = '/home/noahmu/Documents/JeremyData/ActigraphyOnly/ZTData/AO1_300Lux_ZT_data.csv';
outputpath1000 = '/home/noahmu/Documents/JeremyData/ActigraphyOnly/ZTData/AO1_1000Lux_ZT_data.csv';
writetable(Lux300DataZT, outputpath300);
writetable(Lux1000DataZT, outputpath1000);

%% Read in data tables
data300Lux = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/AO1_300Lux_ZT_data.csv');
data1000Lux = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ActigraphyOnly/AO1_1000Lux_ZT_data.csv');

%% Circadian Analysis
AnalyzeCircadianRunning(data300Lux, true, 'AO1 - 300 Lux');
AnalyzeCircadianRunning(data1000Lux, true, 'AO1 - 1000 Lux');

%% Compare Lighting Conditions
CompareLightingConditions(data300Lux, data1000Lux, true);




