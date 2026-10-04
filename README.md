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

### Oracle `Q'[...]'` Quoting: No Setup Needed

The `REF_POP_ATTRIBUTE` reference table stores SQL query templates that
were originally authored against an Oracle-based FIADB backend. Some FIA
DataMart downloads have templates that use Oracle's `Q'[...]'` quoting
operator (which has no PostgreSQL equivalent), and some don't.

`GB_est()`, `GB_est_w_filter()`, `PLOT_obs()`, and `TREE_obs()` all
handle this automatically and transparently -- no setup step required,
and nothing in your PostgreSQL database is ever modified. Whichever
style your DataMart download used, it just works.

(`fix_oracle_syntax()` still exists for the rare case where something
*other than* FIADB.diRect needs the `REF_POP_ATTRIBUTE` rows themselves
to already be PostgreSQL-compatible -- see `?fix_oracle_syntax`. Most
users will never need it.)

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

Current version: **0.0.3**

The package currently passes:

- R CMD check: 0 errors
- R CMD check: 0 warnings
- R CMD check: 0 notes

## Authors

Phil Radtke, Aakriti Sapkota, David Walker

Virginia Tech
