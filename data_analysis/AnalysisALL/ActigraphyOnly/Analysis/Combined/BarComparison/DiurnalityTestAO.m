% Load the CSV data
data = readtable('/Users/noahmuscat/University of Michigan Dropbox/Noah Muscat/ActivityAnalysis/ActigraphyOnly/AOActivityData.csv');
save_directory = '/Users/noahmuscat/Desktop';

% Define animal groups
maleAnimals = {'AO1', 'AO2', 'AO3', 'AO7'};
femaleAnimals = {'AO4', 'AO5', 'AO6', 'AO8'};

% Perform analysis for males and females
analyzeGroup(data, maleAnimals, 'Males', save_directory);
analyzeGroup(data, femaleAnimals, 'Females', save_directory);

% Function to analyze a gender group and plot results
function analyzeGroup(data, animalGroup, genderLabel, save_directory)
    % Filter data for current gender group
    genderData = data(ismember(data.Animal, animalGroup), :);
    
    % Create hourly bins
    genderData.HourlyBins = dateshift(genderData.DateZT, 'start', 'hour');
    hourlySumTable = groupsummary(genderData, 'HourlyBins', 'mean', 'NormalizedActivity');
    hourlyMeans = hourlySumTable.mean_NormalizedActivity;
    hourlyBinTimes = hourlySumTable.HourlyBins;
    
    % Extract ZT time from hourly bins
    ZT_Time = mod(hour(hourlyBinTimes), 24);

    % Define ZT ranges
    lights_on_range = ismember(ZT_Time, 3:9);
    lights_off_range = ismember(ZT_Time, 15:21);
    zt_10_14 = ismember(ZT_Time, 10:14);
    zt_22_2 = ismember(ZT_Time, [22, 23, 0, 1, 2]);
    zt_rest = ~(zt_10_14 | zt_22_2); % Remaining ZT: combines ZT 3-9 and ZT 15-21

    % Plot results with subplots
    figure;

    subplot(1, 2, 1);
    plotComparison(hourlyMeans, lights_on_range, lights_off_range, {'3-9', '15-21'}, 'Diurnality Test');

    subplot(1, 2, 2);
    plotMultiplePeriods(hourlyMeans, zt_10_14, zt_22_2, zt_rest, {'10-14', '22-2', 'Rest of Day'}, 'ZT Period Comparison');
    
    sgtitle(genderLabel);

    save_filename = sprintf('%s--Diurnality.png', genderLabel); % Construct the filename
    saveas(gcf, fullfile(save_directory, save_filename)); % Save the figure
end

% Function to calculate the mean and SEM
function [meanValue, semValue] = calculateMeanSEM(hourlyMeans, range)
    meanValue = mean(hourlyMeans(range));
    semValue = std(hourlyMeans(range)) / sqrt(sum(range));
end

% Function to plot comparison for two periods with stats
function plotComparison(hourlyMeans, range1, range2, labels, compTitle)
    % Calculate means and SEMs
    mean1 = mean(hourlyMeans(range1));
    sem1 = std(hourlyMeans(range1)) / sqrt(sum(range1));
    mean2 = mean(hourlyMeans(range2));
    sem2 = std(hourlyMeans(range2)) / sqrt(sum(range2));

    means = [mean1, mean2];
    sems = [sem1, sem2];
    
    bar(1:2, means, 'FaceColor', [0.5, 0.7, 0.9]);
    hold on;
    errorbar(1:2, means, sems, 'k', 'LineStyle', 'none');
    set(gca, 'XTickLabel', labels);
    xlabel('Zeitgeber Time Period');
    ylabel('Normalized Activity');
    ylim([-0.4, 0.4]);
    title(compTitle);
    
    % Perform statistical test
    [~, p] = ttest2(hourlyMeans(range1), hourlyMeans(range2));

    % Add significance stars if p-value < 0.05
    if p < 0.05
        sigstar({[1, 2]}, p);
    end
    
    hold off;
end

% Function to plot comparison for three periods with ANOVA and post-hoc
function plotMultiplePeriods(hourlyMeans, range1, range2, range3, labels, compTitle)
    % Gather data for ANOVA
    values = [hourlyMeans(range1); hourlyMeans(range2); hourlyMeans(range3)];
    group = [repmat(1, sum(range1), 1); repmat(2, sum(range2), 1); repmat(3, sum(range3), 1)];
    
    % Perform ANOVA
    [~, tbl, stats] = anova1(values, group, 'off');
    
    % Multiple comparisons post-hoc analysis
    c = multcompare(stats, 'CType', 'bonferroni', 'Display', 'off');

    % Calculate means and SEMs
    mean1 = mean(hourlyMeans(range1));
    sem1 = std(hourlyMeans(range1)) / sqrt(sum(range1));
    mean2 = mean(hourlyMeans(range2));
    sem2 = std(hourlyMeans(range2)) / sqrt(sum(range2));
    mean3 = mean(hourlyMeans(range3));
    sem3 = std(hourlyMeans(range3)) / sqrt(sum(range3));

    means = [mean1, mean2, mean3];
    sems = [sem1, sem2, sem3];

    bar(1:3, means, 'FaceColor', [0.5, 0.7, 0.9]);
    hold on;
    errorbar(1:3, means, sems, 'k', 'LineStyle', 'none');
    set(gca, 'XTickLabel', labels);
    xlabel('Zeitgeber Time Period');
    ylabel('Normalized Activity');
    ylim([-0.4, 0.4]);
    title(compTitle);

    % Annotate significant pairwise comparisons
    for i = 1:size(c, 1)
        if c(i, 6) < 0.05
            sigstar({c(i, 1:2)}, c(i, 6));
        end
    end
    
    hold off;
end