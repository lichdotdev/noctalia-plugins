--!nonstrict
-- Writes the status rings and the lich mark as SVG files in the active palette's
-- colors, since ui.* can neither draw an arc nor rotate a glyph. One directory per
-- palette under the plugin's data dir, so a theme change gets fresh files.

local marks = require("./marks.luau")

-- lich's sidebar ring (native/cmd/lich-native/sidebar_card.go statusGlyph): 22px,
-- 1.25px stroke, a quarter arc over a 25% track turning once a second.
local SIZE = 22
local STROKE = 1.25
local ICON = 12
local BUSY_FRAMES = 30
local TRACK_OPACITY = 0.25

local M = { SIZE = SIZE, BUSY_FRAMES = BUSY_FRAMES }

local function palette()
  return {
    muted = noctalia.getColor("on_surface_variant"),
    wait = noctalia.getColor("tertiary"),
    pass = noctalia.getColor("primary"),
    fg = noctalia.getColor("on_surface"),
  }
end

local function key(p)
  return (`{p.muted}{p.wait}{p.pass}{p.fg}`):gsub("#", "")
end

local function svg(body)
  return `<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" viewBox="0 0 {SIZE} {SIZE}">{body}</svg>`
end

local R = SIZE / 2 - STROKE / 2
local C = SIZE / 2

local function circle(color, opacity)
  return `<circle cx="{C}" cy="{C}" r="{R}" fill="none" stroke="{color}" stroke-opacity="{opacity}" stroke-width="{STROKE}"/>`
end

local function arc(color, frame)
  local a0 = frame * 2 * math.pi / BUSY_FRAMES - math.pi / 2
  local a1 = a0 + math.pi / 2
  local d = string.format("M %.3f %.3f A %.3f %.3f 0 0 1 %.3f %.3f",
    C + R * math.cos(a0), C + R * math.sin(a0), R, R, C + R * math.cos(a1), C + R * math.sin(a1))
  return `<path d="{d}" fill="none" stroke="{color}" stroke-width="{STROKE}" stroke-linecap="round"/>`
end

local function icon(color, d)
  if d == "" then return "" end
  local off = (SIZE - ICON) / 2
  return `<g transform="translate({off} {off}) scale({ICON / 24})"><path fill="{color}" d="{d}"/></g>`
end

local function ringName(provider, state)
  return `{provider}-{state}.svg`
end

M.ringName = ringName

-- ensure writes the files for the active palette once and returns their directory.
function M.ensure()
  local p = palette()
  local dir = `{noctalia.pluginDataDir()}/assets/{key(p)}`
  if noctalia.fileExists(`{dir}/lich.svg`) then return dir end
  noctalia.mkdirAll(dir)
  local providers = { none = "" }
  for name, d in marks.LOBE do providers[name] = d end
  for name, d in providers do
    local mark = icon(p.muted, d)
    noctalia.writeFile(`{dir}/{ringName(name, "waiting")}`, svg(circle(p.wait, 1) .. mark))
    noctalia.writeFile(`{dir}/{ringName(name, "done")}`, svg(circle(p.pass, 1) .. mark))
    noctalia.writeFile(`{dir}/{ringName(name, "idle")}`, svg(circle(p.muted, TRACK_OPACITY) .. mark))
    for f = 0, BUSY_FRAMES - 1 do
      local track = circle(p.muted, TRACK_OPACITY) .. arc(p.muted, f)
      noctalia.writeFile(`{dir}/{ringName(name, string.format("busy-%02d", f))}`, svg(track .. mark))
    end
  end
  -- Written last: its presence marks the set as complete.
  noctalia.writeFile(`{dir}/lich.svg`,
    `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 1024 1024"><path fill="{p.fg}" fill-rule="evenodd" d="{marks.LICH}"/></svg>`)
  return dir
end

return M
