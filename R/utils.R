# Internal utility: returns x unless x is NULL
`%||%` <- function(x, y) if (is.null(x)) y else x

