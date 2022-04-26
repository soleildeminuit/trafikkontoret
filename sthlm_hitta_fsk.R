library(dplyr)
library(sf)
library(osmdata)
library(jsonlite)
library(osmdata)
library(tmap)
# library(openrouteservice)
library(geojsonio)
library(areal)

url_st <- "https://apigw.stockholm.se/NoAuth/VirtualhittaserviceDMZ/Rest/servicetypes"
st <- fromJSON(url_st)

url_fsk <- "https://apigw.stockholm.se/NoAuth/VirtualhittaserviceDMZ/Rest/serviceunits?filter[servicetype.id]=2&page[limit]=1500&page[offset]=0&sort=name"
fsk <- fromJSON(url_fsk)

fsk <- fsk$data$attributes
fsk$east <- fsk$location$east
fsk$north <- fsk$location$north
fsk$created <- as.Date(fsk$created)
fsk$changed <- as.Date(fsk$changed)

fsk <- st_as_sf(fsk, coords = c("east", "north"), crs = 3011)

# st_write(fsk, "fsk.geojson", delete_dsn = TRUE)

tm_shape(fsk) + tm_symbols()