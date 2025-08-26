# Import packages

import pandas as pd

# Import crime files
df_crimes_2010 = pd.read_csv("C:/Users/.../Crime Data from 2010 to 2019.csv", low_memory=False)
df_crimes_2020 = pd.read_csv("C:/Users/.../Crime Data from 2020 to Present.csv", low_memory=False)

# Merge crime files
df_Crime_Dist = pd.concat([df_crimes_2010, df_crimes_2020], axis=0, ignore_index=True)
df_Crime_Dist.to_csv('LA Crime Data - 2010 - Present.csv', index=True)