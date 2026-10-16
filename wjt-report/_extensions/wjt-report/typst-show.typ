#show: doc => report(
$if(title)$
  title: [$title$],
$endif$
$if(subtitle)$
  subtitle: [$subtitle$],
$endif$
$if(short-title)$
  short-title: [$short-title$],
$endif$
$if(by-author)$
  authors: (
$for(by-author)$
    (
      name: [$it.name.literal$],
$if(it.affiliations)$
      affiliation: [$for(it.affiliations)$$it.name$$sep$, $endfor$],
$endif$
    ),
$endfor$
  ),
$endif$
$if(client)$
  client: [$client$],
$endif$
$if(client-note)$
  client-note: [$client-note$],
$endif$
$if(date)$
  date: [$date$],
$endif$
$if(report-number)$
  report-number: [$report-number$],
$endif$
$if(report-kind)$
  kind: [$report-kind$],
$endif$
$if(report-logo)$
  // Pandoc escapes markup chars (e.g. `\_`) in variables; undo that for the path.
  logo: "$report-logo$".replace("\\", ""),
$endif$
$if(abstract)$
  abstract: [$abstract$],
$endif$
$if(abstract-title)$
  abstract-title: [$abstract-title$],
$endif$
$if(citation-text)$
  citation: [$citation-text$],
$endif$
$if(toc)$
  toc: true,
$else$
  toc: false,
$endif$
$if(toc-depth)$
  toc-depth: $toc-depth$,
$endif$
$if(toc-title)$
  toc-title: [$toc-title$],
$endif$
$if(papersize)$
  paper: "$papersize$",
$endif$
$if(fontsize)$
  fontsize: $fontsize$,
$endif$
  section-dividers: "$section-dividers$",
$if(section-numbering)$
  section-numbering: "$section-numbering$",
$endif$
  cover: "$cover$",
  doc,
)
