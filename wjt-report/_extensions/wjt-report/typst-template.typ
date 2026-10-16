// ============================================================
// Research Report — Typst template for Quarto
// Palette: #009fb7 teal · #fed766 gold · #696773 gray
//          #272727 ink  · #f0f0f0 mist
// Visual spec: Research Report Template.dc.html
// ============================================================

#let brand = (
  teal: rgb("#009fb7"),
  teal-dark: rgb("#0091a7"),
  teal-tint: rgb("#f7feff"),
  gold: rgb("#fed766"),
  gold-tint: rgb("#fffdf3"),
  gold-dark: rgb("#8a6d00"),
  gray: rgb("#696773"),
  ink: rgb("#272727"),
  mist: rgb("#f0f0f0"),
)

// Fall back to the older "Pro" releases, which are metrically near-identical.
#let sans = ("Source Sans 3", "Source Sans Pro")
#let serif = ("Source Serif 4", "Source Serif Pro")
#let mono = "Source Code Pro"

// Set by the wjt-report.lua filter before every level-1 heading.
#let chapter-blurb = state("rr-chapter-blurb", none)
// Per-heading divider override: true ({.divider}), false ({.no-divider}), none.
#let chapter-divider = state("rr-chapter-divider", none)

// ---------- geometry ----------------------------------------
// Pointy-top regular hexagon; height = width * 2/sqrt(3).
#let hex(width: 12pt, fill: brand.teal, stroke: none) = {
  let w = width
  let h = w * 1.1547
  polygon(
    fill: fill,
    stroke: stroke,
    (w * 0.5, 0pt),
    (w, h * 0.25),
    (w, h * 0.75),
    (w * 0.5, h),
    (0pt, h * 0.75),
    (0pt, h * 0.25),
  )
}

// Hexagonal ring: outer hex with a hole punched in the middle.
#let hex-ring(width: 12pt, fill: brand.teal, hole: white, ratio: 0.72) = {
  box(width: width, height: width * 1.1547)[
    #place(center + horizon, hex(width: width, fill: fill))
    #place(center + horizon, hex(width: width * ratio, fill: hole))
  ]
}

// Hexagon with something inside it (page numbers, section numbers).
#let hex-badge(
  body,
  width: 14pt,
  fill: brand.teal,
  text-fill: white,
  size: 7.5pt,
) = {
  box(width: width, height: width * 1.1547, baseline: 25%)[
    #place(center + horizon, hex(width: width, fill: fill))
    #place(center + horizon, text(
      font: sans, size: size, weight: "bold", fill: text-fill,
    )[#body])
  ]
}

#let eyebrow(body, fill: brand.gray, size: 8.5pt, tracking: 0.14em) = text(
  font: sans, size: size, weight: "bold", fill: fill, tracking: tracking,
)[#upper(body)]

// ---------- chapter helpers ---------------------------------
#let is-appendix(h) = h.supplement == [Appendix]

// Marker for a level-1 heading: "01" (numbered), "A" (appendix), "—" (other).
// Needs context.
#let chapter-mark(h) = {
  if is-appendix(h) {
    let n = query(heading.where(level: 1).before(h.location())).filter(is-appendix).len()
    numbering("A", n)
  } else if h.numbering != none {
    let n = counter(heading).at(h.location()).first()
    if n < 10 { "0" + str(n) } else { str(n) }
  } else {
    "—"
  }
}

// The chapter a page belongs to: the first level-1 heading on the page,
// otherwise the last one before it. Needs context.
#let current-chapter() = {
  let pg = here().page()
  let h1s = query(heading.where(level: 1))
  let on = h1s.filter(h => h.location().page() == pg)
  let before = h1s.filter(h => h.location().page() < pg)
  if on.len() > 0 { on.first() } else if before.len() > 0 { before.last() } else { none }
}

// ---------- suggested citation (APA 7) ----------------------
// Plain text of Quarto-supplied content (names, titles).
#let plain(it) = if it == none { "" } else if type(it) == str { it } else if it.has("text") { it.text } else if it.has("children") { it.children.map(plain).join() } else if it.has("body") { plain(it.body) } else if it == [ ] { " " } else { "" }

// "W. Jake" -> "W. J."; "Mary-Jane" -> "M.-J."
#let initials(given) = plain(given).split(" ").filter(w => w != "").map(w =>
  w.split("-").filter(p => p != "").map(p => p.clusters().first() + ".").join("-")
).join(" ")

// "Thompson, W. J."; a name Quarto couldn't split (e.g. an organisation)
// is used as written.
#let apa-name(a) = {
  let family = a.at("family", default: none)
  let given = a.at("given", default: none)
  if family == none { plain(a.name) }
  else if given == none { plain(family) }
  else { plain(family) + ", " + initials(given) }
}

// APA 7 author list: "A", "A, & B", "A, B, & C" (up to 20 names); beyond
// 20, the first 19, an ellipsis, then the last.
#let apa-authors(authors) = {
  let names = authors.map(apa-name)
  let n = names.len()
  if n == 0 { none }
  else if n == 1 { names.first() }
  else if n <= 20 { names.slice(0, -1).join(", ") + ", & " + names.last() }
  else { names.slice(0, 19).join(", ") + ", . . . " + names.last() }
}

// Author, A. A. (Year). _Title_ (Kind No. Number). Publisher.
#let apa-citation(authors: (), year: none, title: none, kind: none, number: none, publisher: none) = {
  let series = if kind != none and number != none { [ (#kind No. #number)] }
    else if kind != none { [ (#kind)] }
    else if number != none { [ (No. #number)] }
  let work = [#emph(title)#series.]
  let who = apa-authors(authors)
  // Group authors need the period personal names get from their initials.
  if who != none and not who.ends-with(".") { who += "." }
  let lead = if who != none { [#who (#year). #work] } else { [#work (#year).] }
  if publisher != none { [#lead #publisher.] } else { lead }
}

// ---------- page furniture ----------------------------------
#let running-header() = context {
  let chap = current-chapter()
  if chap != none {
    let mark = chapter-mark(chap)
    let label = if mark == "—" { chap.body } else { [#mark#h(0.7em)#chap.body] }
    block(width: 100%, inset: (bottom: 7pt), stroke: (bottom: 0.75pt + brand.mist))[
      #grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
        text(font: sans, size: 8.5pt, tracking: 0.1em, fill: brand.gray)[#upper(label)],
        hex(width: 11pt, fill: brand.gold),
      )
    ]
  }
}

#let running-footer(running) = context {
  block(width: 100%, inset: (top: 9pt), stroke: (top: 0.75pt + brand.mist))[
    #grid(columns: (1fr, auto, auto), align: horizon, column-gutter: 7pt,
      text(font: sans, size: 8.5pt, tracking: 0.1em, fill: brand.gray)[#upper(running)],
      hex(width: 13pt, fill: brand.teal),
      text(font: sans, size: 9pt, weight: "semibold", fill: brand.gray)[
        #counter(page).display()
      ],
    )
  ]
}

// ---------- cover -------------------------------------------
#let cover-page(
  title: none,
  subtitle: none,
  authors: (),
  client: none,
  client-note: none,
  report-number: none,
  kind: "Technical Report",
  logo: none,
  band-height: 5.9in,
) = {
  set page(margin: 0pt, header: none, footer: none, numbering: none)

  // — colour band —
  block(width: 100%, height: band-height, fill: brand.teal, clip: true)[
    #place(top + right, dx: 0.7in, dy: -1.1in,
      hex-ring(width: 3.2in, fill: brand.teal-dark, hole: brand.teal))
    #place(top + right, dx: -1.55in, dy: 1.55in, hex(width: 1.05in, fill: brand.gold))
    #place(top + right, dx: -2.35in, dy: 2.75in,
      hex(width: 0.5in, fill: brand.gold.transparentize(45%)))
    #place(bottom + left, dx: 0.85in, dy: -0.55in, block(width: 5.6in)[
      #if kind != none or report-number != none {
        grid(columns: (auto, auto), column-gutter: 10pt, align: horizon,
          hex(width: 13pt, fill: brand.gold),
          eyebrow(
            if report-number == none { kind } else { [#kind#h(0.9em)·#h(0.9em)No. #report-number] },
            fill: brand.gold, size: 10pt, tracking: 0.16em,
          ),
        )
        v(0.3in)
      }
      #block(spacing: 0pt)[
        #set par(leading: 0.3em, justify: false)
        #text(font: sans, size: 40pt, weight: "bold", fill: white,
              tracking: -0.015em, hyphenate: false)[#title]
      ]
      #if subtitle != none {
        v(0.3in)
        block(width: 4.9in)[
          #set par(leading: 0.55em)
          #text(font: serif, size: 16pt, style: "italic", fill: rgb("#eafaff"))[#subtitle]
        ]
      }
    ])
  ]

  // — lower half —
  block(width: 100%, height: 1fr, inset: (x: 0.85in, top: 0.5in, bottom: 0.7in))[
    // Tight leading: names and affiliations can wrap, and the body's paragraph
    // leading would open a bigger gap between lines than between items.
    #let party(name, note) = stack(spacing: 8pt,
      block[
        #set par(leading: 0.4em)
        #text(font: sans, size: 13pt, weight: "semibold", fill: brand.ink)[#name]
      ],
      if note != none {
        block[
          #set par(leading: 0.5em)
          #text(font: serif, size: 11pt, fill: brand.gray)[#note]
        ]
      },
    )
    #grid(columns: (1.6fr, 1fr), column-gutter: 0.9in, row-gutter: 9pt,
      if authors.len() > 0 { eyebrow[Prepared by] },
      if client != none { eyebrow[Prepared for] },
      if authors.len() > 0 {
        stack(spacing: 10pt, ..authors.map(a => {
          let degrees = a.at("degrees", default: none)
          let name = if degrees != none [#a.name, #degrees] else { a.name }
          party(name, a.at("affiliation", default: none))
        }))
      },
      if client != none {
        party(client, client-note)
      },
    )
    #v(1fr)
    #grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
      if logo != none { image(logo, height: 0.72in) },
      stack(dir: ltr, spacing: 5pt,
        hex(width: 15pt, fill: brand.mist),
        hex(width: 15pt, fill: brand.gray.transparentize(65%)),
        hex(width: 15pt, fill: brand.gold),
        hex(width: 15pt, fill: brand.teal),
      ),
    )
  ]
}

// ---------- contents ----------------------------------------
#let contents-page(title: "Contents", depth: 2, citation: none) = {
  block(below: 0.36in)[
    #grid(columns: (auto, auto), align: horizon, column-gutter: 10pt,
      hex(width: 15pt, fill: brand.teal),
      text(font: sans, size: 22pt, weight: "bold", tracking: -0.01em)[#title],
    )
  ]
  block(width: 100%, height: 3pt, fill: brand.gold, below: 0.2in)

  show outline.entry: it => context {
    let el = it.element
    let page-num = text(font: serif, size: 11pt, fill: brand.gray)[#it.page()]
    let row(inset, mark, title) = block(
      width: 100%, above: 0pt, below: 0pt, inset: inset,
      stroke: (bottom: 0.75pt + brand.mist),
    )[
      #set par(leading: 0.5em, spacing: 0pt, justify: false)
      #link(el.location())[
        #box(width: 0.42in, mark)#h(10pt)#box(width: 1fr, title)#h(10pt)#page-num
      ]
    ]
    if it.level == 1 {
      let numbered = el.numbering != none and not is-appendix(el)
      let tone = if numbered { brand.teal } else { brand.gray }
      row(
        (y: 12pt),
        text(font: sans, size: 10pt, weight: "bold", fill: tone)[#chapter-mark(el)],
        text(font: sans, size: 13pt, weight: "semibold",
             fill: if numbered { brand.ink } else { brand.gray })[#el.body],
      )
    } else {
      row(
        (y: 9pt, left: 0.42in),
        none,
        text(font: serif, size: 11pt, fill: brand.gray)[#el.body],
      )
    }
  }
  outline(title: none, depth: depth, indent: 0pt)

  if citation != none {
    v(1fr)
    block(
      width: 100%, fill: brand.mist, inset: (x: 0.26in, y: 0.22in),
      stroke: (left: 3pt + brand.gold), breakable: false,
    )[
      #stack(spacing: 9pt,
        eyebrow[Suggested citation],
        {
          set par(leading: 0.75em)
          text(font: serif, size: 10pt)[#citation]
        },
      )
    ]
  }
}

// ---------- executive summary -------------------------------
#let summary-box(body, title: "Executive summary") = block(
  width: 100%, fill: brand.mist, inset: (x: 0.32in, y: 0.24in), breakable: false,
  below: 0.3in,
)[
  #grid(columns: (auto, 1fr), column-gutter: 0.28in,
    box(width: 0.42in, height: 0.42in * 1.1547)[
      #place(center + horizon, hex(width: 0.42in, fill: brand.teal))
      #place(center + horizon, hex(width: 0.16in, fill: brand.gold))
    ],
    stack(spacing: 14pt,
      eyebrow(title, fill: brand.teal, size: 10pt),
      {
        set par(leading: 0.85em, spacing: 1.2em)
        text(font: serif, size: 11.5pt)[#body]
      },
    ),
  )
]

// ---------- section divider page ----------------------------
#let divider-page(number: none, title: none, blurb: none) = {
  page(fill: brand.ink, margin: 0pt, header: none, footer: none)[
    #block(width: 100%, height: 100%, clip: true)[
      #place(top + left, dx: -1.2in, dy: -0.9in, hex(width: 4.6in, fill: rgb("#2f2f2f")))
      #place(bottom + right, dx: 1.1in, dy: 1.6in,
        hex-ring(width: 5.4in, fill: brand.teal.transparentize(10%), hole: brand.ink, ratio: 0.76))
      #place(top + right, dx: -1.1in, dy: 2.2in, hex(width: 0.62in, fill: brand.gold))
      #place(horizon + left, dx: 0.85in, block(width: 5.4in)[
        #grid(columns: (auto, 1fr), align: horizon, column-gutter: 12pt,
          if number != none {
            hex-badge(number, width: 0.46in, fill: brand.gold,
                      text-fill: brand.ink, size: 15pt)
          },
          line(length: 100%, stroke: 1pt + brand.gray),
        )
        #v(0.2in)
        #block[
          #set par(leading: 0.3em)
          #text(font: sans, size: 38pt, weight: "bold", fill: white,
                tracking: -0.02em, hyphenate: false)[#title]
        ]
        #if blurb != none {
          v(0.2in)
          block(width: 4.4in)[
            #set par(leading: 0.65em)
            #text(font: serif, size: 14pt, weight: "regular", style: "italic", fill: rgb("#dcdcdc"))[#blurb]
          ]
        }
      ])
    ]
  ]
}

// ---------- callouts (Quarto hook) --------------------------
// Quarto passes its own palette; map it onto the brand: note/tip → teal,
// warning/caution/important → gold.
#let callout(
  body: [],
  title: "Note",
  background_color: none,
  icon: none,
  icon_color: none,
  body_background_color: none,
) = {
  let warm = ("#eb9113", "#fc5300", "#cc1914")
  let is-warm = icon_color != none and icon_color.to-hex() in warm
  let accent = if is-warm { brand.gold } else { brand.teal }
  let tint = if is-warm { brand.gold-tint } else { brand.teal-tint }
  let label-color = if is-warm { brand.gold-dark } else { brand.teal }
  block(
    width: 100%, fill: tint, inset: (x: 0.28in, y: 0.24in), breakable: false,
    stroke: (left: 4pt + accent, rest: 0.75pt + accent), above: 14pt, below: 14pt,
  )[
    #grid(columns: (auto, 1fr), column-gutter: 0.22in,
      hex(width: 0.3in, fill: accent),
      stack(spacing: 12pt,
        eyebrow(title, fill: label-color, size: 9.5pt, tracking: 0.12em),
        {
          set par(leading: 0.85em, spacing: 1.2em)
          text(font: serif, size: 10.5pt)[#body]
        },
      ),
    )
  ]
}

// ---------- code (overrides Pandoc's Skylighting) -----------
#let code-block(body) = block(
  width: 100%, fill: brand.mist, inset: (x: 0.24in, y: 0.2in),
  stroke: (left: 3pt + brand.gray), above: 12pt, below: 14pt,
)[
  #set par(leading: 0.75em, justify: false)
  #show raw: it => text(font: mono, size: 9pt, it.text)
  #text(font: mono, size: 9pt, fill: brand.ink)[#body]
]

#let Skylighting(fill: none, number: false, start: 1, sourcelines) = {
  let blocks = []
  let lnum = start - 1
  for ln in sourcelines {
    if number {
      lnum = lnum + 1
      blocks = blocks + box(width: 24pt, text(fill: brand.gray)[#lnum])
    }
    blocks = blocks + ln + linebreak()
  }
  code-block(blocks)
}

// ---------- main article ------------------------------------
#let report(
  title: none,
  subtitle: none,
  short-title: none,
  authors: (),
  client: none,
  client-note: none,
  report-number: none,
  kind: "Technical Report",
  publisher: none,
  logo: none,
  abstract: none,
  abstract-title: "Executive summary",
  toc: true,
  toc-title: "Contents",
  toc-depth: 2,
  citation: none,
  paper: "us-letter",
  fontsize: 11.5pt,
  section-dividers: true,
  cover: true,
  section-numbering: none,
  doc,
) = {
  // Report number defaults to the render month, e.g. "2026-10".
  let report-number = if report-number == none {
    datetime.today().display("[year]-[month]")
  } else { report-number }

  // Suggested citation: `citation-text` wins; otherwise built from the YAML.
  let citation = if citation != none { citation } else if title != none {
    apa-citation(
      authors: authors, year: datetime.today().year(), title: title,
      kind: kind, number: report-number, publisher: publisher,
    )
  }

  // `set document` needs plain strings; Quarto hands us content blocks.
  set document(title: if title == none { "" } else { title }, author: authors.map(a => plain(a.name)))

  let running = if short-title != none { short-title } else { title }

  set text(font: serif, size: fontsize, fill: brand.ink, lang: "en")
  set par(justify: false, leading: 0.92em, spacing: 1.85em)
  // Links are teal, except citations (links to citeproc's <ref-…> labels),
  // which stay in body ink so cited passages don't stand out.
  let is-citation(dest) = type(dest) == label and str(dest).starts-with("ref-")
  show link: it => {
    set text(fill: if is-citation(it.dest) { brand.ink } else { brand.teal })
    it
  }
  set list(
    marker: box(baseline: 12%, hex(width: 7pt, fill: brand.teal)),
    indent: 0pt, body-indent: 9pt, spacing: 1.45em,
  )
  set enum(numbering: n => text(font: sans, weight: "bold", fill: brand.teal)[#n.])

  // headings
  set heading(numbering: section-numbering)
  show heading: set text(font: sans, hyphenate: false)

  show heading.where(level: 1): set block(above: 0pt, below: 16pt)
  show heading.where(level: 1, supplement: [Appendix]): set block(above: 0.45in)
  show heading.where(level: 2): set block(above: 1.9em, below: 12pt)
  show heading.where(level: 3): set block(above: 1.7em, below: 10pt)
  show heading.where(level: 4): set block(above: 1.6em, below: 8pt)
  // section-dividers: true (every numbered chapter), false (none), or
  // "after-first" (chapter 1 runs on after the executive summary).
  // {.divider} / {.no-divider} on a heading overrides this.
  let divider-mode = if section-dividers in (true, "true") { true }
    else if section-dividers == "after-first" { "after-first" }
    else { false }

  show heading.where(level: 1): it => context {
    let numbered = it.numbering != none and not is-appendix(it)
    let n = counter(heading).get().first()
    let default = numbered and (
      divider-mode == true or (divider-mode == "after-first" and n > 1)
    )
    let override = chapter-divider.get()
    let wants-divider = if override != none { override } else { default }

    let inline-h1 = block(sticky: true)[
      #set par(leading: 0.4em)
      #text(size: 26pt, weight: "bold", fill: brand.ink, tracking: -0.015em)[#it.body]
    ]
    // Hex badge + title: gold/ink for chapters (as on divider pages),
    // ink/gold for appendices.
    let badged-h1(mark, fill: brand.gold, text-fill: brand.ink) = block(sticky: true,
      grid(columns: (auto, 1fr), column-gutter: 11pt, align: horizon,
        hex-badge(mark, width: 0.36in, fill: fill, text-fill: text-fill, size: 12pt),
        text(size: 22pt, weight: "bold", fill: brand.ink, tracking: -0.015em)[#it.body],
      ))

    if wants-divider {
      divider-page(
        number: if numbered { counter(heading).display(it.numbering) }
          else if is-appendix(it) { chapter-mark(it) } else { none },
        title: it.body,
        blurb: chapter-blurb.get(),
      )
    } else if is-appendix(it) {
      badged-h1(chapter-mark(it), fill: brand.ink, text-fill: brand.gold)
    } else if numbered {
      // Chapter 1 follows the executive summary on the first body page.
      if n > 1 { pagebreak(weak: true) }
      badged-h1(counter(heading).display(it.numbering))
    } else {
      pagebreak(weak: true)
      inline-h1
    }
  }
  show heading.where(level: 2): it => block(sticky: true,
    text(size: 15pt, weight: "bold", fill: brand.teal)[#it.body])
  show heading.where(level: 3): it => block(sticky: true,
    text(size: 12pt, weight: "bold", fill: brand.ink)[#it.body])
  show heading.where(level: 4): it => block(sticky: true,
    text(size: 11pt, weight: "bold", fill: brand.gray, tracking: 0.04em)[#upper(it.body)])

  // figures & tables
  set figure(gap: 8pt)
  show figure: set block(above: 12pt, below: 16pt)
  show figure.caption: it => block(
    width: 100%, stroke: (top: 2pt + brand.teal), inset: (top: 7pt),
  )[
    #set par(leading: 0.75em, justify: false)
    #set align(left)
    #grid(columns: (auto, 1fr), column-gutter: 9pt,
      text(font: sans, size: 9.5pt, weight: "bold", fill: brand.teal, tracking: 0.04em)[
        #it.supplement #context it.counter.display(it.numbering).
      ],
      text(font: serif, size: 9.5pt, fill: brand.gray)[#it.body],
    )
  ]
  // Brand table text. This also overrides the CSS font stack Quarto carries
  // over from HTML tables (e.g. gt's "Roboto, Helvetica, Arial, sans-serif").
  show table: set text(font: serif, size: 10pt)
  show table.cell.where(y: 0): set text(font: sans, weight: "bold", size: 9.5pt)
  // APA rules: none above the header, 1pt black under it and at the bottom.
  // The header rule is the table.hline() Pandoc/Quarto emit after the header
  // rows (so multi-row gt spanner headers work too). Stroke functions can't
  // see the row count, so the bottom rule is the edge of a box hugging the table.
  set table(stroke: none, inset: (x: 8pt, y: 6pt))
  set table.hline(stroke: 1pt + black)
  show table: it => box(stroke: (bottom: 1pt + black), it)

  // code (un-highlighted blocks; highlighted ones go through Skylighting)
  show raw: set text(font: mono)
  show raw.where(block: true): it => code-block(it)
  show raw.where(block: false): set text(size: 1.15em)

  show quote.where(block: true): it => block(
    width: 100%, inset: (left: 20pt), stroke: (left: 3pt + brand.gold),
  )[#text(style: "italic", fill: brand.gray)[#it.body]]

  // references (citeproc output or Typst's own bibliography)
  show <refs>: set text(size: 10.5pt)
  show <refs>: set par(hanging-indent: 0.3in, leading: 0.75em, spacing: 1.3em)
  show bibliography: set text(size: 10.5pt)

  let footer = running-footer(running)

  // cover (page i)
  if cover in (true, "true") {
    cover-page(
      title: title, subtitle: subtitle, authors: authors, client: client,
      client-note: client-note, report-number: report-number,
      kind: kind, logo: logo,
    )
  }

  // front matter (roman numerals, no running header)
  if toc {
    set page(
      paper: paper,
      margin: (x: 0.85in, top: 0.95in, bottom: 1.3in),
      header: none,
      footer: footer,
      footer-descent: 0.27in,
      numbering: "i",
    )
    contents-page(title: toc-title, depth: toc-depth, citation: citation)
  }

  // body: header sits 0.8in from the top edge, footer 0.7in from the bottom
  set page(
    paper: paper,
    margin: (x: 0.85in, top: 1.42in, bottom: 1.3in),
    header: running-header(),
    header-ascent: 0.32in,
    footer: footer,
    footer-descent: 0.27in,
    numbering: "1",
  )
  counter(page).update(1)

  if abstract != none {
    summary-box(abstract, title: abstract-title)
  }

  doc
}
