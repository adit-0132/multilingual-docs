#' @keywords internal
#'
#' Package-level environment for internal state.
#'
#' \code{.pkg_env$deadline} holds the GSoC submission deadline as a
#' \code{Date} object. Storing the deadline here rather than as a bare global
#' avoids namespace pollution and makes the value easy to update in a single
#' location.
.pkg_env <- new.env(parent = emptyenv())

#' Submission deadline
#'
#' A \code{Date} object representing the final day on which a proposal may be
#' submitted. Modify this value to update the deadline across all functions and
#' documentation without touching individual source files.
#'
#' @format A \code{Date} of length 1.
#' @keywords internal
.pkg_env$deadline <- as.Date("2025-03-31")
