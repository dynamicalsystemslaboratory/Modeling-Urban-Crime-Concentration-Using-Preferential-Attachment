% Remove specific blocks from the data

%% Load the dataset
city = input('Enter the city name: ', 's');
tablename = sprintf('%s_df_Crime_Dist_Block_Annual_Final.csv', city);

% Real data
T = readtable(tablename, 'VariableNamingRule', 'preserve');

%% Blocks to remove
% Remove = {'360050224032001'};
Remove = {};

%% Cleaning the dataset
T.Properties.VariableNames{2} = 'Year'; % Uniform nameing

Offenses = T.Properties.VariableNames(3:end);  % Get offenses names
Num_Offenses = length(Offenses);    % Number of offenses

T = T(~isnan(T.GEOID), :);  % Remove NaN blocks
T.GEOID = arrayfun(@num2str, T.GEOID, 'UniformOutput', false);  % Convert block numbers to strings

for i = 1:length(Remove)
    rows2remove = find(strcmp(T.GEOID, Remove{i}));
    T(rows2remove, :) = [];
end

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
    end

    Processed_Data{yearIdx}.(sprintf('Year_%d', All_Years(yearIdx))) = Crimes_Per_Type_T;    % Store data

end

%% Save data
for yearIdx = 2:length(All_Years)
    LastyearField = sprintf('Year_%d', All_Years(yearIdx - 1)); % Generate the last year part of the variable name
    CurrentYearField = sprintf('Year_%d', All_Years(yearIdx)); % Generate the current year part of the variable name
    for crimeIdx = 1:Num_Offenses
        %% Getting the data
        offenseField = sprintf('%s', matlab.lang.makeValidName(Offenses{crimeIdx})); % Generate the offense part of the variable name
        
        Total_Crime_T0 = Processed_Data{1, yearIdx - 1}.(LastyearField){1, crimeIdx}.(offenseField).Total_Crime_T;    % Get total degree up to year T - 1 including
        Added_Crimes_T = Processed_Data{1, yearIdx}.(CurrentYearField){1, crimeIdx}.(offenseField).Added_Crimes;    % Get added links durnig year T
        
        Data = [Total_Crime_T0, Added_Crimes_T];    % Data

        if isempty(Remove)
            save(sprintf('All_PA_Data_%s_%s_%s.mat', offenseField, CurrentYearField, city), 'Data');
        else
            save(sprintf('PA_Data_mblock_%s_%s_%s.mat', offenseField, CurrentYearField, city), 'Data');
        end

    end
end
