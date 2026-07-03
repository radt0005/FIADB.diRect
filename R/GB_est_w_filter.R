# GB_est_w_filter.R provides a convenience wrapper for generating
# FIA Green Book estimates using user-specified filter criteria.

#' Calculate FIA Green Book Estimates with Filters
#'
#' Generates FIA Green Book estimates for a specified evaluation group
#' and attribute using filter criteria supplied as variable names,
#' values, comparison operators, and logical connectors.
#'
#' This function simplifies filtered analyses by constructing the
#' required SQL filter expression and passing it to \code{GB_est()}.
#'
#' @param EVAL_GRP FIA evaluation group identifier. Integer of the form
#'   SSYYYY, where SS is the two-digit state FIPS code and YYYY is the
#'   evaluation year.
#' @param ATTRIBUTE_NBR FIA attribute number.
#' @param GRP_BY_ATTRIB Character vector of FIA variables used to group
#'   the estimates.
#' @param VAR_NAMES Character vector of FIA variable names used in the
#'   filter specification.
#' @param VAR_VALUES Values associated with \code{VAR_NAMES}.
#' @param VAR_CONDS Character vector of comparison operators (for
#'   example, \code{"="}, \code{">"}, or \code{"IN"}).
#' @param VAR_BOOLS Optional logical operators used to combine filter
#'   conditions (for example, \code{"AND"} or \code{"OR"}).
#' @param SCHEMA PostgreSQL schema containing the FIA tables.
#' @param dbname PostgreSQL database name.
#'
#' @return
#' A data frame containing FIA Green Book estimates and associated
#' summary statistics.
#'
#' @examples
#' \dontrun{
#' GB_est_w_filter(
#'   EVAL_GRP = 102019,
#'   ATTRIBUTE_NBR = 2,
#'   GRP_BY_ATTRIB = "STATECD",
#'   VAR_NAMES = "STATUSCD",
#'   VAR_VALUES = 1,
#'   VAR_CONDS = "="
#' )
#' }
#'
#' @export

GB_est_w_filter <- function(EVAL_GRP, ATTRIBUTE_NBR, GRP_BY_ATTRIB="STATECD", SCHEMA = "FS_FIADB",VAR_NAMES = NA, VAR_VALUES = NA, VAR_CONDS = NA, VAR_BOOLS = NA,dbname = "fiadb"){ 
  #Aakriti 01/13/2025
    if (exists("con")) {warning("The connection already exists") 
    }else{
      con <- FIAdb_connect(dbname)
    }
  VAR_NAMES <- toupper(VAR_NAMES)
  GRP_BY_ATTRIB <- toupper(GRP_BY_ATTRIB)
  #adding VAR_NAMES IN GRP_BY_ATTRIB
  if (all(VAR_NAMES %in% GRP_BY_ATTRIB)){
    GRP_BY_ATTRIB <- GRP_BY_ATTRIB
  #   #this is added to remove NA in GRP_BY_ATTRIB
  # } else if (is.na(VAR_NAMES)){
  #   GRP_BY_ATTRIB <- GRP_BY_ATTRIB
  #
    } 
  else{
    GRP_BY_ATTRIB <- c(GRP_BY_ATTRIB, VAR_NAMES)
  }
  #REMOVING THE VALUES THAT ARE REPEATED
  GRP_BY_ATTRIB <- unique(GRP_BY_ATTRIB)
  if(any(is.na(GRP_BY_ATTRIB))){
    GRP_BY_ATTRIB <- GRP_BY_ATTRIB[!is.na(GRP_BY_ATTRIB)] #removes NA if there is any 09/09/2024
  }
  FILTER_NONE <- ""
  if (any(is.na(c(VAR_NAMES, VAR_VALUES, VAR_CONDS)))){
    FILTER <- FILTER_NONE
  } else {
    #calling create_filter function to get sql code required for filtering
    FILTER <- create_filter(VAR_NAMES, VAR_VALUES, VAR_CONDS, VAR_BOOLS)
  }
  query_result <- GB_est(EVAL_GRP,ATTRIBUTE_NBR,GRP_BY_ATTRIB, FILTER = FILTER)
  return(query_result)
}



