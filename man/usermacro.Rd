% Minimal demo: user-defined macros only.
% Callable as ?usermacro. The macros are defined in man/macros/gsoc-macros.Rd
% and each expansion is tagged USERMACRO in the parse tree (attr "macro" keeps
% the macro name), surviving into the installed .rdb.
\name{usermacro}
\alias{usermacro}
\title{User-defined macros}
\description{
Zero-argument macro: \gsoc{}

Macro that expands to other markup: \pkgenv{}

Macro that takes an argument: \deadlineNote{2025-03-31}
}
\keyword{internal}
