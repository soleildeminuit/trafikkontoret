library(dplyr)
library(tibble)
library(httr)
library(jsonlite)
library(osmdata)
library(sf)
library(tmap)

############################## Open Street Map (OSM) ##############################
# Hämta alla systembolag inom Stockholms stads gränser från Systembolaget         #
#                                                                                 #
# OBS! API-nyckel måste först skapas på https://api-portal.systembolaget.se/ och  #
# läggas i textfilen "api_key_systembolaget.R" (i arbetskatalogen/working dir).   #
#                                                                                 #
# Textfilen ska bara innehålla en enda rad:                                       #
# api_key <- "<DIN API_NYCKEL>" + Enter                                           #
#                                                                                 #
###################################################################################
source("api_key_systembolaget.R")

# Läs geodata (gränser) för stadsdelsnämndsområden, från Stockholms stads dataportal (öppna data)
url_sdn <- "https://dataportalen.stockholm.se/dataportalen/Data/Stadsbyggnadskontoret/Stadsdelsnamndsomrade_2020.zip"
f <- paste(getwd(), "/data/sdn.zip", sep = "")
download.file(url_sdn, f, mode="wb")
unzip(f, exdir = "data")
sdn <- st_read("data/Stadsdelsn„mndsomr†de_2020.shp") %>% 
  st_zm(drop = TRUE) %>% 
  st_transform(crs = 4326)

# Hämta alla Systembolagets butiker (API)
systembolaget_url <- "https://api-extern.systembolaget.se/site/V2/Store"

httpResponse <- GET(systembolaget_url, 
                    add_headers("Ocp-Apim-Subscription-Key" = api_key))
probe_result = fromJSON(content(httpResponse, "text", encoding = "UTF-8"))

l <- list()
for (i in 1:nrow(probe_result)){
  df <- tribble(~name,~lon,~lat,~city,~ordersToday,
                probe_result[i,]$alias,
                probe_result[i,]$position$longitude,
                probe_result[i,]$position$latitude,
                probe_result[i,]$city,
                probe_result[i,]$ordersToday)
  l[[i]] <- df
}
sb <- do.call("rbind", l) %>% st_as_sf(., coords=c("lon","lat"), crs = 4326)
# Variabeln "sb" innehåller nu alla landets Systembolagsbutiker

# För att välja endast de som befinner sig inom Stockholms stads gränser...
sb_sthlm <- st_intersection(sb, sdn)

# Kolla hur många butiker inom resp. stadsdelsområde
table(sb_sthlm$Sdn_omarde)

# Enkel plot
plot(st_geometry(sb_sthlm))

# Enkel, men interaktiv, kartvy
tmap_mode("view")
tm_shape(sb_sthlm) + tm_symbols(col = "ordersToday", style = "jenks")

# Transformera till SWEREF 99 18 00 TM
sb_sthlm <- sb_sthlm %>% st_transform(., crs = 3011)

st_write(sb_sthlm, "data/systembolag.shp", delete_dsn = T)

############################## Open Street Map (OSM) ##############################
# Hämta alla systembolag inom Stockholms stads gränser från Open Street Map       #
###################################################################################

# Skapa OpenStreetMap-fråga, med stadsdelsnämndsområden som sökområde
q0 <- opq(bbox = st_bbox(sdn))

# Hämta alla systembolag inom sökområdet
q1 <- add_osm_feature(opq = q0, key = 'shop', value = "alcohol") # add_osm_feature("shop", "supermarket")
res1 <- osmdata_sf(q1)

sb_osm <- res1$osm_points
sb_osm$name <- iconv(sb_osm$name, "UTF-8")
# p <- p %>% dplyr::select(osm_id, name)

# Transformera till SWEREF 99 18 00 TM
sb_osm <- sb_osm %>% st_transform(., crs = 3011)

# Spara systembolagen som ESRI-shapefiler
st_write(sb_osm, "data/systembolag_osm.shp", delete_dsn = T)
