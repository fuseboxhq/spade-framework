-- Remove active or fetchable content from untrusted SPADE Markdown.
-- Pandoc executes this filter before the standalone writer embeds resources.

local function has_control(value)
  return value:find("[%z\1-\31\127]") ~= nil
end

local function safe_link(target)
  if has_control(target) then
    return false
  end
  local lower = target:lower()
  if lower:match("^https?://") or lower:match("^mailto:") or target:match("^#") then
    return true
  end
  if lower:match("^[a-z][a-z0-9+.-]*:") or target:match("^[/\\]") then
    return false
  end
  if lower:match("%%2f") or lower:match("%%5c") or target == ".."
      or target:match("^%.%.[/\\]") or target:match("[/\\]%.%.[/\\]")
      or target:match("[/\\]%.%.$") then
    return false
  end
  return true
end

function RawBlock(_)
  return {}
end

function RawInline(_)
  return {}
end

function Link(element)
  if not safe_link(element.target) then
    return pandoc.Span(element.content)
  end
  element.attributes = {}
  return element
end

function Image(element)
  local lower = element.src:lower()
  local kind = lower:match("^data:image/([a-z]+);base64,")
  local allowed = {png = true, jpeg = true, gif = true, webp = true}
  if not has_control(element.src) and allowed[kind] then
    element.attributes = {}
    return element
  end
  return pandoc.Span(element.caption)
end
