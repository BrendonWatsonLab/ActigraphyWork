function [binnedData] = Binner(data, binbyminute, isfile)
    % Define the bin duration: 5 minutes
    binDuration = minutes(binbyminute);

    if isfile
        fprintf('Reading in data table... \n');
        data = readtable(data);
    end

    % Preallocate the table for binned data with the correct structure
    binnedData = table('Size', [0, 6], ...
                       'VariableTypes', {'double', 'double', 'cell', 'cell', 'datetime', 'double'}, ...
                       'VariableNames', {'SelectedPixelDifference', 'NormalizedActivity', 'Rat', 'Condition', 'Date', 'RelativeDay'});

    rats = unique(data.Rat);
    conditions = unique(data.Condition);

    for r = 1:length(rats)
        rat = rats{r};
        for c = 1:length(conditions)
            condition = conditions{c};
            fprintf('Binning %s: %s \n', rat, condition);
            thisData = data(strcmp(data.Rat, rat) & strcmp(data.Condition, condition), :);

            if isempty(thisData)
                fprintf('No data found \n');
                continue;
            end

            % Generate datetime bins
            edges = thisData.Date(1):binDuration:thisData.Date(end) + binDuration;
            bins = discretize(thisData.Date, edges);

            % Aggregate data within each bin
            for b = 1:max(bins)
                binData = thisData(bins == b, :);
                if isempty(binData)
                    continue;
                end
                % Calculate mean of SelectedPixelDifference, NormalizedActivity, and RelativeDay
                meanSelectedPixelDiff = mean(binData.SelectedPixelDifference);
                meanNormalizedActivity = mean(binData.NormalizedActivity);
                meanRelativeDay = mean(binData.RelativeDay); % Assumes RelativeDay is consistent within 5 minutes

                % Choose the bin start time as the representative datetime
                binStartTime = edges(b);

                % Create a new row for the binned data
                newRow = {meanSelectedPixelDiff, meanNormalizedActivity, rat, condition, binStartTime, meanRelativeDay};
                fprintf('New row to be added:\n');
                disp(newRow);

                % Append to the binned data table
                binnedData = [binnedData; newRow]; %#ok<AGROW>
            end
        end
    end
end

