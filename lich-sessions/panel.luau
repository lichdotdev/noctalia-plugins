--!nonstrict
local view = require("./ui.luau")

local sessions = noctalia.state.get("sessions") or {}
local dir = noctalia.state.get("assets") or ""
local frame = 0
local open = false
local HOME = noctalia.getenv("HOME") or ""

local function shellQuote(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function focus(s)
  noctalia.runAsync(`lich focus --project {shellQuote(s.projectPath)} {shellQuote(s.id)}`)
  panel.close()
end

local function render()
  local header = view.header(sessions, dir, 18)
  table.insert(header, ui.button({ glyph = "close", variant = "ghost", onClick = function() panel.close() end }))
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ align = "center", gap = 8 }, header),
    ui.scroll({ flexGrow = 1, gap = 4, align = "stretch" }, view.body(sessions, frame, dir, HOME, focus)),
  }))
end

noctalia.state.watch("sessions", function(value)
  sessions = value or {}
  if open then render() end
end)
noctalia.state.watch("assets", function(value)
  dir = value or ""
  if open then render() end
end)

function update()
  if not open then
    noctalia.setUpdateInterval(60000)
    return
  end
  local busy = view.counts(sessions)
  noctalia.setUpdateInterval(busy > 0 and view.FRAME_MS or 1000)
  frame += 1
  render()
end

function onOpen(_context)
  open = true
  noctalia.setUpdateInterval(view.FRAME_MS)
  render()
end

function onClose()
  open = false
end
