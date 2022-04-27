library(osmdata)
library(sf)
library(dplyr)
# library(tmap)

# Läs geodata (gränser) för stadsdelsnämndsområden
sdn <- st_read("../data/sbk/Adm_area_ny.shp") %>% 
  st_union() %>% 
  st_as_sf() %>% 
  st_transform(crs = 4326)

# Skapa OpenStreetMap-fråga, men stadsdelsnämndsområden som sökområde
q0 <- opq(bbox = st_bbox(sdn))

# Hämta alla systembolag inom sökområdet
q1 <- add_osm_feature(opq = q0, key = 'shop', value = "alcohol") # add_osm_feature("shop", "supermarket")
res1 <- osmdata_sf(q1)

systembolag <- res1$osm_points
systembolag$name <- iconv(systembolag$name, "UTF-8")
# p <- p %>% dplyr::select(osm_id, name)

# Transformera till SWEREF 99 18 00 TM
systembolag <- systembolag %>% st_transform(., crs = 3011)

# Spara systembolagen som ESRI-shapefiler
st_write(systembolag, "data/systembolag.shp", delete_dsn = T)

# mapview::mapview(systembolag)
# tmap_save(t, "t.html", width = 297, height = 210, units ="mm", dpi=300)
