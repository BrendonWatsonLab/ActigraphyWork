sourceDirectory = '/data/Jeremy/Grass Rat Data/ActigraphyOnly_GR_Videos/Cohort2';
destinationDirectory = '/nfs/turbo/umms-brendonw/JeremyData/GrassRatActigraphyOnlyData/Cohort2DARKSleepDep';
animalNames = {'AO5', 'AO6', 'AO7', 'AO8'};

copySelectedMp4Files(sourceDirectory, destinationDirectory, animalNames);


%% Function
function copySelectedMp4Files(sourceDir, destDir, animalNames)
    % Ensure directories end with the file separator
    if sourceDir(end) ~= filesep
        sourceDir = [sourceDir, filesep];
    end
    if destDir(end) ~= filesep
        destDir = [destDir, filesep];
    end

    % Make destination directory if it does not exist
    if ~exist(destDir, 'dir')
        mkdir(destDir);
    end

    % Define the cut-off datetime
    cutoffDateTime = datetime('2024-09-06 18:00:00', 'InputFormat', 'yyyy-MM-dd HH:mm:ss');

    % Loop for each animal
    for k = 1:length(animalNames)
        animal = animalNames{k}; % Extract the actual string
        
        % Get the source directory for this animal
        animalSourceDir = fullfile(sourceDir, animal);
        
        % Get list of .mp4 files in the source directory for this animal
        files = dir(fullfile(animalSourceDir, '*.mp4'));

        % Create animal-specific subdirectory in the destination if not exists
        animalDestDir = fullfile(destDir, animal);
        if ~exist(animalDestDir, 'dir')
            mkdir(animalDestDir);
        end

        % Loop through each file and check if it matches the criteria
        for i = 1:length(files)
            fileName = files(i).name;
            % Extract the datetime part of the filename
            dateTimeStr = fileName(length(animal) + 2 : length(animal) + 20); % Adjust indexing

            try
                % Convert to datetime object
                fileDateTime = datetime(dateTimeStr, 'InputFormat', 'yyyyMMdd_HH-mm-ss.SSS');
                
                % Check if the datetime is on or after the cutoff
                if fileDateTime >= cutoffDateTime
                    % Copy the file to the destination directory
                    copyfile(fullfile(animalSourceDir, fileName), fullfile(animalDestDir, fileName));
                end
            catch
                % If there's an issue with the datetime conversion, skip the file
                warning('Skipping file: %s due to unexpected format', fileName);
                continue;
            end
        end
    end

    disp('File copying operation completed.');
end