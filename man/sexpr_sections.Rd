% Demo: dynamic \Sexpr living in sections OTHER than the description --
% inside an \arguments item and in \value -- plus a non-windows #ifdef.
% Fills the gaps not covered by the other demo pages.
\name{sexpr_sections}
\alias{sexpr_sections}
\title{Sexpr in arguments and value}
\description{
Shows install-stage Sexpr macros in help sections beyond the description.
#ifdef unix
This note is shown only on Unix and macOS (a non-Windows conditional).
#endif
The rest of the description always appears, on every platform.
}
\arguments{
  \item{mode}{One of \Sexpr[results=text,stage=install]{ paste(c("fast", "safe", "debug"), collapse = ", ") }. An install-stage Sexpr inside an argument description, like a package documenting its allowed option values.}
  \item{x}{A plain static argument, for contrast.}
}
\value{
A greeting string, produced under \Sexpr[results=text,stage=install]{ R.version.string }.
}
\examples{
1 + 1
}
\keyword{internal}
