function CompareLightingConditions(datafile300_week1, datafile1000_week1, datafile1000_week4, convert_ZT)
    % Load and process data for 300 lux condition (week 1)
    data300_week1 = readtable(datafile300_week1);
    if convert_ZT
        data300_week1 = make_ZT(data300_week1, 5);
    end
    hourlySum300_week1 = CalculateHourlySum(data300_week1);

    % Load and process data for 1000 lux condition (week 1)
    data1000_week1 = readtable(datafile1000_week1);
    if convert_ZT
        data1000_week1 = make_ZT(data1000_week1, 5);
    end
    hourlySum1000_week1 = CalculateHourlySum(data1000_week1);

    % Load and process data for 1000 lux condition (week 4)
    data1000_week4 = readtable(datafile1000_week4);
    if convert_ZT
        data1000_week4 = make_ZT(data1000_week4, 5);
    end
    hourlySum1000_week4 = CalculateHourlySum(data1000_week4);

    % Perform two-sample t-tests
    [h1, p1] = ttest2(hourlySum300_week1, hourlySum1000_week1);
    disp(['Two-sample t-test p-value (300 Lux Week1 vs 1000 Lux Week1): ', num2str(p1)]);
    [h2, p2] = ttest2(hourlySum300_week1, hourlySum1000_week4);
    disp(['Two-sample t-test p-value (300 Lux Week1 vs 1000 Lux Week4): ', num2str(p2)]);

    % Calculate means and SEMs
    mean300_week1 = mean(hourlySum300_week1);
    sem300_week1 = std(hourlySum300_week1) / sqrt(numel(hourlySum300_week1));
    mean1000_week1 = mean(hourlySum1000_week1);
    sem1000_week1 = std(hourlySum1000_week1) / sqrt(numel(hourlySum1000_week1));
    mean1000_week4 = mean(hourlySum1000_week4);
    sem1000_week4 = std(hourlySum1000_week4) / sqrt(numel(hourlySum1000_week4));

    % Plot bar chart with error bars
    figure;
    hold on;
    b = bar([1, 2, 3], [mean300_week1, mean1000_week1, mean1000_week4], 'FaceColor', 'flat');
    b.CData(1,:) = [0.2, 0.2, 0.5]; % Color for 300 Lux Week 1
    b.CData(2,:) = [0.5, 0.2, 0.2]; % Color for 1000 Lux Week 1
    b.CData(3,:) = [0.5, 0.2, 0.2]; % Color for 1000 Lux Week 4
    errorbar([1, 2, 3], [mean300_week1, mean1000_week1, mean1000_week4], ...
             [sem300_week1, sem1000_week1, sem1000_week4], ...
             'k', 'LineWidth', 1.5, 'LineStyle', 'none');
    
    ylabel('Mean of Hourly Sum of SelectedPixelDifference');
    xticks([1, 2, 3]);
    xticklabels({'300 Lux Week 1', '1000 Lux Week 1', '1000 Lux Week 4'});
    title('Comparison of Movement');

    % Add asterisks for statistical significance if p < 0.05
    y_max = max([mean300_week1 + sem300_week1, mean1000_week1 + sem1000_week1, mean1000_week4 + sem1000_week4]) * 1.1;
    
    % Add asterisk and lines for first comparison (300 Lux Week 1 vs 1000 Lux Week 1)
    if p1 < 0.05
        plot([1, 2], [y_max, y_max], '-k', 'LineWidth', 1.5);
        plot([1 1], [y_max * 0.95, y_max], '-k', 'LineWidth', 1.5); % Left notch
        plot([2 2], [y_max * 0.95, y_max], '-k', 'LineWidth', 1.5); % Right notch
        text(1.5, y_max * 1.05, '*', 'FontSize', 20, 'HorizontalAlignment', 'center');
    end
    
    % Add asterisk and lines for second comparison (300 Lux Week 1 vs 1000 Lux Week 4)
    if p2 < 0.05
        y_max2 = y_max * 1.15;
        plot([1, 3], [y_max2, y_max2], '-k', 'LineWidth', 1.5);
        plot([1 1], [y_max2 * 0.95, y_max2], '-k', 'LineWidth', 1.5); % Left notch
        plot([3 3], [y_max2 * 0.95, y_max2], '-k', 'LineWidth', 1.5); % Right notch
        text(2, y_max2 * 1.05, '*', 'FontSize', 20, 'HorizontalAlignment', 'center');
        y_max = y_max2; % Update y_max to the new height
    end
    
    ylim([0, y_max * 1.3]); % Adjust the y-axis limits to accommodate the significance lines and asterisks
    hold off;
end
