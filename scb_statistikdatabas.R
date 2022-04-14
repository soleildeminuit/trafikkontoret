library(pxweb)
library(dplyr)
library(openxlsx)
library(tmap)
library(viridis)

# "http://api.scb.se/OV0104/v1/doris/sv/ssd/BE/BE0101/BE0101Y/FolkmDesoAldKonN"
# d <- pxweb_interactive("http://api.scb.se/OV0104/v1/doris/sv/ssd/BE/BE0101/BE0101Y/FolkmDesoAldKonN")
# d <- pxweb_interactive("api.scb.se")

# query <- pxweb_query_as_json(d$query, pretty = TRUE)

pxq <- pxweb_query("data/query_befstat.json")

pxd <- pxweb_get("http://api.scb.se/OV0104/v1/doris/sv/ssd/BE/BE0101/BE0101Y/FolkmDesoAldKonN",
                 pxq)
pxd

pxdf <- as.data.frame(pxd, column.name.type = "text", variable.value.type = "text")
head(pxdf)

# saveRDS(pxdf, "data/pxdf.rds")

deso_sthlm_df <- pxdf %>% 
  filter(grepl("^\\d{4}[A-C]\\d{4}$", region) == TRUE,
         substr(region, 1, 4) == "0180",
         ålder == "totalt", kön == "totalt") %>% 
  select(-ålder, -kön) %>% 
  rename(deso = region)

# Read join table, DeSO <-> RegSO
deso_regso <- read.xlsx("https://www.scb.se/contentassets/e3b2f06da62046ba93ff58af1b845c7e/kopplingstabell-deso_regso_20211004.xlsx", 
                        "Blad1",
                        startRow = 4) %>% select(-Kommun, -Kommunnamn) %>% 
  rename(deso = DeSO, regso_namn = RegSO, regso = RegSOkod)

# Join DesO and RegSO
deso_sthlm_df <- deso_sthlm_df %>% 
  left_join(., deso_regso, by = c("deso" = "deso")) %>% 
  rename(pop_count = `Folkmängden per region`)

# Join statistics with geography
# NOTE: First run the script scb_wfs.R
deso_areas_sf <- st_read("data/DeSO_2018.gpkg") %>% 
  filter(kommun == "0180") %>%
  left_join(., deso_sthlm_df, by = c("deso" = "deso"))

# RegSO

# Join statistics with geography
# NOTE: First run the script scb_wfs.R
regso_areas_sf <- st_read("data/RegSO_2018.gpkg") %>% filter(kommun == "0180") %>% 
  rename(regso_namn = regso, regso = regsokod)

# Sum population counts per RegSO
pop_count_regso <- deso_sthlm_df %>% group_by(regso, regso_namn) %>% summarise(pop_count = sum(pop_count)) %>% ungroup()

# Join statistics with geography
regso_areas_sf <- regso_areas_sf %>% left_join(.,
                                               pop_count_regso %>% select(-regso_namn),  # Exclude the name as it's in both sides.
                                               by = "regso")

# # Create a thematic map
t <- tm_shape(regso_areas_sf) + 
  tm_fill(
    "pop_count", 
    style = "jenks", 
    palette = "viridis") + 
  tm_borders() +
  tm_shape(regso_areas_sf) +
  tm_text("regso_namn", remove.overlap = TRUE)

# Save highres map
tmap_save(t, "figs/map.png", width = 297, height = 210, units = "mm", dpi = 300)
