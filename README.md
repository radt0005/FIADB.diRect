# FIADB.diRect

FIADB.diRect is an R package for direct access to USDA Forest Inventory and Analysis (FIA) PostgreSQL databases.

The package provides tools for querying FIA databases and generating:

- Green Book estimates
- Filtered Green Book estimates
- Plot-level observations
- Filtered plot-level observations
- Tree-level observations
- Filtered tree-level observations
- Custom FIA record retrievals
- SQL filter expressions for FIA queries

## Main Functions

| Function | Description |
|-----------|-------------|
| `GB_est()` | Generate FIA Green Book estimates |
| `GB_est_w_filter()` | Generate Green Book estimates with user-defined filters |
| `PLOT_obs()` | Retrieve plot-level observations |
| `PLOT_obs_w_filter()` | Retrieve filtered plot-level observations |
| `TREE_obs()` | Retrieve tree-level observations |
| `TREE_obs_w_filter()` | Retrieve filtered tree-level observations |
| `GET_record()` | Retrieve FIA database records |
| `create_filter()` | Build SQL filter expressions |

## Installation

### From GitHub

```r
# install.packages("remotes")
remotes::install_github("radt0005/FIADB.diRect")
```

### From Source

```r
devtools::install("path/to/FIADB.diRect")
```

## Example

```r
library(FIADB.diRect)

GB_est(
  EVAL_GRP = 102019,
  ATTRIBUTE_NBR = 2,
  GRP_BY_ATTRIB = c("STATECD", "COUNTYCD")
)
```

## Database Requirements

The package requires access to an FIA PostgreSQL database and appropriate PostgreSQL drivers.

## Development Status

Current version: **0.0.1**

The package currently passes:

- R CMD check: 0 errors
- R CMD check: 0 warnings
- R CMD check: 0 notes

## Author

Phil Radtke

Virginia Tech
