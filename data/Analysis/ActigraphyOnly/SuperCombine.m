%% Combining all rat data into one file

rootFolder = '/home/noahmu/Documents/JeremyData/ActigraphyOnly';

animals = {'AO1', 'AO2', 'AO3', 'AO4', 'AO5', 'AO6', 'AO7', 'AO8'};

conditions = {'300Lux', '1000Lux'};

combined_data_total = Normalize_Combine(rootFolder, animals, conditions);