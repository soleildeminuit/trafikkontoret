library(osmdata)
library(sf)
library(dplyr)
library(tmap)

sdn <- st_read("../data/sbk/Adm_area_ny.shp") %>% 
  st_union() %>% st_as_sf() %>% st_transform(crs = 4326)

q0 <- opq(bbox = st_bbox(sdn))

q1 <- add_osm_feature(opq = q0, key = 'leisure', value = "park") # add_osm_feature("shop", "supermarket")
res1 <- osmdata_sf(q1)

p <- res1$osm_polygons
p$name <- iconv(p$name, "UTF-8")
p <- p %>% select(osm_id, name)
# st_write(p, "parker.shp", delete_dsn = T)

mapview::mapview(p)

tm_shape(p %>% mutate(a = st_area(.))) + 
  tm_fill("a", palette = "Greens", style = "jenks") +
  tm_borders()