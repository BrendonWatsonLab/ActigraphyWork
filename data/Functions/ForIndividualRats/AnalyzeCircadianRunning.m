function AnalyzeCircadianRunning(datafile, convert_ZT, name)
    if ~istable(datafile)
        % Load and process data
        datafile = readtable(datafile);
        if convert_ZT
            datafile = make_ZT(datafile, 5);
        end
    end
    
    % Calculate hourly means across the week
    [hourlyMeans, hourlyBinTimes] = CalculateHourlyMeans(datafile);

    % Extract ZT time from the hourly bins
    ZT_Time = mod(hour(hourlyBinTimes), 24);

    % Segment the hourly means into three groups: ZT 22-2, ZT 10-14, and the rest of the times
    range_ZT_22_2 = ismember(ZT_Time, [22, 23, 0, 1, 2]); % ZT 22 to ZT 2
    range_ZT_10_14 = ismember(ZT_Time, 10:14); % ZT 10 to ZT 14
    range_rest = ~(range_ZT_22_2 | range_ZT_10_14); % All other ZTs

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
    [p_anova, tbl, stats] = anova1(group_data, group_labels, 'off');
    disp(['ANOVA p-value (ZT 22-2 vs ZT 10-14 vs Rest): ', num2str(p_anova)]);
    
    % Calculate means and SEMs for Lights On and Lights Off comparison
    lights_on_range = ismember(ZT_Time, 0:9); % ZT 0 to ZT 9
    lights_off_range = ismember(ZT_Time, 15:23); % ZT 15 to ZT 24
    excl_range = ismember(ZT_Time, 10:14); % Excluded range
    lights_on_range = lights_on_range & ~excl_range;
    lights_off_range = lights_off_range & ~excl_range;

    meanLightsOn = mean(hourlyMeans(lights_on_range));
    meanLightsOff = mean(hourlyMeans(lights_off_range));
    semLightsOn = std(hourlyMeans(lights_on_range)) / sqrt(sum(lights_on_range));
    semLightsOff = std(hourlyMeans(lights_off_range)) / sqrt(sum(lights_off_range));

    % Perform two-sample t-tests for Lights On and Lights Off comparison
    [h2, p2] = ttest2(hourlyMeans(lights_on_range), hourlyMeans(lights_off_range));
    disp(['Two-sample t-test p-value (Lights On [ZT 0-9] vs Lights Off [ZT 15-23]): ', num2str(p2)]);

    % Segment the hourly means into another two groups: ZT 0-11 vs ZT 12-23
    range_ZT_0_11 = ismember(ZT_Time, 0:11); % ZT 0 to ZT 11
    range_ZT_12_23 = ismember(ZT_Time, 12:23); % ZT 12 to ZT 23

    % Calculate means and SEMs for the new two groups
    mean_ZT_0_11 = mean(hourlyMeans(range_ZT_0_11));
    mean_ZT_12_23 = mean(hourlyMeans(range_ZT_12_23));
    sem_ZT_0_11 = std(hourlyMeans(range_ZT_0_11)) / sqrt(sum(range_ZT_0_11));
    sem_ZT_12_23 = std(hourlyMeans(range_ZT_12_23)) / sqrt(sum(range_ZT_12_23));

    % Perform two-sample t-test for ZT 0-11 vs ZT 12-23
    [h3, p3] = ttest2(hourlyMeans(range_ZT_0_11), hourlyMeans(range_ZT_12_23));
    disp(['Two-sample t-test p-value (ZT 0-11 vs ZT 12-23): ', num2str(p3)]);

    % Plotting the results
    figure;

    % First subplot: ZT 22-2 vs ZT 10-14 vs Rest of Day
    subplot(1, 3, 1);
    hold on;
    b1 = bar([1, 2, 3], [mean_ZT_22_2, mean_ZT_10_14, mean_rest], 'FaceColor', 'flat');
    b1.CData(1,:) = [0.2, 0.2, 0.5]; % Color for ZT 22-2
    b1.CData(2,:) = [0.5, 0.2, 0.2]; % Color for ZT 10-14
    b1.CData(3,:) = [0.2, 0.5, 0.2]; % Color for Rest
    errorbar([1, 2, 3], [mean_ZT_22_2, mean_ZT_10_14, mean_rest], [sem_ZT_22_2, sem_ZT_10_14, sem_rest], ...
             'k', 'LineWidth', 1.5, 'LineStyle', 'none');
    ylabel('Mean of SelectedPixelDifference');
    xticks([1, 2, 3]);
    xticklabels({'ZT 22-2', 'ZT 10-14', 'Rest of Day'});
    title('Comparison of Movement: ZT 22-2 vs ZT 10-14 vs Rest of Day');

    % Add asterisks for statistical significance if p < 0.05
    y_max = max([mean_ZT_22_2 + sem_ZT_22_2, mean_ZT_10_14 + sem_ZT_10_14, mean_rest + sem_rest]) * 1.1;
    if p_anova < 0.05
        plot([1, 2, 3], [y_max, y_max, y_max], '-k', 'LineWidth', 1.5);
        plot([1 1], [y_max * 0.95, y_max], '-k', 'LineWidth', 1.5); % Left notch
        plot([2 2], [y_max * 0.95, y_max], '-k', 'LineWidth', 1.5); % Middle notch
        plot([3 3], [y_max * 0.95, y_max], '-k', 'LineWidth', 1.5); % Right notch
        text(2, y_max * 1.05, '*', 'FontSize', 20, 'HorizontalAlignment', 'center');
    end
    ylim([0, y_max * 1.3]);
    hold off;

    % Second subplot: Lights On (ZT 0-9) vs Lights Off (ZT 15-23)
    subplot(1, 3, 2);
    hold on;
    b2 = bar([1, 2], [meanLightsOn, meanLightsOff], 'FaceColor', 'flat');
    b2.CData(1,:) = [0.2, 0.2, 0.5]; % Color for Lights On
    b2.CData(2,:) = [0.5, 0.2, 0.2]; % Color for Lights Off
    errorbar([1, 2], [meanLightsOn, meanLightsOff], [semLightsOn, semLightsOff], ...
             'k', 'LineWidth', 1.5, 'LineStyle', 'none');
    ylabel('Mean of SelectedPixelDifference');
    xticks([1, 2]);
    xticklabels({'Lights On (ZT 0-9)', 'Lights Off (ZT 15-23)'});
    title('Comparison of Movement: Lights On vs Lights Off');

    % Add asterisks for statistical significance if p < 0.05
    y_max = max([meanLightsOn + semLightsOn, meanLightsOff + semLightsOff]) * 1.1;
    if p2 < 0.05
        plot([1, 2], [y_max, y_max], '-k', 'LineWidth', 1.5);
        plot([1 1], [y_max * 0.95, y_max], '-k', 'LineWidth', 1.5); % Left notch
        plot([2 2], [y_max * 0.95, y_max], '-k', 'LineWidth', 1.5); % Right notch
        text(1.5, y_max * 1.05, '*', 'FontSize', 20, 'HorizontalAlignment', 'center');
    end
    ylim([0, y_max * 1.3]);
    hold off;

    % Third subplot: ZT 0-11 vs ZT 12-23
    subplot(1, 3, 3);
    hold on;
    b3 = bar([1, 2], [mean_ZT_0_11, mean_ZT_12_23], 'FaceColor', 'flat');
    b3.CData(1,:) = [0.2, 0.2, 0.5]; % Color for ZT 0-11
    b3.CData(2,:) = [0.5, 0.2, 0.2]; % Color for ZT 12-23
    errorbar([1, 2], [mean_ZT_0_11, mean_ZT_12_23], [sem_ZT_0_11, sem_ZT_12_23], ...
             'k', 'LineWidth', 1.5, 'LineStyle', 'none');
    ylabel('Mean of SelectedPixelDifference');
    xticks([1, 2]);
    xticklabels({'ZT 0-11', 'ZT 12-23'});
    title('Comparison of Movement: ZT 0-11 vs ZT 12-23');

    % Add asterisks for statistical significance if p < 0.05
    y_max = max([mean_ZT_0_11 + sem_ZT_0_11, mean_ZT_12_23 + sem_ZT_12_23]) * 1.1;
    if p3 < 0.05
        plot([1, 2], [y_max, y_max], '-k', 'LineWidth', 1.5);
        plot([1 1], [y_max * 0.95, y_max], '-k', 'LineWidth', 1.5); % Left notch
        plot([2 2], [y_max * 0.95, y_max], '-k', 'LineWidth', 1.5); % Right notch
        text(1.5, y_max * 1.05, '*', 'FontSize', 20, 'HorizontalAlignment', 'center');
    end
    ylim([0, y_max * 1.3]);
    hold off;

    % Add overall title for the figure
    sgtitle(['Circadian Running Analysis: ', name]);
end