# Nödvändiga paket
for (package in c(
  "dplyr", 
  "tibble", 
  "httr", 
  "jsonlite", 
  "osmdata", 
  "sf", 
  "areal",
  "tmap", 
  "viridis")) {
  if (!require(package, character.only=T, quietly=T)) {
    suppressPackageStartupMessages(package)
    suppressWarnings(package)
    install.packages(package)
    library(package, character.only=T)
  }
}

# Installera alla nödvändiga paket, metod 2
# list.of.packages <- c("ggplot2", "ggmap", "osmdata")
# new.packages <- list.of.packages[!(list.of.packages %in% 
#                                      installed.packages()[,"Package"])]
# if(length(new.packages)) install.packages(new.packages)

################################## Systembolaget ##################################
# Hämta alla systembolag inom Stockholms stads gränser från Systembolaget         #
#                                                                                 #
# OBS! API-nyckel måste först skapas på:                                          #
# https://api-portal.systembolaget.se/products/Open%20API                         #
# Nyckeln läggs i textfilen "api_key_systembolaget.R" (i working dir).            #
#                                                                                 #
# Textfilen ska bara innehålla en enda rad:                                       #
# api_key <- "<DIN API_NYCKEL>" + Enter                                           #
#                                                                                 #
###################################################################################
source("api_key_systembolaget.R")

# Metod 1: Läs geodata (gränser) för stadsdelsnämndsområden, från Stockholms stads dataportal (öppna data)
url_dataportal <- "https://dataportalen.stockholm.se/dataportalen/Data/Stadsbyggnadskontoret/Stadsdelsnamndsomrade_2020.zip"
f <- paste(getwd(), "/data/sdn.zip", sep = "")
download.file(url_dataportal, f, mode="wb")
unzip(f, exdir = "data")
sdn <- st_read("data/Stadsdelsn„mndsomr†de_2020.shp") %>% 
  st_zm(drop = TRUE) %>% 
  st_transform(crs = 4326)

# Metod 2: Hämta geodata för stadsdelsnämndsområden genom WebQuery-API (sbk)
url_webquery <- "http://kartor.stockholm.se/bios/webquery/app/baggis/web/web_query?section="
methods <- c("locate*stadsdelsnamnd", "stadsdelsnamnd*suggest")
urlJ <- fromJSON(paste(url_webquery,
                       methods[1],
                       "&&resulttype=json",
                       sep = ""))
urlJ2 <- fromJSON(paste(url_webquery,
                        methods[2],
                        "&&resulttype=json",
                        sep = ""))

sfc <- st_as_sfc(urlJ$dbrows$WKT, EWKB = F)
sdn <- st_sf(sfc, crs = 3011) %>%
  rename(geometry = sfc) %>%
  mutate(ADM_ID = as.integer(urlJ$dbrows$ID)) %>% 
  arrange(ADM_ID)

sdn$NAMN <-  urlJ2$dbrows$RESULT
sdn <- sdn %>% dplyr::select(NAMN, ADM_ID)

sdn <- sdn %>% mutate(ADM_ID = case_when(ADM_ID == 21 ~ 22, TRUE ~ as.numeric(ADM_ID)))

#########################

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

# Statisk kartvy
# Ange tmap_mode("view")för interaktiv webbkarta 
tmap_mode("plot")

t <- tm_shape(sdn) + 
  tm_borders(alpha = 0) +
  tm_shape(sb_sthlm) + 
  tm_symbols(
    col = "ordersToday", 
    size = "ordersToday",
    style = "jenks", 
    palette = "viridis") +
  tm_shape(sdn) + 
  tm_borders(lwd = 3) +
  tm_shape(sdn) + 
  tm_text(
    "NAMN",
    size = 0.5,
    auto.placement = TRUE,
    remove.overlap = TRUE,
    col = "black") +
  tm_credits("Datakällor: Systembolaget, Stockholms stad",
             position=c("right", "bottom")) +
  tm_scale_bar(position=c("left", "bottom")) +
  tm_compass(type = "arrow", position=c("right", "top"), show.labels = 3) +
  tm_layout(
    main.title = "Systembolagsbutiker i Stockholms stad",
    legend.format=list(fun=function(x) formatC(x, digits=0, format="d", big.mark = " "), text.separator = "-")
  )

tmap_save(t, "Systembolag.png", width = 297, height = 210, units = "mm", dpi = 300)

# Transformera till SWEREF 99 18 00 TM
sb_sthlm <- sb_sthlm %>% st_transform(., crs = 3011)

# Spara geodata som ESRI Shape-filer
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
