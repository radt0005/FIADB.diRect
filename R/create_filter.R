#' Create an FIA SQL Filter Expression
#'
#' Constructs an SQL WHERE-clause filter expression from user-specified
#' FIA variable names, values, comparison operators, and logical
#' connectors.
#'
#' This function simplifies the creation of filter conditions used by
#' \code{GB_est()}, \code{PLOT_obs()}, \code{TREE_obs()}, and related
#' functions. Variable names are automatically matched to the
#' appropriate FIA database tables.
#'
#' @details
#' If \code{VAR_NAMES} contains a single variable, then
#' \code{VAR_VALUES}, \code{VAR_CONDS}, and \code{VAR_BOOLS} may be
#' supplied as vectors.
#'
#' \preformatted{
#' VAR_NAMES  = "OWNGRPCD"
#' VAR_VALUES = c(10, 20, 30, 40)
#' VAR_CONDS  = c("=", "=", "!=", ">=")
#' VAR_BOOLS  = c("OR", "OR", "OR")
#' }
#'
#' If \code{VAR_NAMES} contains multiple variables, then
#' \code{VAR_VALUES}, \code{VAR_CONDS}, and \code{VAR_BOOLS} should be
#' supplied as lists with one element per variable.
#'
#' \preformatted{
#' VAR_NAMES  = c("OWNGRPCD", "DIA")
#' VAR_VALUES = list(
#'   OWNGRPCD = c(10,20,30),
#'   DIA      = c(15,25)
#' )
#' }
#'
#' @param VAR_NAMES Character vector of FIA variable names to be used
#'   in the filter expression.
#' @param VAR_VALUES Values associated with \code{VAR_NAMES}.
#' @param VAR_CONDS Character vector of comparison operators.
#' @param VAR_BOOLS Optional logical operators used to combine filter
#'   conditions.
#' @param dbname PostgreSQL database name.
#'
#' @return
#' A character string containing a valid SQL filter expression suitable
#' for use in FIA database queries.
#'
#' @examples
#' \dontrun{
#' create_filter(
#'   VAR_NAMES = c("STATUSCD", "OWNGRPCD"),
#'   VAR_VALUES = c(1, 40),
#'   VAR_CONDS = c("=", "="),
#'   VAR_BOOLS = "AND"
#' )
#' }
#'
#' @export

create_filter <- function(VAR_NAMES, VAR_VALUES, VAR_CONDS, VAR_BOOLS = NA,dbname = "fiadb"){
  TABLE_VAR_REF <- get_TABLE_VAR_REF(dbname)
  if (exists("con")) {warning("The connection already exists") #Aakriti 09/10/2024
  }else{
    con <- FIAdb_connect(dbname)}
  VAR_NAMES = toupper(VAR_NAMES)
  # length(VAR_NAMES)
  # todo: error trap for length(VAR_NAMES) == length(VAR_VALUES)
  # todo: error trap for length(VAR_NAMES) == length(VAR_CONDS)
  # todo: error trap for length(VAR_NAMES) == length(VAR_BOOLS)
  # todo: move VAR_NAMES_table inside of if/else brackets 
  VAR_NAMES_table = array(data=NA,dim=length(VAR_NAMES))
  if(length(VAR_NAMES) > 1){
    names(VAR_VALUES) <- VAR_NAMES
    names(VAR_CONDS) <- VAR_NAMES
    #names(VAR_BOOLS) <- VAR_NAMES
    for(x in 1:length(VAR_NAMES)){
      VAR_NAMES_table[x] <- 
        paste0(TABLE_VAR_REF$TABLE[TABLE_VAR_REF$VAR_NAME == VAR_NAMES[x]],
               '.',VAR_NAMES[x])
    }
    filter_script = array(data=NA,dim=length(VAR_NAMES))
    for(x in 1:length(VAR_NAMES)){
      #VAR_BOOLS[x] = toupper(VAR_BOOLS[x])
      filter_script[x] <- paste0("AND (",
                            paste(VAR_NAMES_table[x], 
                                  VAR_CONDS[[x]],
                                  VAR_VALUES[[x]],
                                  collapse=paste0(' ',VAR_BOOLS[[x]],' ')),')')
    }
    filter_script <- paste0(filter_script,collapse=' ')
    if ("NA" %in% strsplit(filter_script, " ")[[1]]) {
      stop('ERROR : VAR_BOOLS is missing values.')}
  }else{
    # VAR_CONDS = toupper(VAR_CONDS)
    # VAR_VALUES
    #VAR_BOOLS = toupper(VAR_BOOLS)
    VAR_NAMES_table = array(data=NA,dim=length(VAR_NAMES))
    for(x in 1:length(VAR_NAMES)){
      VAR_NAMES_table[x] <- 
        paste0(TABLE_VAR_REF$TABLE[TABLE_VAR_REF$VAR_NAME == VAR_NAMES[x]],
               '.',VAR_NAMES[x])
    }
    filter_script <- paste0("AND (",
                            paste(VAR_NAMES_table, 
                                  VAR_CONDS,
                                  VAR_VALUES,
                                  collapse=paste0(' ',VAR_BOOLS,' ')),')')
    if ("NA" %in% strsplit(filter_script, " ")[[1]]) {
      stop('ERROR : VAR_BOOLS is missing values.')}}
  DBI::dbDisconnect(con) #Aakriti 09/10/2024
  rm(con)  #Aakriti 09/10/2024
  return(filter_script)
}


