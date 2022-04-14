library(dplyr)
library(sf)
library(ows4R)
library(httr)
library(purrr)
library(stringr)

wfs_msb <- "https://geodata.scb.se/geoserver/stat/wfs"

url <- parse_url(wfs_msb)
url$query <- list(service = "wfs",
                  #version = "2.0.0", # optional
                  request = "GetCapabilities"
)
request <- build_url(url)
request

scb_client <- WFSClient$new(wfs_msb, 
                            serviceVersion = "1.0.0")

scb_client$getFeatureTypes(pretty = TRUE)

# scb_client$getCapabilities()

scb_client$
  getCapabilities()$ 
  getFeatureTypes() %>%  
  map_chr(function(x){x$getAbstract()})

url$query <- list(service = "wfs",
                  version = "1.0.0", 
                  request = "GetFeature",
                  typename = "stat:DeSO.2018"#,
                  # srsName = "EPSG:3006"
)
request <- build_url(url)

wfs_features <- read_sf(request, stringsAsFactors = FALSE)

wfs_features <- wfs_features %>% mutate(kommun = as.character(kommun)) %>% 
  mutate(kommun = str_pad(string = kommun, width = 4, side = "left", pad = "0"))

# 5984
# nrow(wfs_features)

# Write Geopackage file
st_write(wfs_features, "data/DeSO_2018.gpkg", delete_dsn = TRUE)

# plot(st_geometry(wfs_features))

# Fetch Regional Demograhic Statistical Areas (RegSO). RegSO are aggregated DeSO, 5 984 DeSO aggregate to 3 363 RegSO (total, in Sweden)
# The Stockholm municipality has 127 RegSO (built from 544 DeSO).
scb_client$
  getCapabilities()$ 
  getFeatureTypes() %>%  
  map_chr(function(x){x$getAbstract()})

url$query <- list(service = "wfs",
                  version = "1.0.0", 
                  request = "GetFeature",
                  typename = "stat:RegSO.2018"#,
                  # srsName = "EPSG:3006"
)
request <- build_url(url)

wfs_features <- read_sf(request, stringsAsFactors = FALSE)

wfs_features <- wfs_features %>% mutate(kommun = as.character(kommun)) %>% 
  mutate(kommun = str_pad(string = kommun, width = 4, side = "left", pad = "0"))

st_write(wfs_features, "data/RegSO_2018.gpkg", delete_dsn = TRUE)