## GET_record.R retrieves records from FIA database tables.

#' Retrieve FIA Database Records
#'
#' Retrieves records from FIA PostgreSQL database tables for a specified
#' evaluation group and FIA attribute. Optional filters and joins may be
#' supplied to restrict the records returned.
#'
#' This function is intended for obtaining the underlying FIA records
#' associated with a particular estimate or analysis.
#'
#' @param TABLE_NAME FIA table name.
#' @param VAR_NAME FIA variable name used for record selection.
#' @param VAR_VALUES Value or vector of values used to identify records.
#' @param SCHEMA PostgreSQL schema containing the FIA tables.
#' @param dbname PostgreSQL database name.
#'
#' @return
#' A data frame containing the records returned by the FIA database
#' query.
#'
#' @examples
#' \dontrun{
#' GET_record(
#'   EVAL_GRP = 102019,
#'   ATTRIBUTE_NBR = 2
#' )
#' }
#'
#' @export

GET_record <- function(TABLE_NAME, VAR_NAME, VAR_VALUES, SCHEMA = "FS_FIADB", dbname = "fiadb"){ #Aakriti 09/10/2024
  # check for existing connection and either print a warning or create a new con
  if (exists("con")) {warning("Warning! previous connection exists! Disconnecting...") 
  }else{
    con <- FIAdb_connect(dbname)
  }
  TABLE_NAME <- toupper(TABLE_NAME)
  VAR_NAME <- toupper(VAR_NAME)
  sql_query1 <- "SELECT * FROM &SCHEMA.&TABLE WHERE &TABLE.&VAR_NAME IN (&VAR_VALUES)"
  sql_query2 <- gsub("&SCHEMA", SCHEMA, sql_query1)
  sql_query3 <- gsub("&TABLE", TABLE_NAME, sql_query2)
  sql_query4 <- gsub("&VAR_NAME", VAR_NAME, sql_query3)
  if (length(VAR_VALUES) > 1){
    VAR_VALUES <- paste0( "'",VAR_VALUES,"'",collapse = ', ')
  }else {
    VAR_VALUES <- paste0( "'",VAR_VALUES,"'")
    }
  sql_query5 <- gsub("&VAR_VALUES", VAR_VALUES, sql_query4)
  result <- getQuery(sql_query5,con) #Aakriti 09/10/2024
  # check for existing connection and disconnect from it
  DBI::dbDisconnect(con ) #Aakriti 09/10/2024
  rm(con)  #Aakriti 09/10/2024
  return(result)  
}




