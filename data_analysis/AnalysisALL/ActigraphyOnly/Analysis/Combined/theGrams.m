% Load and preprocess the data
data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyOnly/AOActivityData.csv');

% Convert DateZT to datetime format for easy handling
data.DateZT = datetime(data.DateZT, 'InputFormat', 'M/dd/yy HH:mm');

% Group the data into 5-minute bins based on DateZT
data.GroupedDateZT = datenum(data.DateZT - minutes(mod(minute(data.DateZT), 5)));

% Calculate the average NormalizedActivity per bin and animal
binnedData = groupsummary(data, {'Animal', 'Condition', 'GroupedDateZT'}, 'mean', 'NormalizedActivity');

% Define gender groups
maleAnimals = {'AO1', 'AO2', 'AO3', 'AO7'};
femaleAnimals = {'AO4', 'AO5', 'AO6', 'AO8'};

% Add gender information to the data
binnedData.Gender = repmat("", height(binnedData), 1);
binnedData.Gender(ismember(binnedData.Animal, maleAnimals)) = "Male";
binnedData.Gender(ismember(binnedData.Animal, femaleAnimals)) = "Female";

% Sort the values to ensure proper plotting
binnedData = sortrows(binnedData, {'Gender', 'Condition', 'GroupedDateZT'});

% Unique genders and conditions
uniqueGenders = unique(binnedData.Gender);
uniqueConditions = unique(binnedData.Condition);

figure;
for i = 1:length(uniqueGenders)
    for j = 1:length(uniqueConditions)
        subplot(length(uniqueGenders), length(uniqueConditions), (i-1)*length(uniqueConditions) + j);

        % Filter data for the current gender and condition
        currGenderData = binnedData(strcmp(binnedData.Gender, uniqueGenders{i}) & strcmp(binnedData.Condition, uniqueConditions{j}), :);

        % Calculate the mean activity per time-bin for this group
        pooledActivity = groupsummary(currGenderData, 'GroupedDateZT', 'mean', 'mean_NormalizedActivity');

        if ~isempty(pooledActivity)
            % Regular spacing needed, fill missing data with zeros
            currActivity = pooledActivity.mean_mean_NormalizedActivity;
            currTimes = pooledActivity.GroupedDateZT;
            allTimes = (min(currTimes):1/(24*12):max(currTimes)).';
            structTimes = datetime(allTimes, 'ConvertFrom', 'datenum');

            % Use interp1 to fill in missing data
            interpActivity = interp1(currTimes, currActivity, allTimes, 'nearest', 'extrap');

            % Compute the FFT
            Y = fft(interpActivity);

            % Compute the power spectrum
            P2 = abs(Y/length(Y));
            P1 = P2(1:floor(length(Y)/2+1));
            P1(2:end-1) = 2*P1(2:end-1);

            % Frequency axis: Convert to cycles per day
            Fs = 12; % Sampling rate (e.g., 12 samples per hour for 5-minute bins)
            f = (Fs*(0:(length(Y)/2))/length(Y)) * 24; % Convert cycles/hour to cycles/day

            % Plot the periodogram
            plot(f, P1);
            xlim([0 144]); % Adjust to show 0 to 6 cycles/day
        end

        title([uniqueGenders{i}, ' - ', uniqueConditions{j}]);
        xlabel('Frequency (cycles/day)');
        ylabel('Power');
    end
end