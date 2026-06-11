% Minimal demo: a single build-stage \Sexpr, nothing else.
% Callable as ?sexpr_build. Build stage runs at R CMD build and is baked to
% plain TEXT -- it is NOT a live \Sexpr node in the installed .rdb.
\name{sexpr_build}
\alias{sexpr_build}
\title{Sexpr: stage = build}
\description{
Output below comes from a build-stage Sexpr (baked to text):

\Sexpr[results=text,stage=build]{ "build-stage output (baked at build time)" }
}
\keyword{internal}
