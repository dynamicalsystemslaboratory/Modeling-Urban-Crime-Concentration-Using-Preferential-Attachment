# Import packages

import geopandas as gpd
import pandas as pd
from shapely.geometry import Point
import numpy as np

# Import Crimes file and clean
df_crimes = pd.read_csv("C:/Users/.../LA Crime Data - 2010 - Present.csv",
                        usecols=[3, 10, 27, 28], low_memory=False)
df_crimes['Crm Cd Desc'] = df_crimes['Crm Cd Desc'].replace("(null)", "N/A")  # Replace (null) with N/A

#Make the column a date and get all the years
df_crimes['DATE OCC'] = pd.to_datetime(df_crimes['DATE OCC'], format='%m/%d/%Y %I:%M:%S %p')
df_crimes["Year"] = pd.to_datetime(df_crimes["DATE OCC"]).dt.year
All_Years = np.unique(df_crimes["Year"])


# Import Streets file and clean
df_Block = gpd.read_file(
    'C:/Users/.../CABlock2020/tl_2020_06_tabblock20.shp')
LA_county_fips = ["037"] # List of NYC county FIPS codes
df_Block = df_Block[df_Block["COUNTYFP20"].isin(LA_county_fips)] # Filter the dataframe
df_Block = df_Block.iloc[:, [4, -1]]
df_Block = df_Block.sort_values(by=['GEOID20'], ascending=[True])  # Sort by GEOID
df_Block.reset_index(drop=True, inplace=True)  # Reset indexing

# Organize df_Block
projected_crs = "EPSG:2230"  # LA Plane (meters)
df_Block = df_Block.to_crs(projected_crs) # Reproject dataframe

# Create new df for crime distribution
unique_offenses = sorted(df_crimes['Crm Cd Desc'].unique())  # Sort all possible offenses
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
    Block_name = crime_locator(row['LON'], row['LAT'])
    year = row['Year']
    offense = row['Crm Cd Desc']  # Get the offense type
    df_Crime_Dist.at[(Block_name, year), offense] += 1  # Update the count for the offense for the given Block and a given year

    counter += 1

df_Crime_Dist.to_csv('LA_df_Crime_Dist_Block_Annual.csv', index=True)