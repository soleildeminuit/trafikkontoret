library(dplyr)
library(tidyr)
library(sf)
library(tmap)
library(viridis)

# https://ods.stockholm.se/

ods_bef <- read.csv("data/CsvOut_662.csv",
                    sep = ";",
                    fileEncoding = "Latin1",
                    skipNul = TRUE,
                    stringsAsFactors = FALSE,
                    header = TRUE)

ods_bef <- ods_bef %>% 
  separate(Område, c("nyko", "namn"), extra = "drop", fill = "right") %>% 
  mutate(nyko = trimws(nyko))

basomr <- st_read("../data/sweco/basomraden2016.shp") %>% 
  mutate(nyko = as.character(nyko)) %>% 
  mutate(nyko = Kod)

antal_inv_per_nyko <- 
  ods_bef %>% 
  group_by(nyko, namn) %>% 
  summarise(antal = sum(Antal))

basomr_bef <- basomr %>% left_join(., antal_inv_per_nyko, by = "nyko") %>% st_make_valid(.)

tm_shape(basomr_bef) + tm_fill("antal", style = "jenks", palette = "viridis") + tm_borders()