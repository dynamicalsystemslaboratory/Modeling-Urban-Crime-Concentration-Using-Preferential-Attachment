%% Testing for preferential attachment in crimes
% Based on 
% Eisenberg, E. and Levanon, E.Y., 2003. Preferential attachment in the protein network evolution. Physical review letters, 91(13), p.138701.

%% Load the dataset
city = input('Enter the city name: ', 's');
tablename = sprintf('%s_df_Crime_Dist_Block_Annual_Final.csv', city);

% Real data
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
Cumulative_Crimes_Running_Sum_T = zeros(length(All_Blocks), Num_Offenses);    % Sum of all crimes up until year T (including!)
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

    Cumulative_Crimes_Running_Sum_T = Cumulative_Crimes_Running_Sum_T + Added_Crimes_T;  % Getting the cumulative number of crimes, including current year

    for crimeIdx = 1:Num_Offenses
        S = struct('Year', All_Years(yearIdx), 'Offense', Offenses(crimeIdx), 'Total_Crime_T', Cumulative_Crimes_Running_Sum_T(:, crimeIdx), ...
            'Added_Crimes', Added_Crimes_T(:, crimeIdx));  % Storing the data
        fieldName = matlab.lang.makeValidName(Offenses{crimeIdx});  % Offense type without spaces
        Crimes_Per_Type_T{crimeIdx}.(sprintf('%s', fieldName)) = S;   % Store data
        Annual_Crime = Added_Crimes_T(:, crimeIdx);
        offenseField = sprintf('%s', matlab.lang.makeValidName(Offenses{crimeIdx}));
        % save(sprintf('Annual_Crime_%s_%d_%s.mat', offenseField, All_Years(yearIdx), city), 'Annual_Crime');
    end

    Processed_Data{yearIdx}.(sprintf('Year_%d', All_Years(yearIdx))) = Crimes_Per_Type_T;    % Store data

end

%% PA calculation
ManualMode = 0;
for yearIdx = 2:length(All_Years)
    LastyearField = sprintf('Year_%d', All_Years(yearIdx - 1)); % Generate the last year part of the variable name
    CurrentYearField = sprintf('Year_%d', All_Years(yearIdx)); % Generate the current year part of the variable name
    for crimeIdx = 1:Num_Offenses
        %% Getting the data
        offenseField = sprintf('%s', matlab.lang.makeValidName(Offenses{crimeIdx})); % Generate the offense part of the variable name
        
        Total_Crime_T0 = Processed_Data{1, yearIdx - 1}.(LastyearField){1, crimeIdx}.(offenseField).Total_Crime_T;    % Get total degree up to year T - 1 including
        Added_Crimes_T = Processed_Data{1, yearIdx}.(CurrentYearField){1, crimeIdx}.(offenseField).Added_Crimes;    % Get added links durnig year T
        
        Data = [Total_Crime_T0, Added_Crimes_T];    % Data
        
        %% The algorithm
        [alpha, Cumulative_Pi, best_cutoff] = Preferential_Attachment(Data, ManualMode);
        
        if ManualMode == 1
            disp('Press any key to continue...');
            pause;  % Wait for a key press
            close(gcf); % Close the figure
        end

        %% Storing the variables
        Processed_Data{1, yearIdx}.(CurrentYearField){1, crimeIdx}.(offenseField).Cumulative_Pi = Cumulative_Pi;    % Storing the cumulative Pi
        Processed_Data{1, yearIdx}.(CurrentYearField){1, crimeIdx}.(offenseField).alpha = alpha;    % Storing alpha
        Processed_Data{1, yearIdx}.(CurrentYearField){1, crimeIdx}.(offenseField).cutoff = best_cutoff;    % Storing cutoff
    end
end

%% Plot alphas
Alphas = zeros(Num_Offenses, length(All_Years) - 1);
for crimeIdx = 1:Num_Offenses
    offenseField = sprintf('%s', matlab.lang.makeValidName(Offenses{crimeIdx}));
    figure(crimeIdx);  % Create a figure
    set(gcf, 'Position', get(0, 'Screensize'));  % Set figure to fullscreen
    set(gca, 'XScale', 'log', 'YScale', 'log');  
    hold on
    
    %% Main - Kappa plot
    for yearIdx = 2:length(All_Years)
        CurrentYearField = sprintf('Year_%d', All_Years(yearIdx)); % Generate the current year part of the variable name
        Cumulative_Pi_current = Processed_Data{1, yearIdx}.(CurrentYearField){1, crimeIdx}.(offenseField).Cumulative_Pi;
        
        plot(Cumulative_Pi_current(:, 1), Cumulative_Pi_current(:, 2), 'o', 'LineWidth', 1.5);

    end

    title(['Measuring Preferential Attachment - ', offenseField]);
    xlabel('k, number of crimes at the beginning of the year');
    ylabel('\kappa(k), Cumulative function of crimes during the year');
    legend(arrayfun(@(y) sprintf('%d', y), All_Years(2:end), 'UniformOutput', false), 'Location', 'northwest');
    grid on;

    %% Inset - Alpha plot
    alphas = zeros(1, length(All_Years) - 1);   % Initialize an alpha vector
    cutoffs = zeros(1, length(All_Years) - 1);   % Initialize an cutoff vector
    years = All_Years(2:end);   % Relevant years

    for yearIdx = 2:length(All_Years)
        CurrentYearField = sprintf('Year_%d', All_Years(yearIdx)); % Generate the current year part of the variable name
        alphas(yearIdx - 1) = Processed_Data{1, yearIdx}.(CurrentYearField){1, crimeIdx}.(offenseField).alpha;  % Get current alpha
        cutoffs(yearIdx - 1) = Processed_Data{1, yearIdx}.(CurrentYearField){1, crimeIdx}.(offenseField).cutoff;  % Get current cutoff
    end
    
    alphas = alphas - 1;
    save(sprintf('Alpha_%s_%d-%d_%s.mat', offenseField, All_Years(1),  All_Years(end), city), 'alphas');
    % save(sprintf('Cutoff_%s_%d-%d_%s.mat', offenseField, All_Years(1),  All_Years(end), city), 'cutoffs');

    insetPos = [0.65, 0.25, 0.2, 0.2];  % Position and (relative) dimensions of the inset 
    insetAxes = axes('Position', insetPos);  % Create the inset
    hold(insetAxes, 'on');  % Plot multiple graphs in the inset
    
    Alphas(crimeIdx, :) = alphas; 

    plot(years, alphas, '-o', 'LineWidth', 1.5, 'MarkerSize', 6);    % Plot alphas
    
    xlabel('Year');
    ylabel('\alpha');
    ylim([min(Alphas(crimeIdx, :))*0.9, max(Alphas(crimeIdx, :))*1.1]);
    
    hold(insetAxes, 'off');
    hold off
end












