%% Circadian Analysis of Pooled Data
% using data pulled from /data/Jeremy on Scatha
%% Reading in data
% reading in data, already in ZT form 
convertZT = false;
combined_data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ZT/Combined_Normalized_Data_With_RelativeDays.csv');
%% Wrangling hourly bins
[hourlyMeans, hourlyBinTimes] = CalculateHourlyMeans(combined_data);

AnalyzeCircadianRunning(combined_data, false, 'All Rats');