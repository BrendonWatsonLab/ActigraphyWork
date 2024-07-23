function CompareLightingConditions(datafile300, datafile1000, convert_ZT)
    % Load and process data for 300 lux condition
    data300 = readtable(datafile300);
    if convert_ZT
        data300 = make_ZT(data300, 5);
    end
    hourlySum300 = CalculateHourlySum(data300);

    % Load and process data for 1000 lux condition
    data1000 = readtable(datafile1000);
    if convert_ZT
        data1000 = make_ZT(data1000, 5);
    end
    hourlySum1000 = CalculateHourlySum(data1000);

    % Perform two-sample t-test
    [h, p] = ttest2(hourlySum300, hourlySum1000);
    disp(['Two-sample t-test p-value: ', num2str(p)]);

    % Calculate means and SEMs
    mean300 = mean(hourlySum300);
    sem300 = std(hourlySum300) / sqrt(numel(hourlySum300));
    mean1000 = mean(hourlySum1000);
    sem1000 = std(hourlySum1000) / sqrt(numel(hourlySum1000));

    % Plot bar chart with error bars
    figure;
    hold on;
    b = bar([1, 2], [mean300, mean1000], 'FaceColor', 'flat');
    b.CData(1,:) = [0.2, 0.2, 0.5]; % Color for 300 Lux
    b.CData(2,:) = [0.5, 0.2, 0.2]; % Color for 1000 Lux
    errorbar([1, 2], [mean300, mean1000], [sem300, sem1000], 'k', 'LineWidth', 1.5, 'LineStyle', 'none');
    ylabel('Mean of Hourly Sum of SelectedPixelDifference');
    xticks([1, 2]);
    xticklabels({'300 Lux', '1000 Lux'});
    title('Comparison of Movement: 300 Lux vs 1000 Lux');

    % Add asterisk for statistical significance if p < 0.05
    y_max = max([mean300 + sem300, mean1000 + sem1000]) * 1.1; % Find the max height and add 10% for space above bars
    if p < 0.05
        plot([1, 2], [y_max, y_max], '-k', 'LineWidth', 1.5);
        text(1.5, y_max * 1.05, '*', 'FontSize', 20, 'HorizontalAlignment', 'center');
    end
    ylim([0, y_max * 1.2]); % Adjust the y-axis limits to accommodate the significance line and asterisk
    hold off;
end