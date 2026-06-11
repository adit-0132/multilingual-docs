% Scratch playground -- edit freely, then re-run in the R console:
%   walk_rd_file("test.Rd")    # raw source tree (nothing baked)
%   walk_rdb_file("test.Rd")   # baked rdb-equivalent tree
% (no save-reinstall needed; both re-read this file from disk each call)
\name{test}
\alias{test}
\title{Scratch test page}
\description{
Plain prose to edit.
A render Sexpr:  \Sexpr[results=text,stage=render]{ 1 + 1 }
A build Sexpr : \Sexpr[results=text,stage=build]{ "build-stage output (baked at build time)"}
An install Sexpr: \Sexpr[results=text,stage=install]{ paste("R", getRversion()) }
Wrapped install->render (computes at install, leaves a LIVE render-node trace in
the .rdb; note R does not re-evaluate the emitted node, so it renders literally):
\Sexpr[results=rd,stage=install]{ paste0("\\\\Sexpr[results=text,stage=render]{\"R ", getRversion(), "\"}") }
A user macro: \gsoc{}
A platform conditional:
#ifdef windows
Windows-only line.
#endif
#ifndef windows
Non-Windows line.
#endif
}
\keyword{internal}
