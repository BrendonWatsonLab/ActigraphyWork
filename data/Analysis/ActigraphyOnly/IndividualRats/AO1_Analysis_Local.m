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