%% Ask for city name (preserve casing and spaces)
city = input('Enter the city name (same as used in classification): ', 's');

%% Construct variable and filenames
matfile = sprintf('categorized_offenses_%s.mat', city);
tablename = sprintf('%s_df_Crime_Dist_Block_Annual.csv', city);

%% Load offense classification
load(matfile, 'Violent_Crime', 'Property_Crime');

%% Load original crime table
T = readtable(tablename, 'VariableNamingRule', 'preserve');
T = T(~isnan(T{:,1}), :);
Offenses = T.Properties.VariableNames(3:end);  % Get offense column names

%% Initialize aggregate category columns
T.Violent_Crime = zeros(height(T),1);
T.Property_Crime = zeros(height(T),1);

%% Helper function to sum selected columns
sum_columns = @(tbl, vars) sum(tbl{:, ismember(tbl.Properties.VariableNames, vars)}, 2, 'omitnan');

%% Aggregate values for each category
T.Violent_Crime = sum_columns(T, Violent_Crime);
T.Property_Crime = sum_columns(T, Property_Crime);
colsToRemove = 3:(length(Offenses) + 2);
T(:, colsToRemove) = [];

%% Save the aggregated table
out_filename = sprintf('%s_df_Crime_Dist_Block_Annual_Aggregated.csv', city);
writetable(T, out_filename);
