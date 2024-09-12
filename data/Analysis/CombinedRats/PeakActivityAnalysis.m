%% Overall analysis of circadian 24 hour activity
% Looking at all rats and all conditions over a 24-hour time period to find
% peak analysis. All data is normalized to each specific rat AND condition,
% so this looks only at peak activity, not comparing across lighting
% conditions

% List of rat IDs and conditions
ratIDs = {'Rollo', 'Canute', 'Harald', 'Gunnar', 'Egil', 'Sigurd', 'Olaf'}; % Add more rat IDs as needed
conditions = {'300Lux', '1000Lux1', '1000Lux4'};

dataDir = '/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/JeremyAnalysis/ZT';
normalizedActivity = struct();

% Normalize condition names to be valid field names
validConditionNames = strcat('Cond_', conditions);

% Loop over each rat and condition
for i = 1:length(ratIDs)
    ratID = ratIDs{i};
    
    for j = 1:length(conditions)
        condition = conditions{j};
        validCondition = validConditionNames{j};
        
        % Construct the filename
        filename = sprintf('%s_%s_ZT.csv', ratID, condition); % Adjust filename based on your pattern
        fullPath = fullfile(dataDir, ratID, filename);
        
        % Check if the file exists
        if isfile(fullPath)
            % Load the data from the CSV file using readtable
            fprintf('Analyzing: %s\n', fullPath);
            dataTable = readtable(fullPath);
            
            % Assuming the data includes a 'Date' column in datetime format and a 'SelectedPixelDifference' column
            if ismember('Date', dataTable.Properties.VariableNames) && ismember('SelectedPixelDifference', dataTable.Properties.VariableNames)
                dateData = dataTable.Date; % Datetime data
                activityData = dataTable.SelectedPixelDifference;
                
                % Extract hour from datetime data
                hours = hour(dateData);
                
                % Bin data by hour (1-hour bins)
                edges = 0:24; % Correct edges to include 24 for completeness
                binIndices = discretize(hours, edges);
                
                % Remove NaN and zero indices
                validIndices = binIndices > 0;
                binIndices = binIndices(validIndices);
                activityData = activityData(validIndices);
                
                % Calculate sum of activity for each bin
                binnedActivity = accumarray(binIndices, activityData, [24, 1], @sum, NaN);
                
                % Calculate z-score normalization for the binned activity
                meanActivity = mean(binnedActivity, 'omitnan');
                stdActivity = std(binnedActivity, 'omitnan');
                
                if stdActivity == 0
                    zscoredActivity = zeros(size(binnedActivity)); % Avoid division by zero
                else
                    zscoredActivity = (binnedActivity - meanActivity) / stdActivity;
                end
                
                % Store results for each animal and condition
                normalizedActivity.(ratID).(validCondition).binnedActivity = zscoredActivity;
            else
                fprintf('Column "Date" or "SelectedPixelDifference" not found in file: %s\n', fullPath);
            end
        else
            fprintf('File not found: %s\n', fullPath);  % Log missing files
        end
    end
end

% Graphical representation of normalized activity
figure;
hold on;

% Plot all conditions together for comparison
colors = lines(length(conditions));
legendEntries = {};

for j = 1:length(validConditionNames)
    validCondition = validConditionNames{j};
    
    for i = 1:length(ratIDs)
        ratID = ratIDs{i};
        
        if isfield(normalizedActivity, ratID) && isfield(normalizedActivity.(ratID), validCondition)
            binnedActivity = normalizedActivity.(ratID).(validCondition).binnedActivity;
            
            % Plot each rat's z-score normalized activity data
            plot(0:23, binnedActivity, 'DisplayName', sprintf('%s - %s', ratID, conditions{j}), 'Color', colors(j, :));
            hold on;
            
            legendEntries{end+1} = sprintf('%s - %s', ratID, conditions{j});
        end 
     end
end


xlabel('Hour of the Day');
ylabel('Normalized Activity');
title('Normalized Activity Over 24 Hours for All Rats');
legend(legendEntries, 'Location', 'BestOutside');
hold off;

% Save the figure if necessary
%saveas(gcf, fullfile(dataDir, 'Normalized_Activity_Per_Hour.png'));

disp('Z-score normalized activity analysis and plots generated and saved.');

