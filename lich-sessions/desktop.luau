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

-- The spinner runs on the host's frame ticks, not on a timer: a timer kept rebuilding
-- the tree at 30fps while the widget was covered by windows, ~40% of a CPU core.
-- Ticks follow the frames the host actually draws, and they are only asked for while
-- a session is busy; the tree is rebuilt only when the spinner moves to its next frame.
local elapsed = 0

local function wantTicks()
  local busy = view.counts(sessions)
  desktopWidget.setNeedsFrameTick(busy > 0)
end

noctalia.state.watch("sessions", function(value)
  sessions = value or {}
  wantTicks()
  render()
end)
noctalia.state.watch("assets", function(value)
  dir = value or ""
  render()
end)

-- Rebuilding the island is the cost, not the tick, so it redraws at 10fps; the frame
-- index still advances with real time, so the ring turns at lich's speed.
local REDRAW_MS = 100

function onFrameTick(deltaMs)
  elapsed += deltaMs
  if elapsed < REDRAW_MS then return end
  frame += elapsed // view.FRAME_MS
  elapsed %= view.FRAME_MS
  render()
end

function update()
  noctalia.setUpdateInterval(60000)
end

wantTicks()
render()
