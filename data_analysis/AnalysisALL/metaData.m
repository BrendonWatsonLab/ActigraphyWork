data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyEphys/EphysActivityData.csv');

% Convert the DateZT column to datetime (assuming it's in 'MM/dd/yy HH:mm' format)
data.DateZT = datetime(data.DateZT, 'InputFormat', 'MM/dd/yy HH:mm');

% Extract unique conditions
conditions = unique(data.Condition);

for i = 1:length(conditions)
    condition = conditions{i};
    
    % Filter data for the current condition
    conditionData = data(strcmp(data.Condition, condition), :);
    
    % Extract unique days
    uniqueDays = unique(floor(conditionData.RelativeDay));
    disp(condition)
    disp(uniqueDays)

end

