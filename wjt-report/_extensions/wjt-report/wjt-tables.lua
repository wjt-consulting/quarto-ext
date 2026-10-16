-- Fix up HTML-derived tables (e.g. gt) before Quarto translates their CSS
-- into Typst. Runs at pre-render, before that translation happens.
--
-- 1. Drop CSS font-family declarations. Quarto carries over font stacks such
--    as "Roboto, Helvetica, Arial, sans-serif"; Typst warns about every
--    family it can't find (generic CSS families never exist), and the
--    template sets brand table fonts anyway.
--
-- 2. Honour horizontal placement. gt's `table.align` is expressed as CSS
--    margins (e.g. "margin-left: 0; margin-right: auto"), which Quarto
--    ignores, so the table ends up centred by its figure. Wrap the table in
--    a full-width Typst align() instead.
--
-- 3. Apply CSS text-transform (uppercase / lowercase / capitalize) to the cell
--    text itself, e.g. gt's `column_labels.text_transform`. Typst has no
--    equivalent property, so Quarto drops it.

local function css_value(style, prop)
  for decl in style:gmatch("[^;]+") do
    local k, v = decl:match("^%s*([%w%-]+)%s*:%s*(.-)%s*$")
    if k == prop then return v end
  end
  return nil
end

-- "left" / "right" from auto margins, or nil for centred / unspecified.
local function horizontal_align(style)
  if not style then return nil end
  local ml, mr = css_value(style, "margin-left"), css_value(style, "margin-right")
  if mr == "auto" and ml ~= "auto" then return "left" end
  if ml == "auto" and mr ~= "auto" then return "right" end
  return nil
end

local function strip_font_family(attr)
  local style = attr.attributes["style"]
  if not style then return end
  local kept = {}
  for decl in style:gmatch("[^;]+") do
    if not decl:match("^%s*font%-family%s*:") then
      table.insert(kept, decl)
    end
  end
  attr.attributes["style"] = table.concat(kept, ";")
end

-- Effective text-transform for an element, falling back to its parent's.
local function text_transform(attr, inherited)
  local style = attr.attributes["style"]
  local v = style and css_value(style, "text-transform")
  if v == nil or v == "inherit" then return inherited end
  return v
end

local transforms = {
  uppercase = pandoc.text.upper,
  lowercase = pandoc.text.lower,
  capitalize = function(s)
    return pandoc.text.upper(pandoc.text.sub(s, 1, 1)) .. pandoc.text.sub(s, 2)
  end,
}

local function apply_transform(cell, tt)
  local fn = transforms[tt]
  if not fn then return end  -- "none" or unknown
  cell.contents = pandoc.Blocks(cell.contents):walk({
    Str = function(el) return pandoc.Str(fn(el.text)) end,
  })
end

local function fix_rows(rows, table_tt)
  for _, row in ipairs(rows) do
    local row_tt = text_transform(row.attr, table_tt)
    strip_font_family(row.attr)
    for _, cell in ipairs(row.cells) do
      apply_transform(cell, text_transform(cell.attr, row_tt))
      strip_font_family(cell.attr)
    end
  end
end

function Table(el)
  if not quarto.doc.is_format("typst") then return nil end

  local align = horizontal_align(el.attributes["style"])

  local tt = text_transform(el.attr, nil)

  strip_font_family(el.attr)
  fix_rows(el.head.rows, tt)
  for _, body in ipairs(el.bodies) do
    fix_rows(body.head, tt)
    fix_rows(body.body, tt)
  end
  fix_rows(el.foot.rows, tt)

  if align then
    return {
      -- Full width, so the figure (which centres its body) leaves room to align in.
      pandoc.RawBlock("typst", "#block(width: 100%)[#align(" .. align .. ")["),
      el,
      pandoc.RawBlock("typst", "]]"),
    }
  end
  return el
end
