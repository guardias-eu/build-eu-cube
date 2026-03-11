library(testthat)
library(here)

test_that("list_downloads returns a data frame with expected columns", {
  downloads <- here::here("data", "output", "list_downloads.tsv") %>%
    readr::read_tsv(na = "")
  expect_true(is.data.frame(downloads))
  expect_identical(
    c("gbif_download_key",
      "input_checklist",
      "gbif_download_created",
      "gbif_download_status",
      "gbif_download_doi"
    ),
    colnames(downloads)
  )
  expect_true(class(downloads$gbif_download_key) == "character")
  expect_true(class(downloads$input_checklist) == "character")
  expect_identical(class(downloads$gbif_download_created), c("POSIXct", "POSIXt"))
  expect_true(class(downloads$gbif_download_status) == "character")
  expect_true(class(downloads$gbif_download_doi) == "character")
})

test_that("No NA values", {
  downloads <- here::here("data", "output", "list_downloads.tsv") %>%
    readr::read_tsv(na = "")
  expect_false(any(is.na(downloads)))
})

test_that("gbif_download_status is one of RUNNING, PREPARING, SUCCEDEED", {
  downloads <- here::here("data", "output", "list_downloads.tsv") %>%
    readr::read_tsv(na = "")
  valid_statuses <- c("RUNNING", "PREPARING", "SUCCEEDED", "CANCELLED")
  expect_true(all(downloads$gbif_download_status %in% valid_statuses))
})

