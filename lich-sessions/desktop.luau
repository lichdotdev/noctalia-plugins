--!nonstrict
local view = require("./ui.luau")

local sessions = noctalia.state.get("sessions") or {}
local dir = noctalia.state.get("assets") or ""
local frame = 0
local HOME = noctalia.getenv("HOME") or ""

-- Desktop widgets cannot scroll (ui.scroll is panels only) and the host shrinks
-- whatever outgrows the widget's box, so it shows at most max_sessions cards.
local MAX = noctalia.getConfig("max_sessions")

local PRIORITY = { waiting = 0, busy = 1, compacting = 1 }

-- The ones that want you first, then the working ones, keeping lich's order within each.
local function shown()
  local ranked = {}
  for i, s in sessions do table.insert(ranked, { s = s, i = i }) end
  table.sort(ranked, function(a, b)
    local pa, pb = PRIORITY[a.s.state] or 2, PRIORITY[b.s.state] or 2
    if pa ~= pb then return pa < pb end
    return a.i < b.i
  end)
  local list = {}
  for i = 1, math.min(MAX, #ranked) do table.insert(list, ranked[i].s) end
  return list, #ranked - #list
end

-- Read-only: a desktop or lock-screen widget has nowhere to focus a session.
local function render()
  local list, hidden = shown()
  local rows = { ui.row({ align = "center", gap = 8, paddingH = 4 }, view.header(sessions, dir, 16)) }
  for _, child in view.body(list, frame, dir, HOME, nil) do
    table.insert(rows, child)
  end
  if hidden > 0 then
    table.insert(rows, ui.label({ text = noctalia.trp("desktop.more", hidden), fontSize = 11, color = "on_surface_variant" }))
  end
  desktopWidget.render(ui.column({ gap = 4, padding = 4, width = 400, align = "stretch" }, rows))
end

noctalia.state.watch("sessions", function(value)
  sessions = value or {}
  render()
end)
noctalia.state.watch("assets", function(value)
  dir = value or ""
  render()
end)

function update()
  local busy = view.counts(sessions)
  noctalia.setUpdateInterval(busy > 0 and view.FRAME_MS or 1000)
  frame += 1
  render()
end

render()
