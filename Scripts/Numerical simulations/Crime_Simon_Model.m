function [dist_counts] = Crime_Simon_Model(Total_Annual_Crime, a, alpha)
%% First Crime
Crimes_Counters = ones(1, 1);   % Crimes per block

%% Simulation
for crime = 2:Total_Annual_Crime
    % Assign a crime to a block
    r_new = rand;   % Draw a random number
    if r_new < a    % New block
        Crimes_Counters(end + 1) = 1; %#ok<*AGROW>

    else    % Preferential attachment 
        Attachment_Probability = Crimes_Counters.^alpha;    % Get counts^alpha
        Attachment_Probability = Attachment_Probability/sum(Attachment_Probability);    % Normalize
        
        r_pa = rand;    % Draw a random number
        prob_edges = [0, cumsum(Attachment_Probability)];   % Get the probabilities partition on [0, 1]
        crime_idx = find(r_pa >= prob_edges(1:end-1) & r_pa < prob_edges(2:end)); % Find the block  
        Crimes_Counters(crime_idx) = Crimes_Counters(crime_idx) + 1;    % Update the block's crime-counter
    end
    
    % Print progress
    % fprintf('Progress: %d/%d completed\n', crime, Total_Annual_Crime);

end

%% Get crime distribution

[counts, UniqueValues] = groupcounts(Crimes_Counters');   % Specific crime distribution

dist_counts = zeros(2, Total_Annual_Crime);    % Crime distribution with all possible values
dist_counts(1, :) = 1:Total_Annual_Crime;   % Possible number of crimes per block

for i = 1:length(UniqueValues)
    dist_counts(2, UniqueValues(i)) = counts(i);  % Store counts
end

end