% Load the data
data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyEphys/EphysActivityData.csv');

% Create hourly bins and calculate the mean of NormalizedActivity for each hour
data.HourlyBins = dateshift(data.DateZT, 'start', 'hour');
hourlySumTable = groupsummary(data, 'HourlyBins', 'mean', 'NormalizedActivity');
hourlyMeans = hourlySumTable.mean_NormalizedActivity;
hourlyBinTimes = hourlySumTable.HourlyBins;

% Extract ZT time from hourly bins
ZT_Time = mod(hour(hourlyBinTimes), 24);

% Define ZT ranges
range3_9 = (ZT_Time >= 3 & ZT_Time <= 9);
range15_21 = (ZT_Time >= 15 & ZT_Time <= 21);
range10_14 = (ZT_Time >= 10 & ZT_Time <= 14);
range22_2 = (ZT_Time >= 22 | ZT_Time <= 2);
other = ~(range3_9 | range15_21 | range10_14 | range22_2);

% Create grouping variables for violin plot
rangeGroup1 = strings(height(hourlySumTable), 1);
rangeGroup1(range3_9) = "ZT 3-9";
rangeGroup1(range15_21) = "ZT 15-21";

rangeGroup2 = strings(height(hourlySumTable), 1);
rangeGroup2(range10_14) = "ZT 10-14";
rangeGroup2(range22_2) = "ZT 22-2";
rangeGroup2(other) = "Other";

% Convert rangeGroups to categorical variables
rangeGroup1 = categorical(rangeGroup1);
rangeGroup2 = categorical(rangeGroup2);

% Create figure with subplots
figure;

% First subplot: Compare between ZT 3-9 vs 15-21
subplot(1, 2, 1);
violinplot(rangeGroup1(range3_9 | range15_21), hourlyMeans(range3_9 | range15_21));
xlabel('ZT Range');
ylabel('Mean Normalized Activity');
title('ZT 3-9 vs 15-21');

% Second subplot: Compare ZT 10-14 vs 22-2 vs Other
subplot(1, 2, 2);
violinplot(rangeGroup2(range10_14 | range22_2 | other), hourlyMeans(range10_14 | range22_2 | other));
xlabel('ZT Range');
ylabel('Mean Normalized Activity');
title('ZT 10-14 vs 22-2 vs Other');