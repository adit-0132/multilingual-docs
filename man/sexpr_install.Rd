% Minimal demo: a single install-stage \Sexpr, nothing else.
% Callable as ?sexpr_install. Install stage runs once at R CMD INSTALL and is
% baked into the .rdb as plain TEXT -- NOT a live \Sexpr node afterwards.
\name{sexpr_install}
\alias{sexpr_install}
\title{Sexpr: stage = install}
\description{
Output below comes from an install-stage Sexpr (baked to text at install):

\Sexpr[results=text,stage=install]{ paste("installed under R", getRversion()) }
}
\keyword{internal}
