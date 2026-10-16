# Research Report (Typst / Quarto extension)

Brand: `#009fb7` teal · `#fed766` gold · `#696773` gray · `#272727` ink · `#f0f0f0` mist.
For contrast, teal text and small elements use `#007789` and the cover band `#006979`;
`#009fb7` is kept for large decorative shapes (see Accessibility).
Type: Source Sans 3 (headings, furniture) + Source Serif 4 (body) + Source Code Pro (code).

## Files

- `_extensions/wjt-report/` — the Quarto extension: `_extension.yml`,
  `typst-template.typ`, `typst-show.typ`, `wjt-report.lua` (heading extras),
  `wjt-tables.lua` (gt/HTML table fixes: drops CSS font stacks, honours `table.align` and
  `text-transform`), `apa.csl`, `logo.png`.
- `template.qmd` — example document exercising every feature.
- `references.bib` — starter bibliography used by `template.qmd`.

The HTML design mock-up (`Research Report Template.dc.html`, with `doc-page.js`,
`support.js` and `assets/`) is a local reference only and is git-ignored.

## Install / use

```bash
quarto use template <you>/wjt-report   # new project: extension + starter files
quarto add <you>/wjt-report            # existing project: extension only
```

`quarto use template` installs the extension and copies the starter files into the
project root: `template.qmd` (renamed after the project folder) and `references.bib`.
`quarto add` installs only the extension.

## References

Citations are formatted in APA 7th edition with the bundled `apa.csl`, processed by
Pandoc (`citeproc: true`) so the list renders in the document's `::: {#refs}` div under
its References heading. The extension never sets `bibliography`; each document names
its own:

```yaml
bibliography: references.bib
```

In-text citations link to their entry in the reference list (`link-citations: true`; set
`false` in a document to turn it off). Linked citations stay in body ink; other links
(URLs, DOIs) are teal.

A document can also override the style with its own `csl:`.

## Suggested citation

Unless `citation-text` is set, the contents page shows an APA 7 citation built from the YAML:

> Thompson, W. J. (2026). *Measuring growth in diagnostic assessment systems* (Technical
> Report No. 2026-10). WJT Consulting.

- Authors: `Family, G. G.` from each author's name (APA list rules up to 20 names, then the
  first 19, `. . .`, and the last). Put credentials in `degrees:`, not in `name:`, since a
  comma in `name` makes Quarto read it as "Family, Given". For particles or unusual names,
  give the parts explicitly: `name: {given: Mary-Jane, family: van der Berg}`. A name Quarto
  can't split (e.g. an organisation) is used as written.
- Year: the year the document is rendered.
- Title: as written in `title` (APA prefers sentence case; override with `citation-text` if
  that matters).
- Report kind and number: `report-kind` and `report-number`.
- Publisher: `publisher`, if set. This is separate from author affiliations.

## Accessibility

Every report is rendered as **PDF/UA-1** (`pdf-standard: ua-1`), the only PDF/UA level Typst
supports. The PDF is tagged, with the document title, language and structure set. Typst
stops the render if it can detect a violation, most commonly an image without alt text:

- Figures from code: `#| fig-alt: "…"`
- Markdown images: `![](file.png){fig-alt="…"}`
- Cover logo: `report-logo-alt` (defaults to "WJT Consulting logo")

If veraPDF is installed (`quarto install verapdf`), Quarto validates every render against
PDF/UA-1 and reports `PASSED` or the failing rules.

Colours meet WCAG 2.1 AA contrast: text ≥ 4.5:1 (≥ 3:1 for large headings), graphics ≥ 3:1.
The brand teal `#009fb7` is only 3.2:1 on white, so it is not used for text or small
elements. veraPDF can't check contrast, alt-text quality or reading order, and colours
inside figures (e.g. gold points on white) are set by the plotting code, not the template.

## Fonts

Fonts must be installed locally (or bundled with `font-paths`): Source Serif 4,
Source Sans 3, Source Code Pro. The older Source Serif Pro / Source Sans Pro are used
as fallbacks (Typst still warns about the missing first choices).

## YAML keys

| key | default | effect |
| --- | --- | --- |
| `short-title` | `title` | running header text |
| `author` (`name`, `degrees`, `affiliations`) | — | "Prepared by" block on cover (`name, degrees`) and the suggested citation (`Family, G. G.`) |
| `client` / `client-note` | — | "Prepared for" block on cover; the note line is omitted when unset |
| `report-number` / `report-kind` | render month (`YYYY-MM`) / Technical Report | cover eyebrow and suggested citation |
| `publisher` | — | publisher in the suggested citation (omitted when unset) |
| `report-logo` | `logo.png` | cover logo (not `logo`, which Quarto reserves for a page-background logo) |
| `abstract` / `abstract-title` | — / Executive summary | grey hex summary box |
| `citation-text` | built from the YAML | suggested-citation box at foot of contents; set it to override the generated text |
| `section-dividers` | `after-first` | which chapters open with a full-bleed dark divider page: `after-first` (numbered chapters except chapter 1, which runs on after the executive summary), `true` (every numbered chapter), `false` (none) |
| `toc-depth` | `2` | levels shown in the contents |
| `cover` | `true` | set `false` for internal drafts |
| `papersize` | `us-letter` | `a4` also supported |
| `execute: echo` | `false` | chunk source hidden; set `echo: true` per document or chunk to show it |
| `execute: warning` | `false` | chunk warnings hidden; set `warning: true` to show them |
| `fig-width` / `fig-asp` | `6` / `0.618` | 6in wide, golden-ratio height (≈3.71in) |
| `fig-dpi` | `320` | resolution for any raster output (figures themselves are SVG, the Typst default) |

Heading attributes (level 1):

- `# Measurement model {blurb="..."}` — italic blurb under the title on its divider page.
- `# Appendix: model code {.appendix}` — lettered appendix heading (A, B, …) with a dark hex
  badge; shown as `A` in the contents.
- Other `{.unnumbered}` chapters (e.g. References) start a new page and show `—` in the contents.
- Numbered chapters without a divider page get an inline heading with a gold hex badge
  carrying the chapter number (matching the divider pages); appendices use the inverse,
  an ink badge with a gold letter.
- `{.divider}` / `{.no-divider}` — force a divider page on or off for that heading, overriding
  `section-dividers`. Works on any level-1 heading, including unnumbered ones and appendices.

With the default `section-dividers: after-first`, chapter 1 runs on directly after the
executive summary. Front matter is numbered i, ii, …;
the body restarts at 1. The running header shows the current chapter.

Tables use APA rules: no rule above the header, 1pt black rules under the header and at the
bottom. Border CSS from gt is ignored (Quarto doesn't carry it into Typst), so these rules
apply to every table. Tables (including gt) use Source Serif 4 for the body and Source Sans 3 for the header row;
any CSS `font-family` a table carries is dropped. gt's `table.align = "left"` / `"right"`
is honoured (Quarto otherwise centres every table in its figure), as is CSS `text-transform`
(e.g. `column_labels.text_transform = "uppercase"`), which Typst has no equivalent for.

Text wrapping around an image (e.g. an author headshot):

```markdown
::: {.wrap-image}
![](headshot.png){width=2in}

Text that runs beside the image, then continues full width beneath it.
:::
```

The div's first image is placed top-left (`{.wrap-image align="right"}` for top-right) and
everything else in the div flows around it. Uses the `@preview/wrap-it` Typst package, which
Quarto downloads on first use (needs network access once).

Callouts: note/tip render teal; warning/caution/important render gold — all with a hexagon icon.

## Status

Compiles with Quarto 1.10 / Typst 0.15. Known gaps against the HTML spec: the cover
title wraps greedily (Typst has no `text-wrap: balance`), and highlighted code keeps
Quarto's token colours where the spec shows plain ink.
