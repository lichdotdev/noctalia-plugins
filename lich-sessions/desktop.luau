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

-- The host measures the tree at its natural size and only scales it to fit the box,
-- aspect kept, so the island holds room for MAX cards: the widget keeps one shape as
-- sessions come and go, and resizing the box scales all of it. 82px is a card with
-- its branch line, as rendered.
local CARD_HEIGHT = 82

local function shown()
  local all = view.sorted(sessions, ORDER)
  local list = {}
  for i = 1, math.min(MAX, #all) do table.insert(list, all[i]) end
  return list, #all - #list
end

-- Read-only: a desktop or lock-screen widget has nowhere to focus a session.
local function render()
  local list, hidden = shown()
  local island = view.ISLAND
  local rows = view.body(list, frame, dir, HOME, nil)
  if hidden > 0 then
    table.insert(rows, ui.label({ text = noctalia.trp("desktop.more", hidden), fontSize = 11, color = "on_surface_variant" }))
  end
  -- The widget is the canvas, so the island reads against it over any wallpaper.
  desktopWidget.render(ui.column({ gap = island.gutter, padding = island.gutter, width = 400, align = "stretch", fill = "surface", radius = island.radius + island.gutter }, {
    ui.row({ align = "center", gap = 8, paddingH = 4, paddingV = 2 }, view.header(sessions, dir, 16)),
    -- The list sits in its own column so the spacers between projects keep their
    -- height and the room left over stays at the bottom.
    ui.column({ padding = 8, minHeight = MAX * CARD_HEIGHT, align = "stretch", fill = island.fill, radius = island.radius }, {
      ui.column({ gap = 2, align = "stretch" }, rows),
    }),
  }))
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
