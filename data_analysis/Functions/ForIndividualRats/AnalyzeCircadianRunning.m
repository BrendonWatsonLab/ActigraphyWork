function AnalyzeCircadianRunning(datafile, convert_ZT, name, save_directory)
    if ~istable(datafile)
        % Load and process data
        datafile = readtable(datafile);
        if convert_ZT
            datafile = make_ZT(datafile, 5);
        end
    end

    % Calculate hourly means across the week using NormalizedActivity
    [hourlyMeans, hourlyBinTimes] = CalculateHourlyMeans(datafile);

    % Extract ZT time from the hourly bins
    ZT_Time = mod(hour(hourlyBinTimes), 24);

    % Define the ranges for segmentation
    range_ZT_22_2 = ismember(ZT_Time, [22, 23, 0, 1, 2]);
    range_ZT_10_14 = ismember(ZT_Time, 10:14);
    range_rest = ~(range_ZT_22_2 | range_ZT_10_14);

    % Calculate means and SEMs for the three groups
    mean_ZT_22_2 = mean(hourlyMeans(range_ZT_22_2));
    mean_ZT_10_14 = mean(hourlyMeans(range_ZT_10_14));
    mean_rest = mean(hourlyMeans(range_rest));

    sem_ZT_22_2 = std(hourlyMeans(range_ZT_22_2)) / sqrt(sum(range_ZT_22_2));
    sem_ZT_10_14 = std(hourlyMeans(range_ZT_10_14)) / sqrt(sum(range_ZT_10_14));
    sem_rest = std(hourlyMeans(range_rest)) / sqrt(sum(range_rest));

    % Perform ANOVA for the three groups
    group_data = [hourlyMeans(range_ZT_22_2); hourlyMeans(range_ZT_10_14); hourlyMeans(range_rest)];
    group_labels = [repmat({'ZT 22-2'}, sum(range_ZT_22_2), 1); repmat({'ZT 10-14'}, sum(range_ZT_10_14), 1); repmat({'Rest'}, sum(range_rest), 1)];
    [p_anova, ~, ~] = anova1(group_data, group_labels, 'off');
    disp(['ANOVA p-value (ZT 22-2 vs ZT 10-14 vs Rest): ', num2str(p_anova)]);

    % Calculate means and SEMs for Lights On and Lights Off
    lights_on_range = ismember(ZT_Time, 3:9);
    lights_off_range = ismember(ZT_Time, 15:21);
    meanLightsOn = mean(hourlyMeans(lights_on_range));
    meanLightsOff = mean(hourlyMeans(lights_off_range));
    semLightsOn = std(hourlyMeans(lights_on_range)) / sqrt(sum(lights_on_range));
    semLightsOff = std(hourlyMeans(lights_off_range)) / sqrt(sum(lights_off_range));

    % Perform two-sample t-tests for Lights On and Lights Off
    [~, p2] = ttest2(hourlyMeans(lights_on_range), hourlyMeans(lights_off_range));
    disp(['Two-sample t-test p-value (Lights On [ZT 3-9] vs Lights Off [ZT 15-21]): ', num2str(p2)]);

    % Calculate means and SEMs for ZT 0-11 vs ZT 12-23
    range_ZT_0_11 = ismember(ZT_Time, 0:11);
    range_ZT_12_23 = ismember(ZT_Time, 12:23);
    mean_ZT_0_11 = mean(hourlyMeans(range_ZT_0_11));
    mean_ZT_12_23 = mean(hourlyMeans(range_ZT_12_23));
    sem_ZT_0_11 = std(hourlyMeans(range_ZT_0_11)) / sqrt(sum(range_ZT_0_11));
    sem_ZT_12_23 = std(hourlyMeans(range_ZT_12_23)) / sqrt(sum(range_ZT_12_23));

    % Perform two-sample t-test for ZT 0-11 vs ZT 12-23
    [~, p3] = ttest2(hourlyMeans(range_ZT_0_11), hourlyMeans(range_ZT_12_23));
    disp(['Two-sample t-test p-value (ZT 0-11 vs ZT 12-23): ', num2str(p3)]);

    % Plot the results
    figure;

    % Subplot: ZT 22-2 vs ZT 10-14 vs Rest of Day
    subplot(1, 3, 1);
    hold on;
    b1 = bar([1, 2, 3], [mean_ZT_22_2, mean_ZT_10_14, mean_rest], 'FaceColor', 'flat');
    b1.CData(1,:) = [1, 0, 0];   % Red for ZT 22-2
    b1.CData(2,:) = [0, 1, 0];   % Green for ZT 10-14
    b1.CData(3,:) = [0, 0, 1];   % Blue for Rest of the Day
    errorbar([1, 2, 3], [mean_ZT_22_2, mean_ZT_10_14, mean_rest], ...
             [sem_ZT_22_2, sem_ZT_10_14, sem_rest], ...
             'k', 'LineWidth', 1.5, 'LineStyle', 'none');
    ylabel('NormalizedActivity', 'FontSize', 16);
    xticks([1, 2, 3]);
    xticklabels({'22-2', '10-14', 'Rest of Day'});
    set(gca, 'FontSize', 14);
    title('Peak Times', 'FontSize', 16);
    y_max_1 = max([mean_ZT_22_2 + sem_ZT_22_2, mean_ZT_10_14 + sem_ZT_10_14, mean_rest + sem_rest]) * 1.1;
    ylim([0, y_max_1]);

    % Subplot: Lights On vs Lights Off
    subplot(1, 3, 2);
    hold on;
    b2 = bar([1, 2], [meanLightsOn, meanLightsOff], 'FaceColor', 'flat');
    b2.CData(1,:) = [1, 0, 0];   % Red for Lights On
    b2.CData(2,:) = [0, 1, 0];   % Green for Lights Off
    errorbar([1, 2], [meanLightsOn, meanLightsOff], ...
             [semLightsOn, semLightsOff], 'k', 'LineWidth', 1.5, 'LineStyle', 'none');
    ylabel('NormalizedActivity', 'FontSize', 16);
    xticks([1, 2]);
    xticklabels({'Lights On', 'Lights Off'});
    set(gca, 'FontSize', 14);
    title('Diurnality Test - Excluding Transition', 'FontSize', 16);
    y_max_2 = max([meanLightsOn + semLightsOn, meanLightsOff + semLightsOff]) * 1.1;
    ylim([0, y_max_2]);

    % Subplot: ZT 0-11 vs ZT 12-23
    subplot(1, 3, 3);
    hold on;
    b3 = bar([1, 2], [mean_ZT_0_11, mean_ZT_12_23], 'FaceColor', 'flat');
    b3.CData(1,:) = [1, 0, 0];   % Red for ZT 0-11
    b3.CData(2,:) = [0, 0, 1];   % Blue for ZT 12-23
    errorbar([1, 2], [mean_ZT_0_11, mean_ZT_12_23], ...
             [sem_ZT_0_11, sem_ZT_12_23], 'k', 'LineWidth', 1.5, 'LineStyle', 'none');
    ylabel('NormalizedActivity', 'FontSize', 16);
    xticks([1, 2]);
    xticklabels({'0-11', '12-23'});
    set(gca, 'FontSize', 14);
    title('ZT 0-11 vs ZT 12-23', 'FontSize', 16);
    y_max_3 = max([mean_ZT_0_11 + sem_ZT_0_11, mean_ZT_12_23 + sem_ZT_12_23]) * 1.1;
    if p3 < 0.05
        plot([1, 2], [y_max_3, y_max_3], '-k', 'LineWidth', 1.5);
        plot([1 1], [y_max_3 * 0.95, y_max_3], '-k', 'LineWidth', 1.5);
        plot([2 2], [y_max_3 * 0.95, y_max_3], '-k', 'LineWidth', 1.5);
        text(1.5, y_max_3 * 1.05, '*', 'FontSize', 20, 'HorizontalAlignment', 'center');
    end
    ylim([0, y_max_3]);

    sgtitle(['Circadian Running Analysis: ', name], 'FontSize', 20);

    save_filename = 'CircadianAnalysis.png'; % Construct the filename
    saveas(gcf, fullfile(save_directory, save_filename)); % Save the figure
end