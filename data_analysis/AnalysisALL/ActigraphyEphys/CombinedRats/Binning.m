binned_data = Binner('/data/Jeremy/NoahJeremySharedFolder/Data_Files_Ephys_Rats/Combined_Normalized_Data_With_RelativeDays.csv', 5, true);

writetable(binned_data, 'binned_data_ephys.csv');
