library(dplyr)
library(httr)
library(jsonlite)
library(tibble)

sdn <- st_read("../data/sbk/Adm_area_ny.shp") %>% 
  st_union() %>% st_as_sf()

sreg <- fromJSON("https://api.scb.se/UF0109/v2/skolenhetsregister/sv/skolenhet/")

skolenheter <- sreg$Skolenheter

l <- list()
for (i in 1:nrow(skolenheter)){
  url_se <- paste("https://api.scb.se/UF0109/v2/skolenhetsregister/sv/skolenhet/", 
                  trimws(skolenheter[i,]$Skolenhetskod), sep = "")
  se <- fromJSON(url_se)
  df <- tribble(~Namn, ~Adress, ~Postnr, ~Ort, ~Kommun, ~Huvudman_Namn, ~lng, ~lat,
    se$SkolenhetInfo$Namn,
    se$SkolenhetInfo$Besoksadress$Adress,
    se$SkolenhetInfo$Besoksadress$Postnr,
    se$SkolenhetInfo$Besoksadress$Ort,
    se$SkolenhetInfo$Kommun,
    se$SkolenhetInfo$Huvudman$Namn,
    se$SkolenhetInfo$Besoksadress$GeoData$Koordinat_WGS84_Lng,
    se$SkolenhetInfo$Besoksadress$GeoData$Koordinat_WGS84_Lat
  ) %>% 
    mutate(
    lng = gsub(",", ".", lng),
    lat = gsub(",", ".", lat)) %>% 
    mutate(
      lng = as.numeric(lng),
      lat = as.numeric(lat)
    )
  l[[i]] <- df
  print(i)
}
skolenheter_df <- do.call("rbind", l) %>% 
  filter(!is.na(lng)) %>% 
  st_as_sf(., coords = c("lng", "lat"), crs = 4326)

# saveRDS(skolenheter_df, "data/skolenheter.rds")
skolenheter_sf <- readRDS("data/skolenheter.rds")
# plot(st_geometry(skolenheter_df))

skolenheter_sf <- skolenheter_sf %>% st_transform(crs = 3011)

skolenheter_sf_sthlm <- skolenheter_sf %>% st_intersection(sdn)

plot(st_geometry(skolenheter_sf_sthlm))

s <- skolenheter_sf_sthlm %>% select(-c(Kommun))
mapview::mapview(s)