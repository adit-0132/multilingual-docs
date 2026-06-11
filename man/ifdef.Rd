% Minimal demo: a single #ifdef ... #endif conditional, nothing else.
% Callable as ?ifdef. The block is kept ONLY on Windows; on Unix/macOS it is
% dropped at install time (resolved before the .rdb is written).
\name{ifdef}
\alias{ifdef}
\title{Conditional: #ifdef windows}
\description{
Text immediately below appears only on Windows:
#ifdef windows
THIS LINE IS WINDOWS-ONLY.
#endif
Text after the conditional always appears.
}
\keyword{internal}
