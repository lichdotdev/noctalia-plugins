--!nonstrict
local view = require("./ui.luau")

local sessions = noctalia.state.get("sessions") or {}
local dir = noctalia.state.get("assets") or ""
local frame = 0
local HOME = noctalia.getenv("HOME") or ""

-- Desktop widgets cannot scroll (ui.scroll is panels only) and the host shrinks
-- whatever outgrows the widget's box, so it shows at most max_sessions cards.
local MAX = noctalia.getConfig("max_sessions")
local ORDER = noctalia.getConfig("order")

local function shown()
  local all = view.sorted(sessions, ORDER)
  local list = {}
  for i = 1, math.min(MAX, #all) do table.insert(list, all[i]) end
  return list, #all - #list
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
