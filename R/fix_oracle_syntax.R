# fix_oracle_syntax.R handles Oracle-specific SQL syntax embedded in the
# REF_POP_ATTRIBUTE reference table so that stored query templates run
# correctly against a PostgreSQL backend.
#
# Some FIA DataMart downloads have SQL_QUERY/SQL_QUERY_SE templates that use
# Oracle's alternative quoting operator, Q'[...]', to safely embed the
# substituted &FILTER text even when it contains single quotes; other
# (older/past) downloads don't. PostgreSQL has no equivalent operator, so an
# un-rewritten Q'[...]' fails with an error like `ERROR: type "q" does not
# exist` once &FILTER is substituted in.
#
# normalize_oracle_quoting() (below) is the fix that actually matters day to
# day: GB_est()/TREE_obs()/PLOT_obs() call it automatically on the query text
# in R memory, immediately after reading it from Postgres and before any
# placeholder substitution -- so both %Q and non-%Q downloads work
# transparently, with no setup step, and the row stored in Postgres is never
# touched. That was a deliberate design choice: other, unrelated scripts
# querying Postgres directly should still be able to assume REF_POP_ATTRIBUTE
# matches the DataMart download exactly, native format and all.
#
# fix_oracle_syntax() (further below) predates that and takes the opposite
# approach -- it permanently rewrites the stored rows via UPDATE. It's no
# longer required for FIADB.diRect to work and isn't part of setup anymore;
# see its own docs for why you'd still reach for it.

#' Normalize Oracle \code{Q'[...]'} Quoting In-Memory
#'
#' Rewrites any \code{Q'[...]'} occurrences in a SQL query string to
#' PostgreSQL's dollar-quoting syntax, \code{$$...$$}, which behaves
#' equivalently (a literal string that safely tolerates embedded single
#' quotes). Operates purely on the R string passed in -- it never reads
#' or writes anything in PostgreSQL. If \code{sql_text} has no
#' \code{Q'[...]'} pattern (e.g. an older DataMart download that never
#' used it), it's returned unchanged.
#'
#' This is what \code{\link{GB_est}}, \code{\link{TREE_obs}}, and
#' \code{\link{PLOT_obs}} call automatically on \code{SQL_QUERY_SE}
#' right after reading it from \code{REF_POP_ATTRIBUTE} and before
#' substituting \code{&FILTER} and friends -- so every caller is handled
#' transparently regardless of which DataMart-quoting style was
#' downloaded, with no setup step and no change to what's stored in
#' Postgres.
#'
#' @param sql_text Character. A SQL query/template string (may contain
#'   zero, one, or more \code{Q'[...]'} occurrences).
#'
#' @return Character. \code{sql_text} with any \code{Q'[...]'} rewritten
#'   to \code{$$...$$}.
#'
#' @keywords internal
normalize_oracle_quoting <- function(sql_text) {
  gsub("Q'\\[(.*?)\\]'", "$$\\1$$", sql_text, ignore.case = TRUE, perl = TRUE)
}

#' Permanently Rewrite Oracle-Style Quoting Stored in REF_POP_ATTRIBUTE
#'
#' \strong{Not required for FIADB.diRect to work} -- \code{\link{GB_est}}
#' and friends now handle \code{Q'[...]'} quoting automatically and
#' transparently via \code{\link{normalize_oracle_quoting}}, entirely in
#' R memory, without touching anything in Postgres. This function
#' predates that and takes the opposite approach: it permanently
#' rewrites the \code{SQL_QUERY}/\code{SQL_QUERY_SE} columns in the
#' \code{REF_POP_ATTRIBUTE} table itself via \code{UPDATE}, so Postgres's
#' copy will no longer match the DataMart download's native format.
#'
#' Reach for this only if something \emph{other than} FIADB.diRect reads
#' \code{REF_POP_ATTRIBUTE} directly and needs the stored text to
#' already be PostgreSQL-compatible (e.g. a non-R tool without its own
#' equivalent of \code{normalize_oracle_quoting}). If you're only using
#' FIADB.diRect's own functions, you don't need to run this at all.
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
    as.integer(DBI::dbGetQuery(con, q)$n)
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
