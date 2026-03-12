# build-eu-cube

## Rationale

This repository contains an automated workflow to trigger and track species occurrence cube downloads from GBIF for marine and oligohaline species in European waters. The workflow:

- Retrieves marine and oligohaline species from the [EASIN-GBIF taxa matcher](https://github.com/guardias-eu/easin-gbif-taxa-matcher)
- Defines the geographic scope using Large Marine Ecosystems (LMEs) relevant to Europe
- Builds and executes a SQL query to create species occurrence cubes via the GBIF Download API
- Tracks download metadata in a version-controlled list

The cubes aggregate GBIF occurrence data into spatiotemporal cells (EEA reference grid at 10km resolution) for calculating [emerging trends indicators](https://github.com/guardias-eu/emtrends).

## Workflow

The workflow is fully automated via GitHub Actions:

1. **Nightly query execution** ([`run-query-and-create-pr.yml`](.github/workflows/run-query-and-create-pr.yml))
   - Runs daily at 2 AM UTC (or manually via `workflow_dispatch`)
   - Generates European LME boundaries by running `get_large_marine_regions.R`
   - Validates the area WKT file with `test-area_wkt.R`
     - If validation fails: workflow stops and creates an issue with `bug` and `automated` labels
     - If validation succeeds: workflow continues
   - Fetches the latest marine/oligohaline species list from EASIN-GBIF matcher
   - Submits SQL query to GBIF to trigger occurrence cube download
   - Updates the download tracking list
   - Creates a pull request with the `automated` label
   - Runs tests on the download list (`test-list_downloads.R`)
   - If tests pass, adds the `approved` label to the PR

2. **Automated merging** ([`merge-prs-labelled-approved.yml`](.github/workflows/merge-prs-labelled-approved.yml))
   - Runs daily at 3 AM UTC (or manually via `workflow_dispatch`)
   - Finds all open pull requests with both `automated` and `approved` labels
   - Merges them to the main branch using squash merge
   - Deletes the merged branch automatically

This ensures that successful query runs are automatically integrated into the repository without manual intervention, while failures in area validation halt the process and alert maintainers.

## Repo structure

The repository structure is based on best practices for reproducible research and automated workflows:

```
├── README.md              : Description of this repository
├── LICENSE                : Repository license
├── build-eu-cube.Rproj    : RStudio project file
├── .gitignore             : Files and directories to be ignored by git
│
├── .github
│   └── workflows
│       ├── run-query-and-create-pr.yml       : Daily query execution workflow
│       └── merge-prs-labelled-approved.yml   : Auto-merge approved PRs
│
├── src
│   ├── get_large_marine_regions.R  : Script to define European LME boundaries
│   └── build_run_query.R           : Main script to build SQL query and trigger download
│
├── tests
│   └── test-list_downloads.R  : Validation tests for download tracking list
│
└── data
    └── output                            : Generated data files GENERATED
        ├── lme_eu.gpkg                   : European Large Marine Ecosystems (geopackage)
        ├── lme_eu_borders_bbox.txt       : WKT of LME bounding box
        ├── species_cube_marine_oligohaline.csv  : Species list used for cube
        └── list_downloads.tsv            : Tracking list of GBIF downloads
```

## Scripts

### `src/get_large_marine_regions.R`

Defines the geographic scope by:
- Retrieving Large Marine Ecosystem (LME) polygons using `mregions2`
- Selecting 9 European LMEs (IDs: 1, 3, 6, 11, 13, 14, 50, 53, 54)
- Computing the union and bounding box of these regions
- Saving WKT representation and geopackage for use in queries

### `src/build_run_query.R`

Main automation script that:
- Fetches accepted marine/oligohaline species from EASIN-GBIF matcher
- Loads the geographic area WKT
- Constructs a SQL query for GBIF's occurrence cube download
- Filters for quality-controlled occurrences (1950+, valid coordinates, verified identifications)
- Triggers the download via `rgbif::occ_download_sql()`
- Updates the download tracking list with metadata using `trias::update_download_list()`

### `tests/test-area_wkt.R`

Validation tests for the area WKT file that ensure:
- WKT file exists and is not empty
- Contains exactly one line (single WKT string)
- Starts with "POLYGON" (bounding box format)
- Has valid polygon structure with 5 points (closed bounding box)
- First and last points are identical (properly closed polygon)

### `tests/test-list_downloads.R`

Validation tests for the download tracking list that ensure:
- Download list has correct structure and column types
- No missing values in critical fields
- Download status is valid (RUNNING, PREPARING, SUCCEEDED, or CANCELLED)

## Requirements

The workflow requires the following secrets to be configured in the GitHub repository:

- `GBIF_USER`: GBIF username
- `GBIF_PWD`: GBIF password
- `GBIF_EMAIL`: Email associated with GBIF account

## Contributors

[List of contributors](https://github.com/guardias-eu/build-eu-cube/contributors)

## License

[MIT License](LICENSE) for the code and documentation in this repository.
