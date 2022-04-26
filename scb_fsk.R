library(dplyr)
library(httr)

# https://www.scb.se/vara-tjanster/oppna-data/oppna-geodata/forskolor/

url_fsk <- "https://www.scb.se/contentassets/51c8cfbe88a94a36927ad34618e636b9/forskolor_ht21_sweref.zip"

f <- paste(getwd(), "/data/fsk_scb.zip", sep = "")
# Encoding(f) <- "UTF-8" 
download.file(url_fsk, f, mode="wb")
unzip(f, exdir = "data")

fsk <- st_read("data/F”rskolor_HT21_Sweref.gpkg")

fsk_sthlm <- fsk %>%
  filter(
    Kommun == "0180", 
    Företagsnamn == "STOCKHOLMS KOMMUN"
  ) %>%
  st_transform(crs = 3011)

plot(st_geometry(fsk_sthlm))