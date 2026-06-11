% Minimal demo: a single render-stage \Sexpr, nothing else.
% Callable as ?sexpr_render. Render stage runs every time the page is opened and
% stays a LIVE \Sexpr node in the installed .rdb (re-evaluated each lookup).
% Re-run ?sexpr_render to see the timestamp change.
\name{sexpr_render}
\alias{sexpr_render}
\title{Sexpr: stage = render}
\description{
Output below comes from a render-stage Sexpr (recomputed live on each lookup):

\Sexpr[results=text,stage=render]{ format(Sys.time()) }
}
\keyword{internal}
