library(testthat)
library(here)

test_that("Area wkt file has one line", {
  area_wkt_file <- here::here("data", "output", "lme_eu_borders_bbox.txt")
  
  # Read the wkt from the file
  area_wkt <- readr::read_file(area_wkt_file)
  # Check that the area_wkt is not empty
  expect_true(nchar(area_wkt) > 0)
  # Check that the area_wkt has only one line
  expect_equal(length(strsplit(area_wkt, "\n")[[1]]), 1)
  # Check that the area_wkt starts with "POLYGON" (since it's a bounding box)
  expect_true(startsWith(area_wkt, "POLYGON"))
  # Check that the area_wkt polygon is well-formed (has 5 points for a bounding box)
  points <- strsplit(area_wkt, "\\(\\(")[[1]][2]
  points <- strsplit(points, "\\)\\)")[[1]][1]
  points <- strsplit(points, ",")[[1]]
  # Remove header spaces
  points <- trimws(points)
  expect_equal(length(points), 5)
  expect_equal(points[1], points[5]) # The first and last point should be the same for a closed polygon
})
