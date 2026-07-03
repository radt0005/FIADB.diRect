# read_TABLE_VAR_REF.R creates a lookup table that associates FIA
# variable names with their corresponding database tables.

#' Build FIA Variable-to-Table Lookup Information
#'
#' Creates a lookup table that maps FIA variable names to the FIA
#' database tables in which they occur.
#'
#' The lookup table is used internally by package functions to identify
#' the appropriate FIA table when constructing SQL queries and filter
#' expressions.
#'
#' Variable names are obtained directly from the database metadata,
#' ensuring consistency with the connected FIA database.
#'
#' @param dbname PostgreSQL database name.
#'
#' @return
#' A data frame with one row per FIA variable containing:
#' \describe{
#'   \item{TABLE}{FIA table containing the variable.}
#'   \item{VAR_NAME}{Name of the FIA variable.}
#' }
#'
#' @examples
#' \dontrun{
#' tbl_ref <- get_TABLE_VAR_REF()
#' head(tbl_ref)
#' }
#'
#' @keywords internal

get_TABLE_VAR_REF <- function(dbname = "fiadb") {

  con <- FIAdb_connect(dbname)

  on.exit(DBI::dbDisconnect(con))

  plot <- "select * from fs_fiadb.plot where false;"
  plot_var_names <- names(getQuery(plot, con))

  TABLE_VAR_REF <- data.frame(
    TABLE = "PLOT",
    VAR_NAME = plot_var_names
  )

  cond <- "select * from fs_fiadb.cond where false;"
  cond_var_names <- names(getQuery(cond, con))

  cond_var_names <- cond_var_names[
    !(cond_var_names %in% plot_var_names)
  ]

  TABLE_VAR_REF <- dplyr::bind_rows(
    TABLE_VAR_REF,
    data.frame(
      TABLE = "COND",
      VAR_NAME = cond_var_names
    )
  )

  tree <- "select * from fs_fiadb.tree where false;"
  tree_var_names <- names(getQuery(tree, con))

  tree_var_names <- tree_var_names[
    !((tree_var_names %in% plot_var_names) |
      (tree_var_names %in% cond_var_names))
  ]

  TABLE_VAR_REF <- dplyr::bind_rows(
    TABLE_VAR_REF,
    data.frame(
      TABLE = "TREE",
      VAR_NAME = tree_var_names
    )
  )

  return(TABLE_VAR_REF)
}

