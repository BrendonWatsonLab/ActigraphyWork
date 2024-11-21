%% Exploring the file
exploreMatFile('Canute_231208.SleepState.states.mat');

%% Analyzing the file

% Define the file path to the sleep state .mat file (must be updated)
sleepstatesFile = '/data/Jeremy/Sleepscoring Output Files/Canute/Canute_231208/Canute_231208.SleepState.states.mat';

% Load the sleep state data
sleepData = load(sleepstatesFile);
sleepStates = sleepData.SleepState.idx.states;

% Filter valid sleep states (only 1, 3, 5 are valid)
validStates = ismember(sleepStates, [1, 3, 5]);
sleepStates = sleepStates(validStates);

% Filter corresponding timestamps
posixTime = sleepData.SleepState.idx.timestamps(validStates);

% Check unique states available in the data to confirm (1: WAKE, 3: NREM, 5: REM)
uniqueStates = unique(sleepStates);
disp('Unique sleep states present in the data:');
disp(uniqueStates');

% Check the length of the timestamps to ensure it matches the sleep states length
if length(posixTime) ~= length(sleepStates)
    error('Mismatch between the length of timestamps and sleep states data.');
end

% Convert Posix timestamps to datetime array for easier manipulation
timeArray = datetime(posixTime, 'ConvertFrom', 'posixtime', 'TimeZone', 'America/New_York');

% Calculate Zeitgeber Time (ZT) in hours considering DST
ZTtime = zeros(size(timeArray));
for i = 1:length(timeArray)
    currentHour = hour(timeArray(i));
    isDST = isdst(timeArray(i));
    if isDST
        % Daylight Saving Time (lights on at 6 AM, lights off at 6 PM)
        ZTtime(i) = mod((currentHour - 6) + (minute(timeArray(i)) / 60), 24);
    else
        % Standard Time (lights on at 5 AM, lights off at 5 PM)
        ZTtime(i) = mod((currentHour - 5) + (minute(timeArray(i)) / 60), 24);
    end
end

% Determine lighting condition based on ZT time (1 for lights on: ZT 0-12, 0 for lights off: ZT 12-24)
lightingCondition = ZTtime >= 0 & ZTtime < 12;

% Metadata for animal sex
animalSex = repmat({'M'}, length(posixTime), 1);  % 'M' for male

% Create a table to save data, adding relevant columns for your specific analysis
sleepSummaryTable = table(posixTime, ZTtime, sleepStates, lightingCondition, animalSex, ...
                          'VariableNames', {'PosixTime', 'ZT_time_hours', 'SleepState', 'LightingCondition', 'AnimalSex'});

% Save the table to a CSV file
writetable(sleepSummaryTable, '/data/Jeremy/Sleepscoring_Data_Noah/Canute_231208_sleep_summary.csv');

disp('Sleep summary CSV created successfully.');

% Computation and Visualization

% Proportion of time spent in each sleep state
totalTime = length(sleepStates);
wakeTime = sum(sleepStates == 1);
nremTime = sum(sleepStates == 3);
remTime = sum(sleepStates == 5);

fprintf('Proportion of time spent in each sleep state:\n');
fprintf('WAKE: %.2f%%\n', (wakeTime / totalTime) * 100);
fprintf('NREM: %.2f%%\n', (nremTime / totalTime) * 100);
fprintf('REM: %.2f%%\n', (remTime / totalTime) * 100);

% Plot sleep states over time
figure;
plot(timeArray, sleepStates);
xlabel('Time');
ylabel('Sleep State');
title('Sleep States Over Time');
yticks([1 3 5]);
yticklabels({'WAKE', 'NREM', 'REM'});
grid on;

% Histogram of sleep states
figure;
histogram(sleepStates, 'BinWidth', 1);
xlabel('Sleep State');
ylabel('Frequency');
title('Distribution of Sleep States');
xticks([1 3 5]);
xticklabels({'WAKE', 'NREM', 'REM'});
grid on;

% Example Plot: Sleep state occupancy by ZT time
ZT_bins = 0:1:24;
ZT_occupancyWAKE = histcounts(ZTtime(sleepStates == 1), ZT_bins);
ZT_occupancyNREM = histcounts(ZTtime(sleepStates == 3), ZT_bins);
ZT_occupancyREM = histcounts(ZTtime(sleepStates == 5), ZT_bins);

figure;
hold on;
plot(ZT_bins(1:end-1) + 0.5, ZT_occupancyWAKE, 'r', 'DisplayName', 'WAKE');
plot(ZT_bins(1:end-1) + 0.5, ZT_occupancyNREM, 'g', 'DisplayName', 'NREM');
plot(ZT_bins(1:end-1) + 0.5, ZT_occupancyREM, 'b', 'DisplayName', 'REM');
xlabel('ZT Time (hours)');
ylabel('State Occupancy Frequency');
title('Sleep State Occupancy by ZT Time');
legend('show');
grid on;
hold off;

%% Spectral Analysis Steps: Example outline, not fully implemented
% Depending on how you want to analyze EEG data's spectral components,
% you may need to load and process other parts, such as LFP signals and specific frequency bands.

% Example placeholder to indicate where you would add spectral analysis.
% Replace with actual data loading and processing for spectral analysis.

% Example Spectral Analysis
% Load EEG data (replace with actual file name & path)
% eegData = load('path_to_your_eeg_data_file.mat'); 
% eegSignal = eegData.your_eeg_signal_field; % Replace with actual field name
% fs = 1000; % Sampling frequency (replace with actual value)
% window = 256; % Length of the window
% noverlap = 128; % Overlap between segments
% nfft = 512; % Number of points in FFT

% Compute power spectral density (replace variables with actual data)
% [pxx,f] = pwelch(eegSignal, window, noverlap, nfft, fs);

% Plot power spectral density
% figure;
% plot(f, 10*log10(pxx));
% xlabel('Frequency (Hz)');
% ylabel('Power/Frequency (dB/Hz)');
% title('Power Spectral Density');
% grid on;