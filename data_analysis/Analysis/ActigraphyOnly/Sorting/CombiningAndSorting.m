%% Combining and Sorting for Actigraphy-Only Animals

%% AO1-4
CombineSortZT('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/Cohort1Data','AO1_300Lux', 6, 5);
CombineSortZT('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/Cohort1Data','AO1_1000Lux', 6, 5);
CombineSortZT('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/Cohort1Data','AO2_300Lux', 6, 5);
CombineSortZT('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/Cohort1Data','AO2_1000Lux', 6, 5);
CombineSortZT('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/Cohort1Data','AO3_300Lux', 6, 5);
CombineSortZT('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/Cohort1Data','AO3_1000Lux', 6, 5);
CombineSortZT('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/Cohort1Data','AO4_300Lux', 6, 5);
CombineSortZT('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/Cohort1Data','AO4_1000Lux', 6, 5);

%% AO5-8
TwoConditionCombiner('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/Cohort2Data','AO5', 6, 5);
TwoConditionCombiner('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/Cohort2Data','AO6', 6, 5);
TwoConditionCombiner('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/Cohort2Data','AO7', 6, 5);
TwoConditionCombiner('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/Cohort2Data','AO8', 6, 5);

%% AO5-8 DARK
CombineSortZT('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/Cohort2DARKdata', 'AO5', 6, 5);
CombineSortZT('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/Cohort2DARKdata', 'AO6', 6, 5);
CombineSortZT('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/Cohort2DARKdata', 'AO7', 6, 5);
CombineSortZT('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/Cohort2DARKdata', 'AO8', 6, 5);

% Halfdan
CombineSortZT('/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData', 'HalfdanData', 6, 5);