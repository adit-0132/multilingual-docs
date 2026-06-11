% Minimal demo: a single #ifndef ... #endif conditional, nothing else.
% Callable as ?ifndef. The block is kept on every platform EXCEPT Windows;
% the choice is resolved at install time before the .rdb is written.
\name{ifndef}
\alias{ifndef}
\title{Conditional: #ifndef windows}
\description{
Text immediately below appears on everything except Windows:
#ifndef windows
THIS LINE IS SHOWN ON UNIX AND MACOS (NOT WINDOWS).
#endif
Text after the conditional always appears.
}
\keyword{internal}
