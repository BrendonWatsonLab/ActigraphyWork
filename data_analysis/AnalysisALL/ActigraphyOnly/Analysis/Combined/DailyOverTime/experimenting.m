% Load data
data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyOnly/AOActivityData.csv');

% Convert dates
data.DateZT = datetime(data.DateZT, 'InputFormat', 'MM/dd/yy HH:mm');

% Add a gender column based on provided animal information
data.Gender = cell(size(data.Animal));
data.Gender(ismember(data.Animal, {'AO1', 'AO2', 'AO3', 'AO7'})) = {'Male'};
data.Gender(ismember(data.Animal, {'AO4', 'AO5', 'AO6', 'AO8'})) = {'Female'};

% Define conditions
conditions = {'300Lux', '1000Lux', 'FullDark', '300LuxEnd'};

% Function to plot data for each gender including individual animals
function plotActivityByGender(data, gender, conditions)
    genderData = data(strcmp(data.Gender, gender), :);
    figure;
    titleStr = sprintf('Normalized Activity Over Experiment - %s', gender);
    title(titleStr);
    hold on;
    ylabel('Normalized Activity');
    xlabel('Condition');

    xPos = 1; % Track the x-axis position dynamically
    sectionCenters = []; % To store center positions for x-tick labels
    plotHandles = []; % Collect plot handles for the legend

    % Plot lines for each individual animal
    animals = unique(genderData.Animal);
    for animalIdx = 1:length(animals)
        animal = animals{animalIdx};
        animalData = genderData(strcmp(genderData.Animal, animal), :);

        % Track x position dynamically within each condition
        condXPos = xPos;
        for condIdx = 1:length(conditions)
            cond = conditions{condIdx};
            condData = animalData(strcmp(animalData.Condition, cond), :);

            % Calculate unique floored days and corresponding data
            flooredDays = floor(condData.RelativeDay);
            uniqueDays = unique(flooredDays);

            if ~isempty(uniqueDays)
                % Calculate individual activity for each floored day
                individualActivity = arrayfun(@(day) mean(condData.NormalizedActivity(flooredDays == day)), uniqueDays);
                
                % Debugging output
                fprintf('Animal: %s, Condition: %s\n', animal, cond);
                disp('Unique Days:'), disp(uniqueDays');
                disp('Individual Activities:'), disp(individualActivity');
                
                % Plot data for the current animal and condition
                dayNumbers = condXPos:condXPos+length(uniqueDays)-1;
                p = plot(dayNumbers, individualActivity, '-o', 'LineWidth', 2, 'MarkerSize', 6, 'Color', 'g');

                % Update xPos for individual animal
                condXPos = condXPos + length(uniqueDays);
            end
        end
    end

    % Plot averaged lines for each condition
    for condIdx = 1:length(conditions)
        cond = conditions{condIdx};
        condData = genderData(strcmp(genderData.Condition, cond), :);

        % Calculate unique floored days and corresponding means
        flooredDays = floor(condData.RelativeDay);
        uniqueDays = unique(flooredDays);

        if ~isempty(uniqueDays)
            meanActivity = arrayfun(@(day) mean(condData.NormalizedActivity(flooredDays == day)), uniqueDays);
            
            % Debugging output for averages
            fprintf('Condition: %s\n', cond);
            disp('Unique Days:'), disp(uniqueDays');
            disp('Mean Activities:'), disp(meanActivity');

            % Plot average line for the current condition
            dayNumbers = xPos:xPos+length(uniqueDays)-1;
            h = plot(dayNumbers, meanActivity, '-o', 'LineWidth', 2, 'MarkerSize', 6);
            plotHandles = [plotHandles, h]; % Collect plot handles
            set(h, 'DisplayName', cond);

            % Calculate center position for x-tick label
            sectionCenters = [sectionCenters, mean(dayNumbers)];

            % Mark the division between conditions
            if condIdx < length(conditions)
                xline(dayNumbers(end) + 0.5, '--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
            end

            % Update xPos after averaging plot to synchronize with individual lines
            xPos = xPos + length(uniqueDays);
        end
    end

    % Set custom x-ticks to mark the center of each condition
    xticks(sectionCenters);
    xticklabels(conditions);

    % Only include plot handles for average lines in the legend
    legend(plotHandles, 'Location', 'northwest');
    hold off;
end

% Plot for males
plotActivityByGender(data, 'Male', conditions);

% Plot for females
plotActivityByGender(data, 'Female', conditions);