% Stress fixture: render + install + static text interleaved in one section.
\name{stress_mixed}
\alias{stress_mixed}
\title{Stress: render + install + static}
\description{
Static intro. Live render value: \Sexpr[results=text,stage=render]{ format(Sys.Date()) }.
Install value: \Sexpr[results=text,stage=install]{ paste0("v", getRversion()) }.
Static outro after both.
}
\keyword{internal}
