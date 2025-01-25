% Load data
data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyEphys/EphysActivityData.csv');
save_directory = '/Users/noahmuscat/Desktop';

% Ensure 'RelativeDay' is numeric and integer
if ~isnumeric(data.RelativeDay)
    data.RelativeDay = str2double(string(data.RelativeDay));
end
data.RelativeDay = floor(data.RelativeDay);

conditionOrder = {'300Lux', '1000Lux1', '1000Lux4', 'sleep_deprivation'};
validConditionOrderEphys = {'300Lux', '1000Lux1', '1000Lux4', 'sleepDeprivation'};

% Convert 'Condition' and 'Animal' into categorical variables
data.Condition = categorical(data.Condition, conditionOrderEphys, 'Ordinal', true);
data.Animal = categorical(data.Animal);

% Convert 'RelativeDay' to categorical
data.RelativeDay = categorical(data.RelativeDay);

function fftAnalysisEphysWithSubplots(data, conditionOrder, save_directory, validConditionOrderEphys)
    % Convert DateZT to datetime if not already
    if ~isdatetime(data.DateZT)
        data.DateZT = datetime(data.DateZT);
    end

    % Ensure all needed conditions are present in categories
    if ~all(ismember(conditionOrder, categories(data.Condition)))
        data.Condition = addcats(data.Condition, conditionOrder);
    end

    % Analyze for the given set of conditions
    for condIdx = 1:length(conditionOrder)
        condition = conditionOrder{condIdx};
        validCondition = validConditionOrderEphys{condIdx};

        % Select data for this condition
        selectedData = data(data.Condition == condition, :);

        % Prepare figure for subplots
        figure;

        % === 5-Minute Bins Analysis (Cycles per Hour) ===
        % Create a new column for 5-minute bin identification
        selectedData.FiveMinBin = selectedData.DateZT.Hour * 12 + floor(selectedData.DateZT.Minute / 5) + 1;

        % Calculate mean NormalizedActivity for each 5-minute bin
        binMeans5min = varfun(@mean, selectedData, 'InputVariables', 'NormalizedActivity', ...
                              'GroupingVariables', 'FiveMinBin');
        
        % Remove any NaNs or incomplete bins entries
        binMeans5min = rmmissing(binMeans5min);

        % Apply FFT to 5-minute bins
        N5 = length(binMeans5min.mean_NormalizedActivity);
        fftVals5 = fft(binMeans5min.mean_NormalizedActivity);
        f5 = (0:N5-1)*(12/N5); % Frequency for cycles per hour
        power5 = abs(fftVals5).^2/N5;

        % Subplot 1: 5-minute bin results
        subplot(2, 1, 1); % 2 rows, 1 column, 1st subplot
        plot(f5, power5);
        xlabel('Frequency (cycles per hour)');
        ylabel('Power');
        title([validCondition, ' - FFT Power Spectrum for 5-Minute Bins']);
        xlim([0 1]); % Display relevant frequency range

        % === Hourly Bins Analysis ===
        % Create a new column for hourly bin identification
        selectedData.HourBin = selectedData.DateZT.Hour + 1;

        % Calculate mean NormalizedActivity for each hourly bin
        binMeansHourly = varfun(@mean, selectedData, 'InputVariables', 'NormalizedActivity', ...
                                'GroupingVariables', 'HourBin');
        
        % Remove any NaNs or incomplete bins entries
        binMeansHourly = rmmissing(binMeansHourly);

        % Apply FFT to hourly bins
        N1 = length(binMeansHourly.mean_NormalizedActivity);
        fftVals1 = fft(binMeansHourly.mean_NormalizedActivity);
        f1 = (0:N1-1)*(1/24); % Frequency for cycles per day
        power1 = abs(fftVals1).^2/N1;

        % Subplot 2: Hourly bin results
        subplot(2, 1, 2); % 2 rows, 1 column, 2nd subplot
        plot(f1, power1);
        xlabel('Frequency (cycles per day)');
        ylabel('Power');
        title([validCondition, ' - FFT Power Spectrum for Hourly Bins']);
        xlim([0 1]);

        % Save the figure
        save_filename_all = sprintf('%s--FFTPowerSpectrum.png', validCondition);
        saveas(gcf, fullfile(save_directory, save_filename_all));
    end
end

% Example call to the function
fftAnalysisEphysWithSubplots(data, conditionOrderEphys, save_directory, validConditionOrderEphys);