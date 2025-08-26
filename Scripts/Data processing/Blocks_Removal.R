library(sf)
library(dplyr)
library(tidyr)
library(spdep)
library(maptiles)
library(ggspatial)
library(tigris)
library(lctools)


#------------------------------------------------------------ DATA ---------------------------------------
bostonBlocks_shp <- st_read(".../tl_2020_25_tabblock20.shp")
bostonBlock_crime <- read.csv(".../Boston_df_Crime_Dist_Block_Annual_Aggregated.csv")

nyBlocks_shp <- st_read(".../NYBlock2020/tl_2020_36_tabblock20.shp")
nyBlock_crime <- read.csv(".../NYC_df_Crime_Dist_Block_Annual_Aggregated.csv")

chicagoBlocks_shp <- st_read(".../Chicago/tl_2020_17_tabblock20.shp")
chicagoBlock_crime <- read.csv(".../Chicago_df_Crime_Dist_Block_Annual_Aggregated.csv")

laBlocks_shp <- st_read(".../LA/tl_2020_06_tabblock20.shp")
laBlock_crime <- read.csv(".../LA_df_Crime_Dist_Block_Annual_Aggregated.csv")


# Remove the "Unknow"
bostonBlock_crime <- bostonBlock_crime[bostonBlock_crime$GEOID != "Unknown", ]
nyBlock_crime <- nyBlock_crime[nyBlock_crime$GEOID != "Unknown", ]
chicagoBlock_crime <- chicagoBlock_crime[chicagoBlock_crime$GEOID != "Unknown", ]
laBlock_crime <- laBlock_crime[laBlock_crime$GEOID != "Unknown", ]

# Corrected boundaries without water 
bostonBlocks_noWater_shp <- st_read(".../City_of_Boston_Outline_Boundary_Water_Excluded.shp") # https://data.boston.gov/dataset/city-of-boston-outline-boundary-water-excluded  (Accessed in 08/22/2025)

chicagoBlocks_noWater_shp <- st_read(".../cityboundary.shp") #https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-City-Map/ewy2-6yfk    (Accessed in 08/22/2025)

laBlocks_noWater_shp <- st_read(".../2020_Census_Blocks.shp") #https://geohub.lacity.org/datasets/8a29319474fe44bb96152d0be8e778af_16/explore?location=33.824207%2C-118.294410%2C8.68  (Accessed in 08/22/2025)
laBlocks_noWater_shp <- laBlocks_noWater_shp[laBlocks_noWater_shp$FIP20 == "44000", ]


# Set all GEOIDs as characters
bostonBlock_crime$GEOID <- as.character(bostonBlock_crime$GEOID)
nyBlock_crime$GEOID <- as.character(nyBlock_crime$GEOID)
chicagoBlock_crime$GEOID <- as.character(chicagoBlock_crime$GEOID)
laBlock_crime$GEOID <- paste0("0", as.character(laBlock_crime$GEOID))

# Take only 2023
bostonBlock_crime <- bostonBlock_crime[bostonBlock_crime$YEAR == 2023, ]
nyBlock_crime <- nyBlock_crime[nyBlock_crime$Year == 2023, ]
chicagoBlock_crime <- chicagoBlock_crime[chicagoBlock_crime$Year == 2023, ]
laBlock_crime <- laBlock_crime[laBlock_crime$Year == 2023, ]


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------- Boston -----------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------

Block_crime <- bostonBlock_crime
Blocks_shp <- bostonBlocks_shp
Blocks_noWater_shp <- bostonBlocks_noWater_shp
Blocks_noWater_shp <- st_make_valid(Blocks_noWater_shp)


# Get the total number of crimes for each block
df <- Block_crime %>%
  select(-YEAR) %>%
  group_by(GEOID) %>%
  summarise(across(where(is.numeric), sum, na.rm = TRUE))

# Merge the Block_crime with shapefile
df <- left_join(df, Blocks_shp, by = c("GEOID" = "GEOID20"))
df <- st_as_sf(df)

# Keep only the block that intersect the noWater geometry
# Check geometries
st_crs(Blocks_noWater_shp)
st_crs(df)


if (st_crs(df) != st_crs(Blocks_noWater_shp)) {
  Blocks_noWater_shp <- st_transform(Blocks_noWater_shp, st_crs(df))
}
df <- df %>%
  filter(st_intersects(geometry, Blocks_noWater_shp, sparse = FALSE))


# Remove the areas that are just water
df <- df[df$ALAND20 > 0, ]

df <- df %>%
  select(-c(
    STATEFP20, COUNTYFP20, TRACTCE20, BLOCKCE20, NAME20, MTFCC20,
    UR20, UACE20, UATYPE20, FUNCSTAT20, INTPTLAT20, INTPTLON20, HOUSING20, POP20
  ))


df <- st_as_sf(df)


# Clean geometries ---
df_empty_geom <- df[st_is_empty(df$geometry) | is.na(df$geometry), ] 
df <- df[!st_is_empty(df$geometry) & !is.na(df$geometry), ] 

#-------------------------------------------------------------------------------
# Map for a specific crime -----------------------------------------------------

crime <- "Property_Crime"

data <- df %>%
  group_by(GEOID) %>%
  summarise(
    Total_Crime = sum(.data[[crime]], na.rm = TRUE),
    geometry = first(geometry),
    Aland20 = first(ALAND20),
    Awater = first(AWATER20)
  ) %>%
  arrange(desc(Total_Crime))

# (...) Code for plot 

# Save csv with only the blocks that belong to Boston
df_Boston <- Block_crime %>%
  filter(GEOID %in% data$GEOID)

write.csv(df_Boston, "Boston_df_Crime_Dist_Block_Annual_Final.csv", row.names = FALSE)




#--------------------------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------- NEW YORK -----------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------


#Select only crime-related columns and sum them
crime_totals <- nyBlock_crime %>%
  select(-c(GEOID, Year)) %>%  # Remove non-crime columns
  summarise(across(everything(), sum, na.rm = TRUE)) %>%  # Sum each crime column
  pivot_longer(cols = everything(), names_to = "Crime", values_to = "Total_Incidents") %>%  # Convert to long format
  arrange(desc(Total_Incidents))  # Sort by total incidents


# Get the the total number of crimes for each block
df <- nyBlock_crime %>%
  select(-Year) %>%
  group_by(GEOID) %>%
  summarise(across(where(is.numeric), sum, na.rm = TRUE))

# Merge the Block_crime with shapefile
df <- left_join(df, nyBlocks_shp, by = c("GEOID" = "GEOID20"))

df <- st_as_sf(df)


#-------------------------------------------------------------------------------
# Map for a specific crime -----------------------------------------------------

crime <- "Property_Crime"

data <- df %>%
  group_by(GEOID) %>%
  summarise(
    Total_Crime = sum(.data[[crime]], na.rm = TRUE),
    geometry = first(geometry),
    Aland20 = first(ALAND20),
    Awater = first(AWATER20)
  ) %>%
  arrange(desc(Total_Crime))

data <- st_as_sf(data)


# Remove the areas that are just water
data <- data[data$Aland20 > 0, ]


# (...) Code for plot 

# Save csv with only the blocks that belong to Boston
df_NYC <- nyBlock_crime %>%
  filter(GEOID %in% data$GEOID)

write.csv(df_NYC, "NYC_df_Crime_Dist_Block_Annual_Final.csv", row.names = FALSE)




#--------------------------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------- Chicago -----------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------

Block_crime <- chicagoBlock_crime
Blocks_shp <- chicagoBlocks_shp
Blocks_noWater_shp <- chicagoBlocks_noWater_shp
Blocks_noWater_shp <- st_make_valid(Blocks_noWater_shp)


# Get the total number of crimes for each block
df <- Block_crime %>%
  select(-Year) %>%
  group_by(GEOID) %>%
  summarise(across(where(is.numeric), sum, na.rm = TRUE))

# Merge the Block_crime with shapefile
df <- left_join(df, Blocks_shp, by = c("GEOID" = "GEOID20"))
df <- st_as_sf(df)


# Keep only the block that intersect the noWater geometry
# Check geometries
st_crs(Blocks_noWater_shp)
st_crs(df)


if (st_crs(df) != st_crs(Blocks_noWater_shp)) {
  Blocks_noWater_shp <- st_transform(Blocks_noWater_shp, st_crs(df))
}
df <- df %>%
  filter(st_intersects(geometry, Blocks_noWater_shp, sparse = FALSE))


# Remove the areas that are just water
df <- df[df$ALAND20 > 0, ]

df <- df %>%
  select(-c(
    STATEFP20, COUNTYFP20, TRACTCE20, BLOCKCE20, NAME20, MTFCC20,
    UR20, UACE20, UATYPE20, FUNCSTAT20, INTPTLAT20, INTPTLON20, HOUSING20, POP20
  ))


df <- st_as_sf(df)


# Clean geometries ---
df_empty_geom <- df[st_is_empty(df$geometry) | is.na(df$geometry), ] 
df <- df[!st_is_empty(df$geometry) & !is.na(df$geometry), ] 


#-------------------------------------------------------------------------------
# Map for a specific crime -----------------------------------------------------

crime <- "Violent_Crime"

data <- df %>%
  group_by(GEOID) %>%
  summarise(
    Total_Crime = sum(.data[[crime]], na.rm = TRUE),
    geometry = first(geometry),
    Aland20 = first(ALAND20),
    Awater = first(AWATER20)
  ) %>%
  arrange(desc(Total_Crime))



# (...) Code for plot 

# Save csv with only the blocks that belong to Chicago
df_Chicago <- Block_crime %>%
  filter(GEOID %in% data$GEOID)

write.csv(df_Chicago, "Chicago_df_Crime_Dist_Block_Annual_Final.csv", row.names = FALSE)



#--------------------------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------- Los Angeles -----------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------

Block_crime <- laBlock_crime
Blocks_shp <- laBlocks_shp
Blocks_noWater_shp <- laBlocks_noWater_shp
Blocks_noWater_shp <- st_make_valid(Blocks_noWater_shp)


# Get the total number of crimes for each block
df <- Block_crime %>%
  select(-Year) %>%
  group_by(GEOID) %>%
  summarise(across(where(is.numeric), sum, na.rm = TRUE))

# Merge the Block_crime with shapefile
df <- left_join(df, Blocks_shp, by = c("GEOID" = "GEOID20"))
df <- st_as_sf(df)

# Keep only the blocks that belong to LA City
# Create a column in df called "tractCode"
df <- df %>% mutate(blockCode = substr(GEOID, 6, 15))


# Extract the unique GEOID values from Blocks_noWater_shp
ct20_values <- unique(Blocks_noWater_shp$CTCB20)

# Filter the df to keep rows where blockCode is not in ct20_values
df_in <- df %>%
  filter((blockCode %in% ct20_values))

df <- df_in

# df_in <- df %>%
#   filter(tractCode %in% ct20_values | 
#            (!(tractCode %in% ct20_values) & (Violent_Crime != 0 | Property_Crime != 0)))
# 


# Keep only the blocks that intersect the noWater geometry
# Check geometries
st_crs(Blocks_noWater_shp)
st_crs(df)



# Remove the areas that are just water
df <- df[df$ALAND20 > 0, ]

df <- df %>%
  select(-c(
    STATEFP20, COUNTYFP20, TRACTCE20, BLOCKCE20, NAME20, MTFCC20, blockCode,
    UR20, UACE20, UATYPE20, FUNCSTAT20, INTPTLAT20, INTPTLON20, HOUSING20, POP20
  ))


df <- st_as_sf(df)



#-------------------------------------------------------------------------------
# Map for a specific crime -----------------------------------------------------

crime <- "Property_Crime"

data <- df %>%
  group_by(GEOID) %>%
  summarise(
    Total_Crime = sum(.data[[crime]], na.rm = TRUE),
    geometry = first(geometry),
    Aland20 = first(ALAND20),
    Awater = first(AWATER20)
  ) %>%
  arrange(desc(Total_Crime))


# (...) Code for plot 


# Save csv with only the blocks that belong to LA City
df_LA <- Block_crime %>%
  filter(GEOID %in% data$GEOID)

write.csv(df_LA, "df_LA.csv", row.names = FALSE)





