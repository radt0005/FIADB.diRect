#' Connect to an FIA PostgreSQL Database
#'
#' Creates a connection to an FIA PostgreSQL database using the
#' supplied database name and user credentials.
#'
#' @param dbname PostgreSQL database name.
#'
#' @return A DBI database connection object.
#'
#' @importFrom DBI dbConnect dbDriver
#'
#' @keywords internal
FIAdb_connect <- function(dbname = "fiadb") {

  drv <- DBI::dbDriver("PostgreSQL")

  con <- DBI::dbConnect(
    drv,
    dbname = dbname
  )

  if (!exists("con")) {

    con <- DBI::dbConnect(
      drv,
      dbname = "fiadb",
      host = "localhost",
      port = 5432,
      user = "postgres",
      password = rstudioapi::askForPassword()
    )
  }

  con
}
