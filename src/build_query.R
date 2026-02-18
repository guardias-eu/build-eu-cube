library(readr)
library(dplyr)
library(readr)
library(glue)
library(rgbif)
library(trias)

# Get specie of interest ####
species_file <- "https://raw.githubusercontent.com/guardias-eu/easin-gbif-taxa-matcher/refs/heads/main/data/output/easin_gbif_match.csv"
# Read the species list from the file
species_list <- readr::read_csv(species_file, na = "", guess_max = 10000)

# Select accepted species
species_list <- species_list %>%
  dplyr::filter(status == "ACCEPTED") %>%
  dplyr::filter(rank == "SPECIES")

# Test with 100 species
species_list <- species_list %>%
  dplyr::slice_head(n = 100)

# Save species list used for the query to GBIF
species_cube_file <- "./data/output/species_cube_first_100.csv"
readr::write_csv(species_list, species_cube_file)


# Get wkt of the area of interest ####
area_wkt_file <- "./data/output/lme_eu_borders_bbox.txt"
# Read the wkt from the file
area_wkt <- readr::read_file(area_wkt_file)

sql_query <- "
  SELECT
    \"year\",
    GBIF_EEARGCode(
      10000,
      decimalLatitude,
      decimalLongitude,
      COALESCE(coordinateUncertaintyInMeters, 1000)
    ) AS eeaCellCode,
    classKey,
    class,
    speciesKey,
    species,
    COUNT(*) AS occurrences,
    MIN(COALESCE(coordinateUncertaintyInMeters, 1000)) AS minCoordinateUncertaintyInMeters,
    MIN(GBIF_TEMPORALUNCERTAINTY(eventdate, eventtime)) AS minTemporalUncertainty,
    IF(ISNULL(classKey), NULL, SUM(COUNT(*)) OVER (PARTITION BY classKey)) AS classCount
  FROM
    occurrence
  WHERE 
    occurrenceStatus = 'PRESENT'
    AND NOT occurrence.basisofrecord IN ('FOSSIL_SPECIMEN', 'LIVING_SPECIMEN')
    AND speciesKey IN ({species_keys})
    AND speciesKey IS NOT NULL
    AND GBIF_Within('{area_wkt}', decimalLatitude, decimalLongitude) = TRUE
    AND \"year\" >= 1950
    AND \"year\" IS NOT NULL
    AND hasCoordinate = TRUE
    AND NOT GBIF_STRINGARRAYCONTAINS(issue, 'ZERO_COORDINATE', TRUE)
    AND NOT GBIF_STRINGARRAYCONTAINS(issue, 'COORDINATE_OUT_OF_RANGE', TRUE)
    AND NOT GBIF_STRINGARRAYCONTAINS(issue, 'COORDINATE_INVALID', TRUE)
    AND NOT GBIF_STRINGARRAYCONTAINS(issue, 'COUNTRY_COORDINATE_MISMATCH', TRUE)
    AND NOT GBIF_STRINGARRAYCONTAINS(issue, 'TAXON_MATCH_FUZZY', TRUE)
    AND (
      LOWER(identificationVerificationStatus) NOT IN (
        'unverified',
        'unvalidated',
        'not validated',
        'under validation',
        'not able to validate',
        'control could not be conclusive due to insufficient knowledge',
        'uncertain',
        'unconfirmed',
        'unconfirmed - not reviewed',
        'validation requested'
        )
      OR identificationVerificationStatus IS NULL
    )
  GROUP BY
    \"year\",
    eeaCellCode,
    speciesKey,
    species,
    classKey,
    class
  ORDER BY
    \"year\" DESC,
    eeaCellCode ASC,
    speciesKey ASC;
"

query_filled <- glue::glue(
  sql_query,
  species_keys = paste(species_list$speciesKey, collapse = ", "),
  area_wkt = area_wkt
)


# Trigger species occurrence cube download with rgbif
d <- rgbif::occ_download_sql(
  q = query_filled,
  format = "SQL_TSV_ZIP",
  user = Sys.getenv("GBIF_USER"),
  pwd = Sys.getenv("GBIF_PWD"),
  email = Sys.getenv("GBIF_EMAIL"),
  validate = TRUE
)
d
# d <- "0027377-260208012135463"
metadata <- rgbif::occ_download_meta(d)

trias::update_download_list(
  file = "./data/output/list_downloads.tsv",
  download_to_add = metadata$key,
  input_checklist = species_cube_file
)
