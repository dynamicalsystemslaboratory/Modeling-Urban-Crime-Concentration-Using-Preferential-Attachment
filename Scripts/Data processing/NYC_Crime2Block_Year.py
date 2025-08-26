# Import packages

import geopandas as gpd
import pandas as pd
from shapely.geometry import Point
import numpy as np

# Import Crimes file and clean
df_crimes = pd.read_csv("C:/Users/.../NYPD_Complaint_Data_Historic.csv",
                        usecols=[1, 7, 8, 10, 27, 28], low_memory=False)
df_crimes['OFNS_DESC'] = df_crimes['OFNS_DESC'].replace("(null)", "N/A")  # Replace (null) with N/A
df_crimes['KY_CD'] = df_crimes['KY_CD'].replace("(null)", "N/A")  # Replace (null) with N/A
df_crimes['PD_DESC'] = df_crimes['PD_DESC'].replace("(null)", "N/A")  # Replace (null) with N/A
df_crimes['Offense'] = (df_crimes['KY_CD'].astype(str) + '.' + df_crimes['OFNS_DESC'].astype(str) + '.'
                        + df_crimes['PD_DESC'].astype(str))
df_crimes = df_crimes.drop(columns=['OFNS_DESC', 'KY_CD', 'PD_DESC'])

##Make the column a date and get all the years
df_crimes["Year"] = pd.to_datetime(df_crimes["CMPLNT_FR_DT"], errors='coerce').dt.year
df_crimes = df_crimes[df_crimes["Year"].notna() & (df_crimes["Year"] >= 2006)]
All_Years = np.unique(df_crimes["Year"])


# Import Streets file and clean
df_Block = gpd.read_file(
    'C:/Users/.../NYBlock2020/tl_2020_36_tabblock20.shp')
nyc_county_fips = ["061", "047", "081", "005", "085"] # List of NYC county FIPS codes
df_Block = df_Block[df_Block["COUNTYFP20"].isin(nyc_county_fips)] # Filter the dataframe
df_Block = df_Block.iloc[:, [4, -1]]
df_Block = df_Block.sort_values(by=['GEOID20'], ascending=[True])  # Sort by GEOID
df_Block.reset_index(drop=True, inplace=True)  # Reset indexing

# Organize df_Block
projected_crs = "EPSG:2263"  # New York State Plane (meters)
df_Block = df_Block.to_crs(projected_crs) # Reproject dataframe

# Create new df for crime distribution
unique_offenses = sorted(df_crimes['Offense'].unique())  # Sort all possible offenses
columns = list(unique_offenses)  # df_Crime_Dist columns

df_Crime_Dist = pd.DataFrame(0, columns=columns, index=df_Block.index)  # Create the dataframe
df_Crime_Dist[unique_offenses] = df_Crime_Dist[unique_offenses].astype(int)  # Ensure correct types

## Add years as index
new_index = pd.MultiIndex.from_product(
    [np.append(df_Block.GEOID20, 'Unknown').astype('str'), All_Years],
    names=["GEOID", "Year"]
)
df_Crime_Dist = df_Crime_Dist.reindex(new_index, method=None).infer_objects().fillna(0)


# Crime to Block function
def crime_locator(longitude, latitude):
    # If location is missing or set to 0,0
    if pd.isna(longitude) or pd.isna(latitude) or longitude == 0 or latitude == 0:
        return 'Unknown'

    # Convert lat, lon to a Point object and reproject it to the same CRS as the shapefile
    point = Point(longitude, latitude)
    point = gpd.GeoSeries([point], crs="EPSG:4326")  # Define CRS of the point (lon, lat)
    point = point.to_crs(projected_crs)  # Reproject the point to match the map

    # Calculate the distance between the point and each group and get the index of the closest group
    block_dist = df_Block.geometry.distance(point[0])
    block_dist.index = df_Block.index  # Set the index to be the same as df_Block

    # Get the closest street (the smallest distance)
    geoid_index = block_dist.idxmin()
    geoid = df_Block.iloc[geoid_index]['GEOID20']

    return str(geoid)

# Number of crimes
total_iterations = len(df_crimes)
counter = 0


# Iterate over the rows of df_crimes
for index, row in df_crimes.iterrows():
    print(f"Iteration {counter + 1} out of {total_iterations}")
    # Use the crime_locator function to get the geoid
    Block_name = crime_locator(row['Longitude'], row['Latitude'])
    year = row['Year']
    offense = row['Offense']  # Get the offense type
    df_Crime_Dist.at[(Block_name, year), offense] += 1  # Update the count for the offense for the given Block and a given year

    counter += 1

df_Crime_Dist.to_csv('NYC_df_Crime_Dist_Block_Annual.csv', index=True)