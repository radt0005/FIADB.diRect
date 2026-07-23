# fix_oracle_syntax.R repairs Oracle-specific SQL syntax embedded in the
# REF_POP_ATTRIBUTE reference table so that stored query templates run
# correctly against a PostgreSQL backend.

#' Repair Oracle-Style Quoting in REF_POP_ATTRIBUTE
#'
#' The \code{REF_POP_ATTRIBUTE} FIA reference table stores SQL query
#' templates (in \code{SQL_QUERY} and \code{SQL_QUERY_SE}) that were
#' originally authored against an Oracle-based FIADB / EVALIDator
#' backend. Some of these templates use Oracle's alternative quoting
#' operator, \code{Q'[...]'}, to safely embed the substituted
#' \code{&FILTER} text as an output column even when the filter text
#' contains single quotes. PostgreSQL has no equivalent operator, so
#' when \code{FIADB.diRect} functions (e.g. \code{\link{GB_est}})
#' substitute an empty or non-empty \code{FILTER} into these templates,
#' PostgreSQL fails with an error such as:
#' \code{ERROR:  type "q" does not exist}.
#'
#' This function rewrites any occurrences of \code{Q'[&FILTER]'} in the
#' \code{SQL_QUERY} and \code{SQL_QUERY_SE} columns to PostgreSQL's
#' dollar-quoting syntax, \code{$$&FILTER$$}, which behaves equivalently
#' (a literal string that safely tolerates embedded single quotes) and
#' is valid PostgreSQL syntax after \code{&FILTER} substitution.
#'
#' This is intended to be run once, after loading FIA reference data
#' into a PostgreSQL \code{REF_POP_ATTRIBUTE} table, and before using
#' functions such as \code{\link{GB_est}} or
#' \code{\link{GB_est_w_filter}}.
#'
#' @param dbname Character string. PostgreSQL database name. Default
#'   \code{"fiadb"}.
#' @param SCHEMA Character string. PostgreSQL schema containing the FIA
#'   reference tables. Default \code{"FS_FIADB"}.
#' @param dry_run Logical. If \code{TRUE} (the default), no changes are
#'   made; the function only reports how many rows in each column would
#'   be affected. Set to \code{FALSE} to apply the fix.
#'
#' @return
#' Invisibly, a named integer vector with the number of affected (or
#' updated) rows in \code{SQL_QUERY} and \code{SQL_QUERY_SE}.
#'
#' @examples
#' \dontrun{
#'   # Check how many rows would be affected, without changing anything
#'   fix_oracle_syntax(dry_run = TRUE)
#'
#'   # Apply the fix
#'   fix_oracle_syntax(dry_run = FALSE)
#' }
#'
#' @export
fix_oracle_syntax <- function(dbname = "fiadb",
                               SCHEMA = "FS_FIADB",
                               dry_run = TRUE) {

  con <- FIAdb_connect(dbname)
  on.exit({
    DBI::dbDisconnect(con)
  })

  table_ref <- paste0(SCHEMA, ".REF_POP_ATTRIBUTE")
  pattern   <- "Q'[&FILTER]'"
  old_str   <- "Q''[&FILTER]''"
  new_str   <- "$$&FILTER$$"

  count_affected <- function(column) {
    q <- paste0(
      "SELECT COUNT(*) AS N FROM ", table_ref,
      " WHERE ", column, " LIKE '%Q''[%'"
    )
    DBI::dbGetQuery(con, q)$n
  }

  n_query_before    <- count_affected("SQL_QUERY")
  n_query_se_before <- count_affected("SQL_QUERY_SE")

  if (dry_run) {
    message(sprintf(
      "[dry run] %d row(s) in SQL_QUERY and %d row(s) in SQL_QUERY_SE contain Oracle-style Q'[...]' quoting.\nRe-run with dry_run = FALSE to apply the fix.",
      n_query_before, n_query_se_before
    ))
    return(invisible(c(SQL_QUERY = n_query_before, SQL_QUERY_SE = n_query_se_before)))
  }

  update_column <- function(column) {
    q <- paste0(
      "UPDATE ", table_ref,
      " SET ", column, " = REPLACE(", column, ", '", old_str, "', '", new_str, "')",
      " WHERE ", column, " LIKE '%Q''[%'"
    )
    DBI::dbExecute(con, q)
  }

  n_query_updated    <- update_column("SQL_QUERY")
  n_query_se_updated <- update_column("SQL_QUERY_SE")

  message(sprintf(
    "Updated %d row(s) in SQL_QUERY and %d row(s) in SQL_QUERY_SE.",
    n_query_updated, n_query_se_updated
  ))

  invisible(c(SQL_QUERY = n_query_updated, SQL_QUERY_SE = n_query_se_updated))
}
