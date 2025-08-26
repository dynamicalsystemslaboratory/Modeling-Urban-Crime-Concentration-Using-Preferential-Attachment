function [alpha, Cumulative_Pi, best_cutoff] = Preferential_Attachment(Data , ManualMode)

Data(Data(:,1) == 0, :) = []; % Removing zero degrees!!!! The PA is calculated for non-zero blocks

if length(unique(Data(:, 1))) > 15
    %% Getting the data
    [sorted_degrees, ~, originalIdx] = unique(Data(:, 1));   % Get unique degrees and their positions
    Pi = [sorted_degrees, accumarray(originalIdx, Data(:,2)) ./ accumarray(originalIdx, 1)];  % Compute averages
    Pi(:, 2) = Pi(:, 2)/sum(Pi(:, 2));  % Normalize

    Cumulative_Pi = [Pi(:, 1), cumsum(Pi(:, 2))];  % Calculating the cumulative

    %% Calculating alpha
    log_degree = log(Cumulative_Pi(:, 1));  
    log_prob = log(Cumulative_Pi(:, 2));  
   
    best_rss = inf;
    best_cutoff = NaN;
    best_beta = [];
       
    for cutoff_pos = 10:(length(log_degree) - 5)
        cutoff = log_degree(cutoff_pos);
        Z = [ones(size(log_degree)), log_degree, max(0, log_degree - cutoff)];
        beta = Z \ log_prob;
        pred = Z * beta;
        rss = sum((log_prob - pred).^2);
        
        if rss < best_rss
            best_rss = rss; % Update best rss
            best_cutoff = cutoff_pos;   % Store the cutoff
            alpha = beta(2);  % Store the first slope
            best_beta = beta;
        end
    end

    if best_cutoff == 10
        best_cutoff = length(log_degree);
        Linear_Model = fitlm(log_degree, log_prob);
        alpha = Linear_Model.Coefficients.Estimate(2);
        best_pred = predict(Linear_Model, log_degree);
    else
        % Recalculate best_pred using best_beta and best_cutoff
        cutoff = log_degree(best_cutoff);
        Z = [ones(size(log_degree)), log_degree, max(0, log_degree - cutoff)];
        best_pred = Z * best_beta;
    end
    
    if ManualMode == 1
    %% Plotting
    figure;
    plot(log_degree, log_prob, 'ko', 'MarkerFaceColor', 'k', 'DisplayName', 'Data');
    hold on;
    plot(log_degree, best_pred, 'r-', 'LineWidth', 2, 'DisplayName', 'Best Fit');
    xline(log_degree(best_cutoff), 'b--', 'DisplayName', 'Best Cutoff');
    xlabel('log(Degree)');
    ylabel('log(Cumulative P_i)');
    legend('show', 'Location', 'northwest');
    title(sprintf('Preferential Attachment Fit (\\alpha = %.2f)', alpha));
    grid on;
    set(gcf, 'Position', get(0, 'Screensize'));  % Set figure to fullscreen
    hold off
    end

else
    error('Not enough data');
end

end
