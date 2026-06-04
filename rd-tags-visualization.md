# `parse_Rd()` Tag Visualization for `submit_proposal.Rd`

> **How to read this:** Each top-level element returned by `parse_Rd()` gets one
> `Rd_tag` attribute. There are **50 elements** in the parsed list. This file
> maps every one of them back to the source `.Rd` file so you can see exactly
> what the parser produces.
>
> To suppress the "unknown macro" warnings, pass the macros file:
> ```r
> rd <- parse_Rd(infile, macros = "multilingual-docs/man/macros/gsoc-macros.Rd")
> ```

---

## Legend

| Color | Tag type | Meaning |
|-------|----------|---------|
| :red_circle: **Red** | `COMMENT` | Lines starting with `%` (Rd comments) |
| :white_circle: **Grey** | `TEXT` | Whitespace / newlines between top-level elements |
| :blue_circle: **Blue** | `\name`, `\alias`, `\encoding`, `\title`, `\keyword`, `\concept` | Simple sectioning macros (single argument) |
| :green_circle: **Green** | `\usage`, `\arguments`, `\description`, `\details`, `\value`, `\note`, `\references`, `\seealso`, `\examples` | Content sections |
| :purple_circle: **Purple** | `\section` | Custom named section (2 arguments: title + body) |

---

## All 50 tags, in order

### Tags 1-12: File header (comments + whitespace)

```
Tag  1  COMMENT   ──▶  % Hand-maintained Rd macro showcase for the multilingual-docs GSoC demo.
Tag  2  TEXT      ──▶  ⏎ (newline between comments)
Tag  3  COMMENT   ──▶  % Purpose: exercise every kind of Rd markup, \Sexpr stage/results variant,
Tag  4  TEXT      ──▶  ⏎
Tag  5  COMMENT   ──▶  % #ifdef/#ifndef conditional, list, table, math, link, and format-conditional
Tag  6  TEXT      ──▶  ⏎
Tag  7  COMMENT   ──▶  % so we can observe how each one renders (and, later, how each translates).
Tag  8  TEXT      ──▶  ⏎
Tag  9  COMMENT   ──▶  % Deliberately hand-edited: do NOT regenerate from R/ with roxygen2 ...
Tag 10  TEXT      ──▶  ⏎
Tag 11  COMMENT   ──▶  % A literal percent sign must be escaped as \% in Rd.
Tag 12  TEXT      ──▶  ⏎
```

> **Pattern:** Every `%`-comment line becomes a `COMMENT` element, and the
> newline after it becomes a `TEXT` element. Comments are stripped during
> rendering; they never appear in help output.

---

### Tags 13-20: Identity macros

```
Tag 13  \name      ──▶  \name{submit_proposal}                        ← line 7
Tag 14  TEXT       ──▶  ⏎
Tag 15  \alias     ──▶  \alias{submit_proposal}                       ← line 8
Tag 16  TEXT       ──▶  ⏎
Tag 17  \alias     ──▶  \alias{gsocproposal-macros}                   ← line 9
Tag 18  TEXT       ──▶  ⏎
Tag 19  \encoding  ──▶  \encoding{UTF-8}                              ← line 10
Tag 20  TEXT       ──▶  ⏎
```

> **Note:** There are TWO `\alias` entries, so two separate elements appear.
> Each is a sectioning macro with one argument. The `TEXT` between them is
> just the newline separating lines.

---

### Tags 21-22: Title

```
Tag 21  \title  ──▶  \title{Submit a \gsoc{} Proposal \emph{and} Showcase Rd Macros}
                                                                      ← line 11
Tag 22  TEXT    ──▶  ⏎
```

> **Inside** this element there are nested child elements (`\gsoc`, `\emph`,
> text nodes) but `parse_Rd()` returns them as *children of Tag 21's list*,
> not as separate top-level tags. `tools:::RdTags()` only shows the
> top-level tags.

---

### Tags 23-26: Usage and Arguments

```
Tag 23  \usage      ──▶  \usage{                                      ← lines 12-16
                           submit_proposal()
                           \method{print}{gsoc_proposal}(x, \dots)
                         }
Tag 24  TEXT        ──▶  ⏎

Tag 25  \arguments  ──▶  \arguments{                                  ← lines 17-22
                           \item{x}{An object of class ...}
                           \item{\dots}{Further arguments ...}
                         }
Tag 26  TEXT        ──▶  ⏎
```

> `\arguments` is a list-type section. Its `\item` children are nested
> inside it, not separate top-level elements.

---

### Tags 27-28: Description

```
Tag 27  \description  ──▶  \description{                              ← lines 23-49
                              Checks whether the current system date ...
                              ...
                              \Sexpr[results=text,stage=install]{...}
                              ...
                              \Sexpr[results=text,stage=render]{...}
                           }
Tag 28  TEXT           ──▶  ⏎
```

> This is a large section. All the `\Sexpr`, `\emph`, `\strong`, `\code`
> macros inside it are **nested children** — they do NOT get their own
> top-level tag numbers.

---

### Tags 29-30: Details

```
Tag 29  \details  ──▶  \details{                                      ← lines 50-111
                         \subsection{Inline text markup}{...}
                         \subsection{Lists}{...}
                         \subsection{A table}{...}
                         \subsection{Math}{...}
                         \subsection{Platform conditionals ...}{...}
                       }
Tag 30  TEXT      ──▶  ⏎
```

> The entire `\details` section — including all five `\subsection` blocks,
> the `\itemize`, `\enumerate`, `\describe`, `\tabular`, `\eqn`, `\deqn`,
> `#ifdef`/`#ifndef` — is ONE top-level element. Everything inside is
> nested.

---

### Tags 31-32: Custom section (Sexpr showcase)

```
Tag 31  \section  ──▶  \section{Sexpr stage and results showcase}{    ← lines 112-133
                         ... \Sexpr[results=text,stage=build]{...}
                         ... \Sexpr[results=verbatim,stage=render]{...}
                         ... \Sexpr[echo=TRUE,...]{...}
                         ... \Sexpr[results=rd,...]{...}
                         ... \Sexpr[results=hide,...]{...}
                       }
Tag 32  TEXT      ──▶  ⏎
```

> `\section` is the only macro with **two arguments** (title + body),
> stored as a two-element list. All other sectioning macros have one.

---

### Tags 33-40: Value, Note, References, See Also

```
Tag 33  \value       ──▶  \value{A single logical value. ...}         ← lines 134-137
Tag 34  TEXT         ──▶  ⏎

Tag 35  \note        ──▶  \note{\ifelse{html}{...}{...} ...}          ← lines 138-142
Tag 36  TEXT         ──▶  ⏎

Tag 37  \references  ──▶  \references{R Core Team. ... \url{...} ...} ← lines 143-146
Tag 38  TEXT         ──▶  ⏎

Tag 39  \seealso     ──▶  \seealso{\code{\link{Sys.Date}} ...}        ← lines 147-150
Tag 40  TEXT         ──▶  ⏎
```

---

### Tags 41-42: Examples

```
Tag 41  \examples  ──▶  \examples{                                    ← lines 151-169
                          submit_proposal()
                          \dontrun{browseURL(...)}
                          \donttest{Sys.sleep(0)}
                          \dontshow{stopifnot(...)}
                        }
Tag 42  TEXT       ──▶  ⏎
```

> `\examples` content is **R-like** text (not LaTeX-like). `\dontrun`,
> `\donttest`, `\dontshow` are nested R-like children.

---

### Tags 43-50: Keywords and Concepts (metadata)

```
Tag 43  \keyword  ──▶  \keyword{utilities}                            ← line 170
Tag 44  TEXT      ──▶  ⏎

Tag 45  \keyword  ──▶  \keyword{documentation}                        ← line 171
Tag 46  TEXT      ──▶  ⏎

Tag 47  \concept  ──▶  \concept{dynamic documentation}                ← line 172
Tag 48  TEXT      ──▶  ⏎

Tag 49  \concept  ──▶  \concept{Sexpr}                                ← line 173
Tag 50  TEXT      ──▶  ⏎ (trailing newline at end of file)
```

---

## Visual summary: the shape of an Rd parse tree

```
parse_Rd("submit_proposal.Rd")
│
├─ [1]  COMMENT ─── "%  Hand-maintained ..."
├─ [2]  TEXT ────── "\n"
├─ [3]  COMMENT ─── "%  Purpose: ..."
├─ [4]  TEXT ────── "\n"
├─ [5]  COMMENT ─── "%  #ifdef/#ifndef ..."
├─ [6]  TEXT ────── "\n"
├─ [7]  COMMENT ─── "%  so we can observe ..."
├─ [8]  TEXT ────── "\n"
├─ [9]  COMMENT ─── "%  Deliberately ..."
├─ [10] TEXT ────── "\n"
├─ [11] COMMENT ─── "%  A literal percent ..."
├─ [12] TEXT ────── "\n"
│
├─ [13] \name ───── "submit_proposal"
├─ [14] TEXT ────── "\n"
├─ [15] \alias ──── "submit_proposal"
├─ [16] TEXT ────── "\n"
├─ [17] \alias ──── "gsocproposal-macros"
├─ [18] TEXT ────── "\n"
├─ [19] \encoding ─ "UTF-8"
├─ [20] TEXT ────── "\n"
│
├─ [21] \title ──── "Submit a {gsoc} Proposal {emph} and Showcase Rd Macros"
├─ [22] TEXT ────── "\n"
│
├─ [23] \usage ─┬── submit_proposal()
│               └── \method{print}{gsoc_proposal}(x, \dots)
├─ [24] TEXT ────── "\n"
│
├─ [25] \arguments ─┬── \item{x}{...}
│                   └── \item{\dots}{...}
├─ [26] TEXT ────── "\n"
│
├─ [27] \description ─┬── text ...
│                     ├── \Sexpr[stage=install]{...}
│                     └── \Sexpr[stage=render]{...}
├─ [28] TEXT ────── "\n"
│
├─ [29] \details ──┬── \subsection{Inline text markup}{...}
│                  ├── \subsection{Lists}{...}
│                  ├── \subsection{A table}{...}
│                  ├── \subsection{Math}{...}
│                  └── \subsection{Platform conditionals}{...}
├─ [30] TEXT ────── "\n"
│
├─ [31] \section ──── {title: "Sexpr stage and results showcase"}
│                     {body:  \describe{ 5x \Sexpr variants }}
├─ [32] TEXT ────── "\n"
│
├─ [33] \value ──── "A single logical value. TRUE if ..."
├─ [34] TEXT ────── "\n"
├─ [35] \note ───── "\ifelse{html}{...}{...} ..."
├─ [36] TEXT ────── "\n"
├─ [37] \references ── "R Core Team. ... \url{...} ..."
├─ [38] TEXT ────── "\n"
├─ [39] \seealso ──── "\code{\link{Sys.Date}} ..."
├─ [40] TEXT ────── "\n"
│
├─ [41] \examples ─┬── submit_proposal()
│                  ├── \dontrun{...}
│                  ├── \donttest{...}
│                  └── \dontshow{...}
├─ [42] TEXT ────── "\n"
│
├─ [43] \keyword ── "utilities"
├─ [44] TEXT ────── "\n"
├─ [45] \keyword ── "documentation"
├─ [46] TEXT ────── "\n"
├─ [47] \concept ── "dynamic documentation"
├─ [48] TEXT ────── "\n"
├─ [49] \concept ── "Sexpr"
└─ [50] TEXT ────── "\n"
```

## Key takeaways

1. **`parse_Rd()` returns a flat list of top-level sections** — there are only
   50 elements, not hundreds, because everything inside a `\details{...}` or
   `\description{...}` is *nested children*, not siblings.

2. **Half the elements (25 of 50) are `TEXT`** — these are just the newlines
   between sections. They carry no content.

3. **The real structure is 6 comments + 19 sectioning macros** = 25 meaningful
   elements. The `TEXT` nodes are separators.

4. **`\section` is special** — it has 2 arguments (title + body) while all other
   sectioning macros have 1.

5. **To suppress the "unknown macro" warnings**, pass the macros file:
   ```r
   rd <- parse_Rd(infile, macros = "multilingual-docs/man/macros/gsoc-macros.Rd")
   ```
   This teaches the parser about `\gsoc`, `\pkgenv`, and `\deadlineNote`.
