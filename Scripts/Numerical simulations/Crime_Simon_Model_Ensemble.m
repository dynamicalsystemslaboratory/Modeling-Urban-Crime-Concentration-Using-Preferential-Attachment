% Modeling crimes on a block level using Simon model (preferential attachment)

%% Parameters
Total_Annual_Crime = 5000; % Total number of crimes in a year
beta = 0.1;    % Probability that an empty block gains its first crime
alpha = 0.9;    % Preferential attachment exponent
num_sim = 1000; % Number of repetitions 

%% Simulation
counts = zeros(num_sim, Total_Annual_Crime);    % Crime counts
parfor sim = 1:num_sim
    
    [dist_counts] = Crime_Simon_Model(Total_Annual_Crime, beta, alpha);
    
    counts(sim, :) = dist_counts(2, :);
    
    % Print progress
    fprintf('Progress: %d/%d completed\n', sim, num_sim);
end

values = 1:Total_Annual_Crime;   % Possible number of crimes per block
Meancounts = mean(counts, 1);  % PMF
errors = std(counts, 0, 1);  % Standard deviations
lowerErrors = min(errors, Meancounts - eps);

%% Plotting
zero_vals = find(Meancounts > 0);
plot(values(zero_vals), Meancounts(zero_vals))
errorbar(values(zero_vals), Meancounts(zero_vals), lowerErrors(zero_vals), errors(zero_vals), 'o-', 'LineWidth', 1.5);
xlabel('Crime Count');
ylabel('Blocks Count');
grid on;
set(gca, 'XScale', 'log', 'YScale', 'log')