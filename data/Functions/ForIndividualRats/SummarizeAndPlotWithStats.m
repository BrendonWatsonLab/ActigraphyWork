function SummarizeAndPlotWithStats(datafile, convert_ZT)
    [dailyLOnSum, dailyLOffSum, uniqueDays] = LightsOnVsOff(datafile, convert_ZT);

    % Plot per day
    figure;
    subplot(2, 1, 1);
    bar(uniqueDays, [dailyLOnSum, dailyLOffSum], 'stacked');
    xlabel('Day');
    ylabel('Sum of SelectedPixelDifference');
    legend({'Lights On', 'Lights Off'});
    title('Daily Summed Movement: Lights On vs Lights Off');
    
    % Perform paired t-test
    [h, p] = ttest(dailyLOnSum, dailyLOffSum);
    disp(['Paired t-test p-value: ', num2str(p)]);
    
    % Plot total sum for all days with asterisk if significant
    totalLOnSum = sum(dailyLOnSum);
    totalLOffSum = sum(dailyLOffSum);

    subplot(2, 1, 2);
    bar(categorical({'Lights On', 'Lights Off'}), [totalLOnSum, totalLOffSum]);
    ylabel('Total Sum of SelectedPixelDifference');
    title('Total Summed Movement: Lights On vs Lights Off');
    
    % Add asterisk for statistical significance
    if p < 0.05
        hold on;
        plot([1, 2], [max([totalLOnSum, totalLOffSum]) * 1.05, max([totalLOnSum, totalLOffSum]) * 1.05], '-k', 'LineWidth', 1.5);
        text(1.5, max([totalLOnSum, totalLOffSum]) * 1.1, '*', 'FontSize', 20, 'HorizontalAlignment', 'center');
        hold off;
    end
end