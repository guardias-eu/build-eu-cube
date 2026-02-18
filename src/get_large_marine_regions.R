library(mregions2)
library(sf)

lme <- mregions2::mrp_get(layer = "lme")

# LME we are interested in
lme_ids_eu <- c(1,3,6,11,13,14,50,53,54)
lme_eu <- lme[lme$objectid %in% lme_ids_eu, ]

# Validate polygons
lme_eu <- sf::st_make_valid(lme_eu)

# Get the union of the LME polygons
lme_eu_borders <- sf::st_union(lme_eu)

# mapview::mapview(lme_eu_borders) # to visualize the borders

# Get WKT representation of the borders
lme_eu_borders_wkt <- sf::st_as_text(lme_eu_borders)

# Get the bounding box of the borders as polygon
lme_eu_borders_bbox <- sf::st_as_sfc(sf::st_bbox(lme_eu_borders))

# Get WKT representation of the bounding box
lme_eu_borders_bbox_wkt <- sf::st_as_text(lme_eu_borders_bbox)

# Save the WKT to file ./data/output/lme_eu_borders_bbox.txt
output_file_bbox <- "./data/output/lme_eu_borders_bbox.txt"
write(lme_eu_borders_bbox_wkt, file = output_file_bbox)

# Save the LMEs of Europe as geopackage
output_file_lme <- "./data/output/lme_eu.gpkg"
sf::st_write(lme_eu, dsn = output_file_lme, layer = "large marine regions (Europe)", delete_dsn = TRUE)
