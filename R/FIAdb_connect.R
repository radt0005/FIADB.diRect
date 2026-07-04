# Null-coalescing operator: returns x if not NULL, otherwise y
`%||%` <- function(x, y) if (is.null(x)) y else x

#' Connect to an FIA PostgreSQL Database
#'
#' Creates a connection to an FIA PostgreSQL database. Connection parameters
#' are resolved in the following order of precedence:
#' \enumerate{
#'   \item Explicit function arguments
#'   \item Environment variables (\code{FIADB_HOST}, \code{FIADB_PORT},
#'         \code{FIADB_USER}, \code{FIADB_PASSWORD})
#'   \item Built-in defaults (\code{localhost}, \code{5432})
#' }
#'
#' This resolution order allows the function to work in multiple execution
#' contexts without code changes: interactively in RStudio (using defaults
#' or explicit arguments), from the command line (using environment
#' variables), or inside a sandboxed Spade block (using environment
#' variables passed through the sandbox).
#'
#' @param dbname Character string. PostgreSQL database name. Default
#'   \code{"fiadb"}.
#' @param host Character string or \code{NULL}. PostgreSQL server hostname.
#'   If \code{NULL}, auto-detects whether to use Unix socket or TCP based
#'   on socket availability. Falls back to \code{FIADB_HOST} environment
#'   variable, then \code{"localhost"} when TCP is used.
#' @param port Integer or \code{NULL}. PostgreSQL server port. If
#'   \code{NULL}, falls back to the \code{FIADB_PORT} environment
#'   variable, then \code{5432}.
#' @param user Character string. PostgreSQL username. Falls back to the
#'   \code{USER} environment variable, then \code{"postgres"}.
#' @param password Character string. PostgreSQL password. Falls back to the
#'   \code{FIADB_PASSWORD} environment variable, then empty string.
#'   Avoid hardcoding passwords in pipeline YAML files or scripts that
#'   may be committed to version control.
#'
#' @return A DBI database connection object.
#'
#' @seealso \code{\link[DBI]{dbConnect}}, \code{\link{GB_est}}
#'
#' @importFrom DBI dbConnect dbDriver
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#'   # Using defaults - auto-detects Unix socket or TCP
#'   con <- FIAdb_connect()
#'
#'   # Explicit TCP connection
#'   con <- FIAdb_connect(host = "localhost", user = "pradtke")
#'
#'   # Using environment variables
#'   Sys.setenv(FIADB_HOST = "myserver", FIADB_USER = "postgres")
#'   con <- FIAdb_connect()
#' }

FIAdb_connect <- function(dbname = "fiadb",
                           host = NULL,
                           port = NULL,
                           user = Sys.getenv("USER", unset = "postgres"),
                           password = Sys.getenv("FIADB_PASSWORD", unset = "")) {

  # Auto-detect whether Unix socket is available.
  # Falls back to TCP if socket doesn't exist (e.g. inside Spade sandbox)
  # or if host is explicitly supplied.
  socket_path <- "/var/run/postgresql"
  use_tcp <- !file.exists(socket_path) || !is.null(host)

  if (use_tcp) {
    DBI::dbConnect(
      DBI::dbDriver("PostgreSQL"),
      dbname   = dbname,
      host     = host %||% Sys.getenv("FIADB_HOST", unset = "localhost"),
      port     = as.integer(port %||% Sys.getenv("FIADB_PORT", unset = "5432")),
      user     = user,
      password = password
    )
  } else {
    # Unix socket connection - peer auth, no password needed
    DBI::dbConnect(
      DBI::dbDriver("PostgreSQL"),
      dbname = dbname,
      user   = user
    )
  }
}
