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

# Database Requirements

FIADB.diRect is a client package for FIA PostgreSQL databases and <u>does not ship with FIA data</u>.

Before using this package, users must have access to an FIA database that has already been loaded into PostgreSQL and is accessible from R. The package connects directly to the PostgreSQL database to retrieve records, observations, and estimates.

### Required One-Time Setup: `fix_oracle_syntax()`

The `REF_POP_ATTRIBUTE` reference table stores SQL query templates that
were originally authored against an Oracle-based FIADB backend. Some of
these templates use Oracle's `Q'[...]'` quoting operator, which has no
PostgreSQL equivalent and will cause errors such as
`ERROR:  type "q" does not exist` when calling functions like
`GB_est()`.

After loading FIA reference data into your PostgreSQL database, and
before using `GB_est()`, `GB_est_w_filter()`, or related functions, run:

```r
library(FIADB.diRect)

# Check how many rows would be affected (no changes made)
fix_oracle_syntax(dry_run = TRUE)

# Apply the fix
fix_oracle_syntax(dry_run = FALSE)
```

This only needs to be run once per database.

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

**Important:** FIADB.diRect **does not ship with FIA data**. Users must have access to an FIA database that has already been loaded into PostgreSQL.

### From GitHub

```r
# install.packages("remotes")
remotes::install_github("radt0005/FIADB.diRect")

# install with pak
pak::pkg_install("radt0005/FIADB.diRect")
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

## Authors

Phil Radtke, Aakriti Sapkota, David Walker

Virginia Tech
