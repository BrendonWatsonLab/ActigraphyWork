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

    % Segment the hourly means into two groups: ZT 10-14 vs. the rest of the day
    range1 = ismember(ZT_Time, 10:14); % ZT 10 to ZT 14
    range2 = ~range1; % All other ZT times

    % Segment the hourly means into two groups: ZT 0-9 vs. ZT 15-24 (excluding ZT 10-14)
    lights_on_range = ismember(ZT_Time, 0:9); % ZT 0 to ZT 9
    lights_off_range = ismember(ZT_Time, 15:23); % ZT 15 to ZT 24
    excl_range = ismember(ZT_Time, 10:14); % Excluded range
    lights_on_range = lights_on_range & ~excl_range;
    lights_off_range = lights_off_range & ~excl_range;

    % Calculate means and SEMs
    meanRange1 = mean(hourlyMeans(range1));
    meanRange2 = mean(hourlyMeans(range2));
    semRange1 = std(hourlyMeans(range1)) / sqrt(sum(range1));
    semRange2 = std(hourlyMeans(range2)) / sqrt(sum(range2));

    meanLightsOn = mean(hourlyMeans(lights_on_range));
    meanLightsOff = mean(hourlyMeans(lights_off_range));
    semLightsOn = std(hourlyMeans(lights_on_range)) / sqrt(sum(lights_on_range));
    semLightsOff = std(hourlyMeans(lights_off_range)) / sqrt(sum(lights_off_range));

    % Perform two-sample t-tests
    [h1, p1] = ttest2(hourlyMeans(range1), hourlyMeans(range2));
    disp(['Two-sample t-test p-value (ZT 10-14 vs Rest): ', num2str(p1)]);
    [h2, p2] = ttest2(hourlyMeans(lights_on_range), hourlyMeans(lights_off_range));
    disp(['Two-sample t-test p-value (Lights On [ZT 0-9] vs Lights Off [ZT 15-23]): ', num2str(p2)]);

    % Plotting the results
    figure;

    % First subplot: ZT 10-14 vs Rest of Day
    subplot(2, 1, 1);
    hold on;
    b1 = bar([1, 2], [meanRange1, meanRange2], 'FaceColor', 'flat');
    b1.CData(1,:) = [0.2, 0.2, 0.5]; % Color for ZT 10-14
    b1.CData(2,:) = [0.5, 0.2, 0.2]; % Color for Rest
    errorbar([1, 2], [meanRange1, meanRange2], [semRange1, semRange2], ...
             'k', 'LineWidth', 1.5, 'LineStyle', 'none');
    ylabel('Mean of Hourly Sum of SelectedPixelDifference');
    xticks([1, 2]);
    xticklabels({'ZT 10-14', 'Rest of Day'});
    title('Comparison of Movement: ZT 10-14 vs Rest of Day');

    % Add asterisks for statistical significance if p < 0.05
    y_max = max([meanRange1 + semRange1, meanRange2 + semRange2]) * 1.1;
    if p1 < 0.05
        plot([1, 2], [y_max, y_max], '-k', 'LineWidth', 1.5);
        plot([1 1], [y_max * 0.95, y_max], '-k', 'LineWidth', 1.5); % Left notch
        plot([2 2], [y_max * 0.95, y_max], '-k', 'LineWidth', 1.5); % Right notch
        text(1.5, y_max * 1.05, '*', 'FontSize', 20, 'HorizontalAlignment', 'center');
    end
    ylim([0, y_max * 1.3]);
    hold off;

    % Second subplot: Lights On (ZT 0-9) vs Lights Off (ZT 15-23)
    subplot(2, 1, 2);
    hold on;
    b2 = bar([1, 2], [meanLightsOn, meanLightsOff], 'FaceColor', 'flat');
    b2.CData(1,:) = [0.2, 0.2, 0.5]; % Color for Lights On
    b2.CData(2,:) = [0.5, 0.2, 0.2]; % Color for Lights Off
    errorbar([1, 2], [meanLightsOn, meanLightsOff], [semLightsOn, semLightsOff], ...
             'k', 'LineWidth', 1.5, 'LineStyle', 'none');
    ylabel('Mean of Hourly Sum of SelectedPixelDifference');
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

    % Add overall title for the figure
    sgtitle(['Circadian Running Analysis: ', name]);
end