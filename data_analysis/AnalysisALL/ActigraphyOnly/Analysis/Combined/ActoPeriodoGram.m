% MATLAB Script for Circadian Activity Analysis (Group Averages)
% ---------------------------------------------------------------
% Description:
% Analyzes grass rat activity data from a CSV file. It calculates group
% averages (Male/Female) for activity data based on absolute timestamps.
% It generates two types of plots per sex group:
%   1. Hourly Actograms: Displays average activity per hour across days
%      within each experimental condition. Uses RelativeDay for the Y-axis.
%   2. Lomb-Scargle Periodograms: Calculates and plots the periodogram
%      based on the 5-minute averaged activity data for each condition.
% The script organizes plots into subplots within figures (one figure type
% per sex) and saves the figures to a specified directory.
%
% Key Features:
% - Loads data from CSV.
% - Handles timestamp alignment and averaging across animals within groups.
% - Bins data hourly for actograms.
% - Uses 'parula' colormap and dark background for NaN visibility in actograms.
% - Calculates Lomb-Scargle periodograms on 5-min averaged data.
% - Saves generated figures automatically.
% - Includes error handling and warnings.
% ---------------------------------------------------------------

%% --- Configuration ---
clear; clc; close all; % Start fresh

% --- File and Path Parameters ---
filename = '/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyOnly/AOActivityData.csv'; % Name/Path of your input CSV file
% *** DEFINE PATH TO SAVE FIGURES ***
savePath = '/Users/noahmuscat/Desktop'; 

% --- Data Column Names ---
activityVar = 'SelectedPixelDifference'; % Variable to use for analysis ('NormalizedActivity' or 'SelectedPixelDifference')
timeVar = 'DateZT';                 % Timestamp column (datetime)
relativeDayVar = 'RelativeDay';     % RelativeDay column (numeric)
animalVar = 'Animal';               % Animal ID column (string/cellstr)
conditionVar = 'Condition';         % Condition column (string/cellstr)

% --- Analysis Parameters ---
samplingIntervalMinutes = 5;      % Data sampling interval in minutes
periodogramRangeHours = [0.5, 48]; % Range of periods (hours) for periodogram
zt_lights_off_start = 12;         % Start hour of lights off (ZT 12)
zt_lights_off_end = 24;           % End hour (exclusive) of lights off (ZT 23)
actogramColormap = 'parula';      % Colormap for actograms
axesBackgroundColor = 'k';        % Background color for actogram axes ('k' = black)

% --- Animal Grouping ---
maleAnimals = {'AO1', 'AO2', 'AO3', 'AO7'};
femaleAnimals = {'AO4', 'AO5', 'AO6', 'AO8'};
sexGroups = {'Male', 'Female'}; % Groups to iterate over

% --- Derived Parameters (calculated automatically) ---
hoursPerDay = 24;
samplingIntervalDuration = minutes(samplingIntervalMinutes);
% *** Re-added binsPerHour calculation ***
binsPerHour = 60 / samplingIntervalMinutes; % Number of data points expected per hour
binsPerDay = hoursPerDay * binsPerHour;     % Number of data points expected per day (for periodogram check)


%% --- Setup Save Directory ---
disp(['Figures will be saved to: ', savePath]);
if ~isfolder(savePath)
    disp('Save directory does not exist. Creating...');
    try
        mkdir(savePath);
        disp('Directory created successfully.');
    catch ME_mkdir
        error('Could not create save directory "%s". Check path and permissions.\nError: %s', savePath, ME_mkdir.message);
    end
end

%% --- Load Data ---
disp(['Loading data from: ', filename]);
try
    opts = detectImportOptions(filename);

    % Ensure essential columns are read correctly, setting types if needed
    varNames = opts.VariableNames;
    requiredVars = {timeVar, relativeDayVar, animalVar, conditionVar, activityVar};
    for k = 1:length(requiredVars)
        varIdx = find(strcmp(varNames, requiredVars{k}), 1);
        if isempty(varIdx), error('Required column "%s" not found in CSV.', requiredVars{k}); end

        % Set expected types (adjust if necessary based on CSV format)
        currentType = opts.VariableTypes{varIdx};
        switch requiredVars{k}
            case timeVar
                if ~strcmp(currentType, 'datetime')
                    warning('Attempting to set variable type for "%s" to datetime.', timeVar);
                    opts = setvartype(opts, timeVar, 'datetime');
                end
            case relativeDayVar
                 if ~strcmp(currentType, 'double')
                    warning('Attempting to set variable type for "%s" to double.', relativeDayVar);
                    opts = setvartype(opts, relativeDayVar, 'double');
                 end
            case activityVar
                 if ~strcmp(currentType, 'double')
                    warning('Attempting to set variable type for "%s" to double.', activityVar);
                    opts = setvartype(opts, activityVar, 'double');
                 end
            case {animalVar, conditionVar}
                 if ~strcmp(currentType, 'cell') && ~strcmp(currentType, 'string')
                    opts = setvartype(opts, requiredVars{k}, 'string');
                 end
        end
    end

    dataTable = readtable(filename, opts);
    disp('Data loaded successfully.');

    % --- Convert/Validate Column Types ---
    if isstring(dataTable.(animalVar)), dataTable.(animalVar) = cellstr(dataTable.(animalVar)); end
    if isstring(dataTable.(conditionVar)), dataTable.(conditionVar) = cellstr(dataTable.(conditionVar)); end
    if ~iscellstr(dataTable.(animalVar)), dataTable.(animalVar) = cellstr(string(dataTable.(animalVar))); end
    if ~iscellstr(dataTable.(conditionVar)), dataTable.(conditionVar) = cellstr(string(dataTable.(conditionVar))); end
    if ~isdatetime(dataTable.(timeVar)), error('Column "%s" was not loaded as datetime.', timeVar); end
    if ~isnumeric(dataTable.(relativeDayVar)), error('Column "%s" was not loaded as numeric.', relativeDayVar); end
    if ~isnumeric(dataTable.(activityVar)), error('Activity variable "%s" is not numeric.', activityVar); end
    if isempty(dataTable.(timeVar).TimeZone), warning('Timestamp column "%s" has no timezone. Assuming local/naive time consistent with ZT.', timeVar); end

    disp('First few rows of loaded data:');
    disp(head(dataTable));
catch ME
    error('Failed to load or parse the CSV file "%s".\nCheck file path, format, column headers, data types, and permissions.\nMATLAB Error: %s', filename, ME.message);
end

%% --- Data Preprocessing ---
disp(['Sorting data by timestamp (' timeVar ')...']);
dataTable = sortrows(dataTable, timeVar);

% Remove rows with NaN in critical columns
nanActivityIdx = isnan(dataTable.(activityVar));
nanTimeIdx = isnat(dataTable.(timeVar));
nanRelDayIdx = isnan(dataTable.(relativeDayVar));
rowsToRemove = nanActivityIdx | nanTimeIdx | nanRelDayIdx;
if any(rowsToRemove)
    warning('%d rows removed due to NaN in activity (%s), timestamp, or RelativeDay.', sum(rowsToRemove), activityVar);
    dataTable(rowsToRemove, :) = [];
end
if isempty(dataTable)
    error('No valid data remains after removing NaN values.');
end

%% --- Analysis Loop ---
disp('Starting group-averaged analysis...');

for i = 1:length(sexGroups)
    currentSex = sexGroups{i};
    fprintf('\nProcessing Sex Group: %s\n', currentSex);

    % --- Initialize Figures for the Current Sex ---
    figTitleActo = sprintf('Actograms (Hourly): %s (%s)', currentSex, strrep(activityVar, '_', ' '));
    figTitlePerio = sprintf('Periodograms: %s (%s)', currentSex, strrep(activityVar, '_', ' '));
    hFigActoCurrentSex = figure('Name', figTitleActo, 'NumberTitle', 'off', 'Visible', 'off');
    hFigPerioCurrentSex = figure('Name', figTitlePerio, 'NumberTitle', 'off', 'Visible', 'off');
    actogramAxesHandles = []; % To store axes handles for color limit synchronization

    % --- Get Animal List and Filter Data ---
    if strcmp(currentSex, 'Male')
        animalsInGroup = maleAnimals;
    else % Female
        animalsInGroup = femaleAnimals;
    end

    try
        sexData = dataTable(ismember(dataTable.(animalVar), animalsInGroup), :);
    catch ME_filter
         error('Error during filtering for Animal column. Check data type consistency. Error: %s', ME_filter.message);
    end

    if isempty(sexData)
        warning('No data found for sex group %s using IDs: %s. Skipping plots for this group.', currentSex, strjoin(animalsInGroup, ', '));
        close(hFigActoCurrentSex); % Close unused figures
        close(hFigPerioCurrentSex);
        continue;
    end

    % --- Determine Conditions and Subplot Layout ---
    conditionsPresent = unique(sexData.(conditionVar), 'stable'); % Keep original order
    numConditions = length(conditionsPresent);
    if numConditions == 0
         warning('No conditions found for sex group %s after filtering. Skipping plots.', currentSex);
         close(hFigActoCurrentSex); close(hFigPerioCurrentSex);
         continue;
    end

    if numConditions <= 2, nRows = 1; nCols = numConditions;
    elseif numConditions <= 4, nRows = 2; nCols = 2;
    else, nRows = ceil(numConditions / 2); nCols = 2; end % Max 2 columns

    fprintf(' Animals: %s\n', strjoin(animalsInGroup, ', '));
    fprintf(' Conditions found: %s\n', strjoin(conditionsPresent, ', '));

    % --- Loop Through Conditions ---
    plotDataGenerated = false; % Flag to track if any subplots were made for this figure
    for j = 1:numConditions
        currentCondition = conditionsPresent{j};
        fprintf('-- Condition: %s (Subplot %d)\n', currentCondition, j);

        % Filter Data for Current Sex/Condition
        try
            conditionData = sexData(strcmp(sexData.(conditionVar), currentCondition), :);
        catch ME_filter_cond
             warning('Error during filtering for Condition column. Skipping condition %s. Error: %s', currentCondition, ME_filter_cond.message);
             continue;
        end

        % *** Check uses binsPerHour again ***
        if isempty(conditionData) || height(conditionData) < binsPerHour % Need at least an hour of data
            warning('Insufficient or no data found for Sex %s, Condition %s (found %d rows, need >= %d). Skipping subplot.', currentSex, currentCondition, height(conditionData), binsPerHour);
            continue;
        end

        % --- Averaging Step (5-min bins) ---
        disp('   Averaging 5-min activity across animals...');
        averagedActivity_5min = []; fullTimeVector_5min = []; averagedRelDays_5min = [];
        try
            roundedTimestamps_5min = dateshift(conditionData.(timeVar), 'start', 'minute', samplingIntervalMinutes);
            activityData_5min = conditionData.(activityVar);
            relDayData_5min = conditionData.(relativeDayVar);

            minTimeCond = min(roundedTimestamps_5min);
            maxTimeCond = max(roundedTimestamps_5min);
            fullTimeVector_5min = (minTimeCond : samplingIntervalDuration : maxTimeCond)';

            if isempty(fullTimeVector_5min), error('Could not create 5-min time vector.'); end

            [groupIndices_5min, uniqueGroupTimes_5min] = findgroups(roundedTimestamps_5min);
            meanActivityPerGroup_5min = splitapply(@nanmean, activityData_5min, groupIndices_5min);
            meanRelDayPerGroup_5min = splitapply(@nanmean, relDayData_5min, groupIndices_5min);

            averagedActivity_5min = NaN(length(fullTimeVector_5min), 1);
            averagedRelDays_5min = NaN(length(fullTimeVector_5min), 1);
            [lia, locb] = ismember(fullTimeVector_5min, uniqueGroupTimes_5min);
            averagedActivity_5min(lia) = meanActivityPerGroup_5min(locb(lia));
            averagedRelDays_5min(lia) = meanRelDayPerGroup_5min(locb(lia));

        catch ME_avg_5min
            warning('Error during 5-min averaging for Sex %s, Condition %s. Skipping subplot. Error: %s', currentSex, currentCondition, ME_avg_5min.message);
            continue;
        end

        % --- Binning to Hourly Data & Reshaping for Actogram ---
        disp('   Binning averaged data to hourly intervals...');
        activityMatrixHourly = []; dayLabels = [];
        try
            validIdx_hourly = find(~isnan(averagedActivity_5min) & ~isnan(averagedRelDays_5min));
            if isempty(validIdx_hourly), error('No valid 5-min data for hourly binning.'); end

            validActivity_5min = averagedActivity_5min(validIdx_hourly);
            validRelDays_5min = floor(averagedRelDays_5min(validIdx_hourly));
            validTimestamps_5min = fullTimeVector_5min(validIdx_hourly);

            ztHour = hour(validTimestamps_5min);
            relDayHourly = validRelDays_5min;

            minPlotDay = min(relDayHourly(relDayHourly>0));
            maxPlotDay = max(relDayHourly);
            if isempty(minPlotDay) || minPlotDay < 1, minPlotDay = 1; end
            if isempty(maxPlotDay) || maxPlotDay < minPlotDay, error('Invalid RelativeDay range.'); end

            numPlotDays = maxPlotDay - minPlotDay + 1;
            dayOffset = minPlotDay - 1;

            subsRow = relDayHourly - dayOffset;
            subsCol = ztHour + 1;

            validSubs = subsRow >= 1 & subsRow <= numPlotDays & subsCol >= 1 & subsCol <= hoursPerDay;
            if ~all(validSubs)
                warning('%d points excluded due to invalid subscripts in hourly binning.', sum(~validSubs));
                subsRow = subsRow(validSubs); subsCol = subsCol(validSubs);
                validActivity_5min_subs = validActivity_5min(validSubs);
            else
                validActivity_5min_subs = validActivity_5min;
            end
            if isempty(subsRow), error('No valid points after subscript validation.'); end

            sumPerHour = accumarray([subsRow, subsCol], validActivity_5min_subs, [numPlotDays, hoursPerDay], @sum, NaN);
            countPerHour = accumarray([subsRow, subsCol], 1, [numPlotDays, hoursPerDay], @sum, 0);

            activityMatrixHourly = sumPerHour ./ countPerHour;
            activityMatrixHourly(countPerHour == 0) = NaN;
            dayLabels = minPlotDay : maxPlotDay;

        catch ME_reshape
            warning('Error during hourly binning/reshaping for Sex %s, Condition %s. Skipping subplot. Error: %s', currentSex, currentCondition, ME_reshape.message);
            continue;
        end

        % --- Data Quality Checks for HOURLY Data ---
        if isempty(activityMatrixHourly) || size(activityMatrixHourly,1) < 1
             warning('No valid days remain after hourly binning for Sex %s, Condition %s. Skipping plots.', currentSex, currentCondition);
             continue;
        end
        if all(isnan(activityMatrixHourly(:)))
            warning('All HOURLY averaged activity data is NaN for Sex %s, Condition %s. Skipping plots.', currentSex, currentCondition);
            continue;
        end
        plotDataGenerated = true; % Mark that we will generate at least one subplot

        % --- Actogram Generation (HOURLY, Single Plot) ---
        disp('   Generating Averaged HOURLY Actogram Subplot...');
        try
            figure(hFigActoCurrentSex); % Ensure figure is active
            axHandle = subplot(nRows, nCols, j);
            actogramAxesHandles = [actogramAxesHandles, axHandle]; % Store handle

            numPlotDays_actual = size(activityMatrixHourly, 1);
            actogramMatrix = activityMatrixHourly; % Single plot

            imagesc(axHandle, actogramMatrix, 'AlphaData', ~isnan(actogramMatrix)); % Plot to specific axes
            colormap(axHandle, actogramColormap);
            axHandle.YDir = 'reverse';
            axHandle.Color = axesBackgroundColor; % Set dark background

            xlabel(axHandle, 'ZT Hour');
            xTickPos = [0.5, 6.5, 12.5, 18.5, 23.5];
            xTickLabels = [0, 6, 12, 18, 23];
            set(axHandle, 'XTick', xTickPos, 'XTickLabel', xTickLabels);
            xlim(axHandle, [0.5, hoursPerDay + 0.5]);

            ylabel(axHandle, 'Relative Day'); % Simplified label
            if numPlotDays_actual > 10, yTickIndices = unique(round(linspace(1, numPlotDays_actual, 5)));
            else, yTickIndices = 1:numPlotDays_actual; end
            yTickIndices = yTickIndices(yTickIndices >= 1 & yTickIndices <= length(dayLabels));
            if isempty(yTickIndices) && numPlotDays_actual > 0, yTickIndices = 1:numPlotDays_actual; end
            set(axHandle, 'YTick', yTickIndices, 'YTickLabel', dayLabels(yTickIndices));
            ylim(axHandle, [0.5, numPlotDays_actual + 0.5]);

            title(axHandle, currentCondition);

            hold(axHandle, 'on'); % Ensure hold is applied to the correct axes
            startHourPatch = zt_lights_off_start + 0.5;
            endHourPatch = zt_lights_off_end -1 + 1.5;
            yLims = ylim(axHandle);
            patch(axHandle, [startHourPatch endHourPatch endHourPatch startHourPatch], [yLims(1) yLims(1) yLims(2) yLims(2)], ...
                  axesBackgroundColor, 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off'); % Use background color for patch
            hold(axHandle, 'off');
            set(axHandle, 'Layer', 'top');

        catch ME_actogram
            warning('Could not generate averaged hourly actogram subplot for Sex %s, Condition %s. Error: %s', currentSex, currentCondition, ME_actogram.message);
        end


        % --- Periodogram Generation (Subplot, uses 5-min averaged data) ---
        disp('   Generating Averaged Periodogram Subplot (using 5-min data)...');
        try
            figure(hFigPerioCurrentSex); % Ensure figure is active
            axPerio = subplot(nRows, nCols, j); % Use different axes handle

            activityClean_perio = averagedActivity_5min;
            timeHoursClean_perio = hours(fullTimeVector_5min - fullTimeVector_5min(1));

            validIdx_perio = ~isnan(activityClean_perio);
            % *** Check uses binsPerDay ***
            if sum(validIdx_perio) < (binsPerDay / 2) % Need at least half a day of 5-min data
                error('Less than half a day of 5-min data for periodogram.');
            end
            activityClean_perio = activityClean_perio(validIdx_perio);
            timeHoursClean_perio = timeHoursClean_perio(validIdx_perio);

            ofac = 4; hifac = 1; % Periodogram parameters
            [pxx, f] = plomb(activityClean_perio, timeHoursClean_perio, [], ofac, 'normalized');

            periodHours = 1 ./ f;
            minPeriod = periodogramRangeHours(1); maxPeriod = periodogramRangeHours(2);
            freqRangeIdx = periodHours >= minPeriod & periodHours <= maxPeriod;
            periodHours = periodHours(freqRangeIdx);
            pxx = pxx(freqRangeIdx);

            [periodHours, sortIdx] = sort(periodHours);
            pxx = pxx(sortIdx);

            plot(axPerio, periodHours, pxx, 'LineWidth', 1.5); % Plot to specific axes
            xlabel(axPerio, 'Period (h)');
            ylabel(axPerio, 'Power');
            title(axPerio, currentCondition);
            grid(axPerio, 'on');
            xlim(axPerio, periodogramRangeHours);

            if ~isempty(pxx)
                [maxPower, maxIdx] = max(pxx);
                peakPeriod = periodHours(maxIdx);
                hold(axPerio, 'on');
                plot(axPerio, peakPeriod, maxPower, 'rv', 'MarkerSize', 6, 'MarkerFaceColor', 'r');
                text(axPerio, peakPeriod, maxPower, sprintf(' %.1fh', peakPeriod), ...
                     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', 'r');
                hold(axPerio, 'off');
                fprintf('     Peak Period (Avg using %s): %.2f hours (Power: %.3f)\n', activityVar, peakPeriod, maxPower);
            else
                 warning('No power spectral density values found within the specified period range [%.1f, %.1f] hours.', minPeriod, maxPeriod);
                 fprintf('     Peak Period (Avg using %s): Not found in range\n', activityVar);
            end

        catch ME_periodogram
            warning('Could not generate averaged periodogram subplot for Sex %s, Condition %s. Error: %s', currentSex, currentCondition, ME_periodogram.message);
        end

    end % End loop through conditions for one sex group

    % --- Finalize and Save Figures for the Current Sex ---
    if plotDataGenerated % Only save if subplots were actually generated
        try
            figure(hFigActoCurrentSex); % Bring to front
            % Add overall title
            sgtitle(figTitleActo, 'FontWeight', 'bold');
            % Add shared colorbar
            if ~isempty(actogramAxesHandles)
                minClim = inf; maxClim = -inf; validAxesExist = false;
                for ax = actogramAxesHandles
                    if ishandle(ax) && ~isempty(ax.Children) && isa(ax.Children(end), 'matlab.graphics.primitive.Image')
                         imgData = ax.Children(end).CData;
                         currentMin = min(imgData(:), [], 'omitnan'); currentMax = max(imgData(:), [], 'omitnan');
                         if isfinite(currentMin) && isfinite(currentMax)
                            minClim = min(minClim, currentMin); maxClim = max(maxClim, currentMax);
                            validAxesExist = true;
                         end
                    end
                end
                if validAxesExist && isfinite(minClim) && isfinite(maxClim) && maxClim > minClim
                     for ax = actogramAxesHandles
                         if ishandle(ax), ax.CLim = [minClim, maxClim]; end
                     end
                     lastValidAx = find(ishandle(actogramAxesHandles), 1, 'last');
                     if ~isempty(lastValidAx)
                         cb = colorbar(actogramAxesHandles(lastValidAx));
                         if ishandle(cb), ylabel(cb, strrep(activityVar, '_', ' '), 'Rotation', 270, 'VerticalAlignment', 'bottom'); end
                     end
                else
                    warning('Could not determine valid color limits for figure %s. Skipping shared colorbar.', hFigActoCurrentSex.Name);
                end
            end
            set(hFigActoCurrentSex, 'Visible', 'on'); % Make visible before saving

            % Save Actogram Figure
            actoFigName = sprintf('Actogram_Hourly_%s_%s.png', currentSex, strrep(activityVar,' ','')); % Clean filename
            actoSaveFullName = fullfile(savePath, actoFigName);
            disp(['Saving actogram figure: ', actoSaveFullName]);
            saveas(hFigActoCurrentSex, actoSaveFullName);

        catch ME_save_acto
             warning('Could not finalize or save actogram figure for %s. Error: %s', currentSex, ME_save_acto.message);
             if ishandle(hFigActoCurrentSex), set(hFigActoCurrentSex, 'Visible', 'on'); end % Still try to show it
        end

        try
            figure(hFigPerioCurrentSex); % Bring to front
            sgtitle(figTitlePerio, 'FontWeight', 'bold');
            set(hFigPerioCurrentSex, 'Visible', 'on'); % Make visible before saving

            % Save Periodogram Figure
            perioFigName = sprintf('Periodogram_%s_%s.png', currentSex, strrep(activityVar,' ','')); % Clean filename
            perioSaveFullName = fullfile(savePath, perioFigName);
            disp(['Saving periodogram figure: ', perioSaveFullName]);
            saveas(hFigPerioCurrentSex, perioSaveFullName);

        catch ME_save_perio
             warning('Could not finalize or save periodogram figure for %s. Error: %s', currentSex, ME_save_perio.message);
              if ishandle(hFigPerioCurrentSex), set(hFigPerioCurrentSex, 'Visible', 'on'); end % Still try to show it
        end
    else
        % If no subplots were generated, close the empty figures
         if ishandle(hFigActoCurrentSex), close(hFigActoCurrentSex); end
         if ishandle(hFigPerioCurrentSex), close(hFigPerioCurrentSex); end
         warning('No data plotted for Sex %s. Figures not saved.', currentSex);
    end


end % End loop through sex groups

disp('--- Group Averaged Analysis Script Finished ---');
