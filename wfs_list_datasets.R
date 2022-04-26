library(dplyr)
library(tidyr)
library(sf)
library(ows4R)
library(httr)
library(purrr)

source("api_key.R")

wfs_tk <- paste("https://openstreetgs.stockholm.se/geoservice/api/", api_key, "/wfs", sep = "")

# url <- parse_url(wfs_tk)
# url$query <- list(service = "wfs",
#                   request = "GetCapabilities"
# )
# request <- build_url(url)
# request

wfs_client <- WFSClient$new(wfs_tk, 
                            serviceVersion = "1.0.0")

wfs_client$getFeatureTypes(pretty = TRUE)
df <- wfs_client$getFeatureTypes(pretty = TRUE)
df


write.table(df, "datasets.csv", quote = F, row.names = F, dec = ",", sep = "\t", na = "")