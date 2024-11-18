parentDir = '/mnt/BalrogData/Jeremy/Harald/Harald_240402_videos_sleepdep';
folder = 'Most';
CombineSortZT(parentDir, folder, 6, 5);

%% Combining
% Read the combined data
combinedData = readtable(combinedFile);

% Read the new Harald data
newHaraldData = readtable(newHaraldFile);

% Ensure 'Date' is converted to datetime if it’s not already
combinedData.Date = datetime(combinedData.Date, 'InputFormat', 'MM/dd/yy HH:mm');
newHaraldData.Date = datetime(newHaraldData.Date, 'InputFormat', 'MM/dd/yy HH:mm');

% Add the necessary columns to newHaraldData
newHaraldData.Rat = repmat({'Harald'}, height(newHaraldData), 1);
newHaraldData.Condition = repmat({'sleep_deprivation'}, height(newHaraldData), 1);

% Initialize the SelectedPixelDifference column if it's missing
if ~ismember('SelectedPixelDifference', newHaraldData.Properties.VariableNames)
    newHaraldData.SelectedPixelDifference = zeros(height(newHaraldData), 1); % Placeholder or calculate as needed
end

% Initialize the NormalizedActivity column if it's missing
if ~ismember('NormalizedActivity', newHaraldData.Properties.VariableNames)
    newHaraldData.NormalizedActivity = zeros(height(newHaraldData), 1); % Placeholder, will be calculated later
end

% Initialize the RelativeDay column if it's missing
if ~ismember('RelativeDay', newHaraldData.Properties.VariableNames)
    newHaraldData.RelativeDay = zeros(height(newHaraldData), 1); % Placeholder, will be calculated later
end

% Bin the new Harald data
binbyminute = 5;
isfile = false; % Since newHaraldData is already loaded, not a file path
binnedHaraldData = Binner(newHaraldData, binbyminute, isfile);

% Extract Harald's 7-day data for the 300Lux condition
harald300LuxData = combinedData(strcmp(combinedData.Rat, 'Harald') & strcmp(combinedData.Condition, '300Lux'), :);

% Calculate the mean and standard deviation for z-scoring
meanHarald300Lux = mean(harald300LuxData.SelectedPixelDifference);
stdHarald300Lux = std(harald300LuxData.SelectedPixelDifference);

% Normalize the binned Harald data using 300Lux mean and std for z-scoring
binnedHaraldData.NormalizedActivity = (binnedHaraldData.SelectedPixelDifference - meanHarald300Lux) / stdHarald300Lux;

% Add necessary columns to binnedHaraldData for consistency
binnedHaraldData.Rat = repmat({'Harald'}, height(binnedHaraldData), 1);
binnedHaraldData.Condition = repmat({'sleep_deprivation'}, height(binnedHaraldData), 1);

% Calculate the RelativeDay starting at 1
minDate = min(binnedHaraldData.Date);
binnedHaraldData.RelativeDay = days(binnedHaraldData.Date - minDate) + 1;

% Reorder the variables to match the combinedData table
binnedHaraldData = binnedHaraldData(:, {'SelectedPixelDifference', 'NormalizedActivity', 'Rat', 'Condition', 'Date', 'RelativeDay'});

% Concatenate the binnedHaraldData with the existing combinedData
updatedData = [combinedData; binnedHaraldData];

% Write the updated table back to a new CSV file
writetable(updatedData, outputFile);

disp(['Data combined successfully and saved to: ' outputFile]);