library(dplyr)
library(tidyr)
library(sf)
library(ows4R)
library(httr)
library(purrr)

source("api_key.R")

wfs_tk <- paste("https://openstreetgs.stockholm.se/geoservice/api/", api_key, "/wfs", sep = "")

url <- parse_url(wfs_tk)
url$query <- list(service = "wfs",
                  request = "GetCapabilities"
)

wfs_client <- WFSClient$new(wfs_tk, 
                            serviceVersion = "1.0.0")

wfs_client$
  getCapabilities()$ 
  getFeatureTypes() %>%  
  map_chr(function(x){x$getAbstract()})

url$query <- list(service = "wfs",
                  version = "1.0.0", 
                  request = "GetFeature",
                  typename =  "ltfr:LTFR_LASTZON" # "ltfr:LTFR_BOENDE_OSTERM"
)
request <- build_url(url)

wfs_features <- read_sf(request, crs = 3011)

st_write(wfs_features, paste("data/", "LTFR_LASTZON",".geojson", sep= ""), delete_dsn = TRUE)
