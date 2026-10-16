# Research Report (Typst / Quarto extension)

Brand: `#009fb7` teal · `#fed766` gold · `#696773` gray · `#272727` ink · `#f0f0f0` mist.
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

## Fonts

Fonts must be installed locally (or bundled with `font-paths`): Source Serif 4,
Source Sans 3, Source Code Pro. The older Source Serif Pro / Source Sans Pro are used
as fallbacks (Typst still warns about the missing first choices).

## YAML keys

| key | default | effect |
| --- | --- | --- |
| `short-title` | `title` | running header text |
| `client` / `client-note` | — | "Prepared for" block on cover, footer left |
| `report-number` / `report-kind` | — / Technical Report | cover eyebrow |
| `report-logo` | `logo.png` | cover logo (not `logo`, which Quarto reserves for a page-background logo) |
| `abstract` / `abstract-title` | — / Executive summary | grey hex summary box |
| `citation-text` | — | suggested-citation box at foot of contents |
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
