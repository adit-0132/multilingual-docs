% Stress fixture (task 2): multi-line install \Sexpr, with and without braces in code.
\name{stress_multiline}
\alias{stress_multiline}
\title{Stress: multi-line install Sexpr}
\description{
Multi-line code, no braces in the body:
\Sexpr[results=text,stage=install]{
  paste("R",
        getRversion())
}.

Multi-line code WITH nested braces (if/else) — this is what truncates a naive
\verb{\{[^\}]*\}} regex:
\Sexpr[results=text,stage=install]{
  if (nchar("abc") > 0) {
    "nonempty"
  } else {
    "empty"
  }
}.
}
\keyword{internal}
