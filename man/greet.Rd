% Clean translation-demo topic: static sections (should translate) plus one
% section containing \Sexpr (the translator sees the Sexpr as text).
\name{greet}
\alias{greet}
\title{Greet the mentors}
\description{
Returns a friendly greeting. This paragraph is plain static prose with no
dynamic content, so it should translate cleanly into another language.
}
\details{
The current date is \Sexpr[results=text,stage=render]{ format(Sys.Date()) } and
this package was installed under \Sexpr[results=text,stage=install]{ paste("R", getRversion()) }.
Because this paragraph embeds Sexpr macros, the translator sees them as text.
}
\value{
A length-one character string containing the greeting.
}
\keyword{internal}
