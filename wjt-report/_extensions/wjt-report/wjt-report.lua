-- Research Report: content extras for the Typst template.
--
--   # Measurement model {blurb="Specification, estimation, and ..."}
--     -> italic blurb under the title on the section divider page
--
--   # Appendix: model code {.appendix}
--     -> lettered appendix heading (A, B, ...) with a dark hex badge
--
--   # Introduction {.divider}      # Results {.no-divider}
--     -> force a section divider page on or off for this heading,
--        overriding the document-level `section-dividers` option
--
--   ::: {.wrap-image}            (or {.wrap-image align="right"})
--   ![](headshot.png){width=2in}
--   Text that flows beside the image, then continues full width below it.
--   :::
--     -> wraps the div's text around its first image (via @preview/wrap-it)

local function to_typst(inlines)
  local out = pandoc.write(pandoc.Pandoc({ pandoc.Plain(inlines) }), "typst")
  return (out:gsub("%s+$", ""))
end

function Header(el)
  if el.level ~= 1 or not quarto.doc.is_format("typst") then
    return nil
  end

  local blocks = {}

  -- Reset the blurb at every chapter so it never leaks into the next divider.
  local blurb = el.attributes["blurb"]
  if blurb then
    local parsed = pandoc.read(blurb, "markdown").blocks
    local inlines = pandoc.utils.blocks_to_inlines(parsed)
    table.insert(blocks, pandoc.RawBlock("typst",
      "#chapter-blurb.update([" .. to_typst(inlines) .. "])"))
    el.attributes["blurb"] = nil
  else
    table.insert(blocks, pandoc.RawBlock("typst", "#chapter-blurb.update(none)"))
  end

  -- Reset the override at every chapter too.
  local divider = "none"
  if el.classes:includes("divider") then
    divider = "true"
  elseif el.classes:includes("no-divider") then
    divider = "false"
  end
  el.classes = el.classes:filter(function(c) return c ~= "divider" and c ~= "no-divider" end)
  table.insert(blocks, pandoc.RawBlock("typst", "#chapter-divider.update(" .. divider .. ")"))

  if el.classes:includes("appendix") then
    local label = el.identifier ~= "" and (" <" .. el.identifier .. ">") or ""
    table.insert(blocks, pandoc.RawBlock("typst",
      "#heading(level: 1, numbering: none, supplement: [Appendix])["
        .. to_typst(el.content) .. "]" .. label))
  else
    table.insert(blocks, el)
  end

  return blocks
end

-- Text wrapping around an image. Typst has no side floats, so this uses the
-- wrap-it package, imported here so only documents that use it fetch it.
local WRAP_IT = '#import "@preview/wrap-it:0.1.1": wrap-content'
local WRAP_GAP = "16pt"

local function is_image_para(block)
  return (block.t == "Para" or block.t == "Plain")
    and #block.content == 1 and block.content[1].t == "Image"
end

function Div(el)
  if not el.classes:includes("wrap-image") or not quarto.doc.is_format("typst") then
    return nil
  end

  local image_at
  for i, block in ipairs(el.content) do
    if is_image_para(block) then image_at = i; break end
  end
  if not image_at then return nil end

  local right = el.attributes["align"] == "right"
  local inset = right
    and "(left: " .. WRAP_GAP .. ", bottom: 6pt)"
    or "(right: " .. WRAP_GAP .. ", bottom: 6pt)"

  local text = {}
  for i, block in ipairs(el.content) do
    if i ~= image_at then table.insert(text, block) end
  end

  -- Keep the image and text as Pandoc blocks so Quarto still resolves them.
  local out = {
    pandoc.RawBlock("typst", WRAP_IT .. "\n#wrap-content(box(inset: " .. inset .. ")["),
    pandoc.Plain(el.content[image_at].content),
    pandoc.RawBlock("typst", "], ["),
  }
  for _, block in ipairs(text) do table.insert(out, block) end
  table.insert(out, pandoc.RawBlock("typst",
    "], align: top + " .. (right and "right" or "left") .. ")"))
  return out
end

