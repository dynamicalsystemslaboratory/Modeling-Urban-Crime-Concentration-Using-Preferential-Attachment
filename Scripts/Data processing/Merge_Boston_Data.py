# Import packages

import pandas as pd

# Import crime files
df_crimes_2015 = pd.read_csv("C:/Users/.../Crime Incident Reports - 2015.csv", low_memory=False)
df_crimes_2016 = pd.read_csv("C:/Users/.../Crime Incident Reports - 2016.csv", low_memory=False)
df_crimes_2017 = pd.read_csv("C:/Users/.../Crime Incident Reports - 2017.csv", low_memory=False)
df_crimes_2018 = pd.read_csv("C:/Users/.../Crime Incident Reports - 2018.csv", low_memory=False)
df_crimes_2019 = pd.read_csv("C:/Users/.../Crime Incident Reports - 2019.csv", low_memory=False)
df_crimes_2020 = pd.read_csv("C:/Users/.../Crime Incident Reports - 2020.csv", low_memory=False)
df_crimes_2021 = pd.read_csv("C:/Users/.../Crime Incident Reports - 2021.csv", low_memory=False)
df_crimes_2022 = pd.read_csv("C:/Users/.../Crime Incident Reports - 2022.csv", low_memory=False)
df_crimes_2023on = pd.read_csv("C:/Users/.../Crime Incident Reports - 2023 to Present.csv", low_memory=False)


# Merge crime files
df_Crime_Dist = pd.concat([df_crimes_2015, df_crimes_2016, df_crimes_2017, df_crimes_2018, df_crimes_2019, df_crimes_2020, df_crimes_2021, df_crimes_2022, df_crimes_2023on], axis=0, ignore_index=True)
df_Crime_Dist.to_csv('Boston Crime Incident Reports - 2015 - Present.csv', index=True)