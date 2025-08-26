%% Lorenz Curves 

%% Load the dataset

% Real data
city = input('Enter the city name: ', 's');
tablename = sprintf('%s_df_Crime_Dist_Block_Annual_Final.csv', city);
T = readtable(tablename, 'VariableNamingRule', 'preserve');

% Synthetic data
% data = load('T1.mat');  % Load data
% T = data.T;    % Store data in T

%% Cleaning the dataset
T.Properties.VariableNames{2} = 'Year'; % Uniform nameing

Offenses = T.Properties.VariableNames(3:end);  % Get offenses names
Num_Offenses = length(Offenses);    % Number of offenses

T = T(~isnan(T.GEOID), :);  % Remove NaN blocks
T.GEOID = arrayfun(@num2str, T.GEOID, 'UniformOutput', false);  % Convert block numbers to strings
All_Blocks = unique(T.('GEOID'));  % Get all unique block names

T(T{:,2} == 2025, :) = [];  % Remove 2025
All_Years = int32(sort(unique(T.Year)));   % Getting the years 

Processed_Data = cell(1, length(All_Years));  % All data for PA test

%% Processing the dataset
for yearIdx = 1:length(All_Years)
    Crimes_Per_Type_T = cell(1, Num_Offenses);    % Dynamic calculation

    year = All_Years(yearIdx);  % Year in question
    T_this_year = T(T.Year == year, :);  % Crimes commited in the previous year
    
    T_year_blocks = T_this_year.('GEOID');    % Get blocks list for current year
    if numel(T_year_blocks) ~= numel(All_Blocks)    % Making sure blocks lists are aligned
        error('Blocks lists are not aligned!');
    end    
      
    T_current_year = T(T.Year == year, :);  % Crimes commited in the current year
    Added_Crimes_T = table2array(T_current_year(:, 3:end));   % Crimes commited in the current year

    for crimeIdx = 1:Num_Offenses
        S = struct('Year', All_Years(yearIdx), 'Offense', Offenses(crimeIdx), ...
            'Added_Crimes_T', Added_Crimes_T(:, crimeIdx));  % Storing the data
        fieldName = matlab.lang.makeValidName(Offenses{crimeIdx});  % Offense type without spaces
        Crimes_Per_Type_T{crimeIdx}.(sprintf('%s', fieldName)) = S;   % Store data
    end

    Processed_Data{yearIdx}.(sprintf('Year_%d', All_Years(yearIdx))) = Crimes_Per_Type_T;    % Store data

end

%% Lorenz curves plots 
for crimeIdx = 1:Num_Offenses
    figure(crimeIdx);  % Create a figure
    set(gcf, 'Position', get(0, 'Screensize'));  % Set figure to fullscreen
    hold on
    for yearIdx = 1:length(All_Years)
        %% Getting the data
        offenseField = sprintf('%s', matlab.lang.makeValidName(Offenses{crimeIdx})); % Generate the offense part of the variable name
        CurrentYearField = sprintf('Year_%d', All_Years(yearIdx)); % Generate the current year part of the variable name
        Added_Crimes_T = Processed_Data{1, yearIdx}.(CurrentYearField){1, crimeIdx}.(offenseField).Added_Crimes_T;    % Get total crime counts
        Total_Added_Crimes_T = sum(Added_Crimes_T);
        save(sprintf('Total_Crime_%s_%s_%s.mat', offenseField, CurrentYearField, city), 'Total_Added_Crimes_T');

        %% Plotting
        sorted_Added_Crimes = sort(Added_Crimes_T);
        N = length(sorted_Added_Crimes);
        Lorenz_crime = cumsum(sorted_Added_Crimes) / sum(sorted_Added_Crimes);  % Cumulative share
        Lorenz_block = (1:N)/ N;   % Cumulative share of population
        
        % save(sprintf('Lorenz_Crime_Share_%s_%s_%s.mat', offenseField, CurrentYearField, city), 'Lorenz_crime');
        % save(sprintf('Lorenz_Block_Share_%s_%s_%s.mat', offenseField, CurrentYearField, city), 'Lorenz_block');
    
        % Compute Gini index
        G = 1 - 2 * trapz(Lorenz_block, Lorenz_crime);
    
        % Plotting
        plot(Lorenz_block, Lorenz_crime, '-', 'LineWidth', 2, 'DisplayName',  sprintf('%s %s (G = %.3f)', Offenses{crimeIdx}, CurrentYearField, G));
    end
    
    plot([0 1], [0 1], 'k--', 'DisplayName', 'Equality Line');
    xlabel('Cumulative Share of Blocks');
    ylabel('Cumulative Share of Crimes');
    legend('Location', 'northwest');
    title(sprintf(' Lorenz Curve with Gini Index - %s', Offenses{crimeIdx}));
    grid on;
    hold off

end
