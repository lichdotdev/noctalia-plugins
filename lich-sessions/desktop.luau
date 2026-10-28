--!nonstrict
local view = require("./ui.luau")

local sessions = noctalia.state.get("sessions") or {}
local dir = noctalia.state.get("assets") or ""
local frame = 0
local HOME = noctalia.getenv("HOME") or ""

-- Read-only: a desktop or lock-screen widget has nowhere to focus a session.
local function render()
  local rows = { ui.row({ align = "center", gap = 8, paddingH = 4 }, view.header(sessions, dir, 16)) }
  for _, child in view.body(sessions, frame, dir, HOME, nil) do
    table.insert(rows, child)
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
