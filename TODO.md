# FIADB.diRect — TODO

## Group-by / filter variables from tables other than PLOT, COND and TREE
*Noted 2026-10-03 (with Claude, during NPS_Biomass work). To address in a future session.*

**Need:** grouping or filtering by `ECOSUBCD` (ECOMAP subsection, and from it province or
division). In FIADB, `ECOSUBCD` is in the **PLOTGEOM** table (`PLOTGEOM.CN = PLOT.CN`), not
PLOT, so it can't currently be used in `GRP_BY_ATTRIB` or the `VAR_NAMES` filters. The
workaround so far is to fetch it separately with `GET_record("PLOTGEOM", "CN", plt_cn)` and
join it in R (see `NPS_Biomass/R/FIA_height_benchmarks.R`).

**Why it doesn't work now:** `get_TABLE_VAR_REF()` (R/read_TABLE_VAR_REF.R) builds the
variable-to-table lookup from **PLOT, COND and TREE only**, and the SQL that `PLOT_obs()`,
`TREE_obs()` and `GB_est()` build (from `REF_POP_ATTRIBUTE` templates) only joins those tables.

**What it would take (to scope):**
- Add PLOTGEOM (and possibly other plot-level tables) to `get_TABLE_VAR_REF()`, keeping the
  rule that a name already found in an earlier table isn't duplicated.
- Add the matching JOIN (e.g. `JOIN FS_FIADB.PLOTGEOM PLOTGEOM ON PLOTGEOM.CN = PLOT.CN`)
  only when a requested group-by or filter variable comes from that table.
- Decide which functions get it: `PLOT_obs()`, `TREE_obs()`, `GB_est()` and their `_w_filter`
  wrappers, and `create_filter()`, all resolve variables through `get_TABLE_VAR_REF()`.
- Derived groupings: province/division from `ECOSUBCD` (e.g. a `PROVINCE` pseudo-variable via
  SQL string functions, or done in R after the query).

**Other candidate variables/tables to review:** PLOTGEOM (`ECOSUBCD`, `CONGCD`, `HUC`,
`FVS_VARIANT`, `ROADLESSCD`, …); `POP_STRATUM`/`POP_ESTN_UNIT` attributes; SEEDLING;
`REF_SPECIES` attributes such as `JENKINS_SPGRPCD` or `SFTWD_HRDWD` for TREE-level grouping.

## Other notes from 2026-10-03
- `man/*.Rd` not yet regenerated after the doc-comment edit to `PLOT_obs_w_filter()`
  ("plot-level observations, not actual PLOT table records"): run `roxygen2::roxygenise()`.
- Version is still 0.0.2 after the `dbname`/`SCHEMA` pass-through fix (commit e1095e0);
  consider bumping to 0.0.3.
- The `_w_filter` wrappers open a connection (`con <- FIAdb_connect(dbname)`) that is never
  used or closed.
- `FIAdb_connect()` uses the local socket with `FIADB_USER` as the database user; where
  `FIADB_USER` differs from the login name (e.g. `spade` set in `.bashrc`), PostgreSQL peer
  authentication refuses the connection.
