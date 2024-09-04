%% for all files in folder
% Define the main folder where the subfolders are located
mainFolder = '/home/noahmu/Documents/JeremyData/NotZT';

% Define the output folder where you want to save the new tables
outputFolder = '/home/noahmu/Documents/JeremyData/ZT';

% Create the output folder if it doesn't exist
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Get a list of all subfolders
ratFolders = dir(mainFolder);
% Loop through each item in the main folder
for i = 1:length(ratFolders)
    % Check if the item is a folder and not the current or parent directory (., ..)
    if ratFolders(i).isdir && ~ismember(ratFolders(i).name, {'.', '..'})
        % Get the full path of the subfolder
        ratFolderPath = fullfile(mainFolder, ratFolders(i).name);
        
        % Create the corresponding output subfolder
        outputSubFolderPath = fullfile(outputFolder, ratFolders(i).name);
        if ~exist(outputSubFolderPath, 'dir')
            mkdir(outputSubFolderPath);
        end
        
        % Get a list of all .csv files in this subfolder
        csvFiles = dir(fullfile(ratFolderPath, '*.csv'));
        
        % Loop through and process each .csv file in the subfolder
        for j = 1:length(csvFiles)
            % Get the full path of the .csv file
            csvFilePath = fullfile(csvFiles(j).folder, csvFiles(j).name);
         
            data = readtable(csvFilePath);

            % Call your function with the .csv file path
            resultTable = make_ZT(data,5);
            
            % Define the output file path
            [~, fileName, ~] = fileparts(csvFiles(j).name);
            outputFilePath = fullfile(outputSubFolderPath, [fileName, '_ZT.csv']);
            
            % Save the resulting table to the new location
            writetable(resultTable, outputFilePath);
        end
    end
end

%% for one file
csvFilePath = '/home/noahmu/Documents/JeremyData/NotZT/combined_normalized_data.csv';
data = readtable(csvFilePath);
resultTable = make_ZT(data,5);
outputpath = '/home/noahmu/Documents/JeremyData/ZT';
writetable(resultTable, outputpath);
