function CompareSleepDep(datafile300_week1, datafile1000_week4, datafilesleepdep, convert_ZT)
    % Load and process data for 300 lux condition (week 1)
    data300_week1 = readtable(datafile300_week1);
    if convert_ZT
        data300_week1 = make_ZT(data300_week1, 5);
    end
    hourlySum300_week1 = CalculateHourlySum(data300_week1);
    assert(isnumeric(hourlySum300_week1), 'hourlySum300_week1 should be numeric.');
    
    % Load and process data for 1000 lux condition (week 4)
    data1000_week4 = readtable(datafile1000_week4);
    if convert_ZT
        data1000_week4 = make_ZT(data1000_week4, 5);
    end
    hourlySum1000_week4 = CalculateHourlySum(data1000_week4);
    assert(isnumeric(hourlySum1000_week4), 'hourlySum1000_week4 should be numeric.');
    
    % Load and process data for sleep deprivation week
    dataSleepdep = readtable(datafilesleepdep);
    if convert_ZT
        dataSleepdep = make_ZT(dataSleepdep, 5);
    end
    hourlySumSleepdep = CalculateHourlySum(dataSleepdep);
    assert(isnumeric(hourlySumSleepdep), 'hourlySumSleepdep should be numeric.');

    % Debug information to check sizes
    disp('Size of hourlySum300_week1:');
    disp(size(hourlySum300_week1));
    disp('Size of hourlySum1000_week4:');
    disp(size(hourlySum1000_week4));
    disp('Size of hourlySumSleepdep:');
    disp(size(hourlySumSleepdep));
    
    % Perform two-sample t-tests
    [h1, p1] = ttest2(hourlySum300_week1, hourlySumSleepdep);
    disp(['Two-sample t-test p-value (300 Lux Week1 vs SleepDep): ', num2str(p1)]);
    [h2, p2] = ttest2(hourlySum1000_week4, hourlySumSleepdep);
    disp(['Two-sample t-test p-value (1000 Lux Week4 vs SleepDep): ', num2str(p2)]);
    [h3, p3] = ttest2(hourlySum300_week1, hourlySum1000_week4);
    disp(['Two-sample t-test p-value (300 Lux Week1 vs 1000 Lux Week4): ', num2str(p3)]);

    % Calculate means and SEMs
    mean300_week1 = mean(hourlySum300_week1);
    sem300_week1 = std(hourlySum300_week1) / sqrt(numel(hourlySum300_week1));
    mean1000_week4 = mean(hourlySum1000_week4);
    sem1000_week4 = std(hourlySum1000_week4) / sqrt(numel(hourlySum1000_week4));
    mean_sleepdep = mean(hourlySumSleepdep);
    sem_sleepdep = std(hourlySumSleepdep) / sqrt(numel(hourlySumSleepdep));

    % Plot bar chart with error bars
    figure;
    hold on;
    b = bar([1, 2, 3], [mean300_week1, mean1000_week4, mean_sleepdep], 'FaceColor', 'flat');
    b.CData(1,:) = [0.2, 0.2, 0.5]; % Color for 300 Lux Week 1
    b.CData(2,:) = [0.5, 0.2, 0.2]; % Color for 1000 Lux Week 4
    b.CData(3,:) = [0.2, 0.5, 0.2]; % Color for SleepDep
    errorbar([1, 2, 3], [mean300_week1, mean1000_week4, mean_sleepdep], ...
             [sem300_week1, sem1000_week4, sem_sleepdep], ...
             'k', 'LineWidth', 1.5, 'LineStyle', 'none');
    
    ylabel('Mean of Hourly Sum of SelectedPixelDifference');
    xticks([1, 2, 3]);
    xticklabels({'300 Lux Week 1', '1000 Lux Week 4', 'SleepDep'});
    title('Comparison of Movement');

    % Add asterisks for statistical significance if p < 0.05
    y_max = max([mean300_week1 + sem300_week1, mean1000_week4 + sem1000_week4, mean_sleepdep + sem_sleepdep]) * 1.1;
    
    % Add asterisk and lines for first comparison (300 Lux Week 1 vs 1000 Lux Week 4)
    if p3 < 0.05
        plot([1, 1, 2, 2], [y_max, y_max * 1.05, y_max * 1.05, y_max], '-k', 'LineWidth', 1.5);
        text(1.5, y_max * 1.1, '*', 'FontSize', 20, 'HorizontalAlignment', 'center');
    end
    
    % Add asterisk and lines for second comparison (300 Lux Week 1 vs SleepDep)
    if p1 < 0.05
        y_max2 = y_max * 1.3;
        plot([1, 1, 3, 3], [y_max2, y_max2 * 1.05, y_max2 * 1.05, y_max2], '-k', 'LineWidth', 1.5);
        text(2, y_max2 * 1.15, '*', 'FontSize', 20, 'HorizontalAlignment', 'center');
        y_max = y_max2; % Update y_max to the new height
    end

    % Add asterisk and lines for third comparison (1000 Lux Week 4 vs SleepDep)
    if p2 < 0.05
        y_max3 = y_max * 1.4;
        plot([2, 2, 3, 3], [y_max3, y_max3 * 1.05, y_max3 * 1.05, y_max3], '-k', 'LineWidth', 1.5);
        text(2.5, y_max3 * 1.15, '*', 'FontSize', 20, 'HorizontalAlignment', 'center');
        y_max = y_max3; % Update y_max to the new height
    end
    
    ylim([0, y_max * 1.3]); % Adjust the y-axis limits to accommodate the significance lines and asterisks
    hold off;
end