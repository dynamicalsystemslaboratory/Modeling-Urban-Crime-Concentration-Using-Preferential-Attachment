**README: Journal Article Materials**

**Title:** *Preferential attachment explains crime concentration in cities*\
**Authors:** Ofek Lauber Bonomo, Inês Figueira, Maurizio Porfiri\
**Corresponding Author:** Maurizio Porfiri\
**Date:** August 25, 2025

---

### Directory Structure
* `data/` Contains processed data necessary to generate figures/perform analysis.

* `scripts/` Scripts used in the research.
    * `Data processing/` Scripts used to process the raw data.
    * `Data analysis/` Scripts used to perform analysis.
    * `Numerical simulations/` Scripts used to simulate the model dynamics.
 
* `figures/` Mathematica scripts used to perform analysis and generate the figures included in the manuscript

---

### Data Processing
We use publicly available reported crime data from four major United States cities:
* Boston - https://data.boston.gov/dataset/crime-incident-reports-august-2015-to-date-source-new-system
* Chicago - https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-Present/ijzp-q8t2/about_data
* LA - https://data.lacity.org/Public-Safety/Crime-Data-from-2010-to-2019/63jg-8b9z/about_data & https://data.lacity.org/Public-Safety/Crime-Data-from-2020-to-Present/2nrs-mtv8/about_data
* NYC - https://data.cityofnewyork.us/Public-Safety/NYPD-Complaint-Data-Historic/qgea-i56i/about_data

** As the datasets for Boston and LA are given as separate files for different periods, we join the files using Merge_Boston_Data and Merge_LA_Data, respectively (see `Data processing/`).

Together with Census block-level shapefiles from the 2020 Decennial Census (https://www.census.gov/cgi-bin/geo/shapefiles/index.php), we assign crime incidents to blocks on an annual basis using City_Crime2Block_Year (see `Data processing/`). 

Based on the FBI's SRS Manual (https://le.fbi.gov/file-repository/summary-reporting-system-user-manual.pdf/view) and state-level manuals (see `data/`, Boston crime data already includes categorization information), we manually aggregate the different crime types into two categories - violent and property crime (see `data/` for aggregated categories). Datasets are then cleaned by excluding blocks with no land area (only water) and crimes with missing or invalid date or location data (see `Data processing/`). We consider only crimes occuring up to, but not including, 2025.

The datasets has been anonymized by replacing the original Census block GEOIDs with sequential, meaningless BlockIDs.
