# getQuery.R executes SQL queries against an FIA PostgreSQL database
# connection and returns the results.

#' Execute an FIA Database Query
#'
#' Executes an SQL query using an existing database connection and
#' returns the results as a data frame.
#'
#' This function is primarily intended for internal package use and is
#' used by other functions when retrieving FIA database records and
#' metadata.
#'
#' @param query Character string containing a valid SQL query.
#' @param con A DBI database connection object.
#'
#' @return
#' A data frame containing the results of the SQL query.
#'
#' @examples
#' \dontrun{
#' con <- FIAdb_connect()
#'
#' getQuery(
#'   "SELECT * FROM fs_fiadb.plot LIMIT 10",
#'   con
#' )
#' }
#'
#' @keywords internal

getQuery <- function(query,con) {
  
  out <- DBI::dbGetQuery(con, query)
  
  names(out) <- toupper(names(out))
  
  return(out)
  
}
