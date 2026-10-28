--!nonstrict
-- Session cards shaped like lich's sidebar (native/cmd/lich-native/sidebar_card.go).

local assets = require("./assets.luau")

-- 33ms is lich's own spinnerFrame.
local FRAME_MS = 33

-- providericon.go: a Lobe mark where Lobe has one, a glyph otherwise.
local PROVIDER_ICON = { claude = "claude", codex = "codex", antigravity = "antigravity", opencode = "opencode", omp = "pi", cursor = "cursor" }
local PROVIDER_GLYPH = { crush = "sparkles", kiro = "ghost" }

-- lich lays its sidebar and stage out as islands (main.go island): rounded boxes
-- (ui.RadiusLG) a shade off the canvas around them, 6px apart (main.go gutter).
local ISLAND = { fill = "surface_container", radius = 8, gutter = 6 }

local M = { FRAME_MS = FRAME_MS, ISLAND = ISLAND }

function M.isBusy(s)
  return s.state == "busy" or s.state == "compacting"
end

local function ringState(s, frame)
  if M.isBusy(s) then return string.format("busy-%02d", frame % assets.BUSY_FRAMES) end
  if s.state == "waiting" or s.state == "done" then return s.state end
  return "idle"
end

function M.ring(s, frame, dir)
  local size = assets.SIZE
  local icon = PROVIDER_ICON[s.kind]
  local img = ui.image({ path = `{dir}/{assets.ringName(icon or "none", ringState(s, frame))}`, width = size, height = size })
  if icon then return img end
  -- A negative gap stacks the glyph over the ring (the agentik plugin's trick).
  return ui.column({ width = size, height = size, gap = -size }, {
    img,
    ui.column({ width = size, height = size, align = "center", justify = "center" }, {
      ui.glyph({ name = PROVIDER_GLYPH[s.kind] or "terminal", size = assets.ICON, color = "on_surface_variant" }),
    }),
  })
end

local function caption(text, color, weight)
  return ui.label({ text = text, fontSize = 11, fontWeight = weight, color = color, maxLines = 1 })
end

-- The line under the title (statusrung.go): the rung while the session waits for you, else its path.
local function secondLine(s, home)
  if s.state == "waiting" then
    return ui.row({ gap = 4, align = "center" }, {
      ui.glyph({ name = "help-circle", size = 12, color = "tertiary" }),
      caption(noctalia.tr("state.waiting"), "tertiary", "medium"),
    })
  end
  local path = s.path or ""
  if home ~= "" and path:sub(1, #home) == home then path = "~" .. path:sub(#home + 1) end
  return caption(path, "on_surface_variant")
end

-- card is lich's (sidebar_card.go cardBody, cardcolor.go): transparent at rest and
-- the hover color under the pointer. ctl is nil where nothing can be clicked.
function M.card(s, frame, dir, home, ctl)
  local rows = {
    ui.row({ gap = 6, align = "center" }, {
      M.ring(s, frame, dir),
      ui.label({ text = s.label, fontSize = 13, fontWeight = "medium", color = "on_surface", maxLines = 1, flexGrow = 1 }),
    }),
    secondLine(s, home),
  }
  if (s.branch or "") ~= "" then
    table.insert(rows, ui.row({ gap = 4, align = "center" }, {
      ui.glyph({ name = "git-branch", size = 12, color = "on_surface_variant" }),
      caption(s.branch, "on_surface_variant"),
    }))
  end
  return ui.column({
    gap = 6, paddingH = 10, paddingV = 8, radius = 6, align = "stretch",
    fill = ctl and ctl.hovered == s.id and "hover" or nil,
    onClick = ctl and function() ctl.focus(s) end or nil,
    onHover = ctl and function(state) ctl.hover(s, state == "true") end or nil,
  }, rows)
end

local PRIORITY = { waiting = 0, busy = 1, compacting = 1 }

-- sorted returns the sessions in the configured order: "lich" keeps the sidebar's,
-- "attention" puts the ones waiting for you first, then the working ones.
function M.sorted(sessions, order)
  if order ~= "attention" then return sessions end
  local ranked = {}
  for i, s in sessions do table.insert(ranked, { s = s, i = i }) end
  table.sort(ranked, function(a, b)
    local pa, pb = PRIORITY[a.s.state] or 2, PRIORITY[b.s.state] or 2
    if pa ~= pb then return pa < pb end
    return a.i < b.i
  end)
  local list = {}
  for _, r in ranked do table.insert(list, r.s) end
  return list
end

function M.groupBy(list, field)
  local groups, order = {}, {}
  for _, s in list do
    local k = s[field] or ""
    if groups[k] == nil then
      groups[k] = {}
      table.insert(order, k)
    end
    table.insert(groups[k], s)
  end
  return groups, order
end

function M.counts(sessions)
  local busy, waiting = 0, 0
  for _, s in sessions do
    if M.isBusy(s) then busy += 1 elseif s.state == "waiting" then waiting += 1 end
  end
  return busy, waiting
end

local function chip(text, color)
  return ui.row({ align = "center", paddingH = 8, paddingV = 3, radius = 10, fill = color .. "/0.12" }, {
    ui.label({ text = text, fontSize = 11, fontWeight = "medium", color = color }),
  })
end

function M.header(sessions, dir, size)
  local busy, waiting = M.counts(sessions)
  local chips = {}
  if busy > 0 then table.insert(chips, chip(noctalia.trp("summary.busy", busy), "on_surface_variant")) end
  if waiting > 0 then table.insert(chips, chip(noctalia.trp("summary.waiting", waiting), "tertiary")) end
  if busy == 0 and waiting == 0 then table.insert(chips, chip(noctalia.tr("summary.idle"), "primary")) end
  return {
    ui.image({ path = `{dir}/lich.svg`, width = size, height = size }),
    ui.label({ text = "lich", fontSize = size - 2, fontWeight = "bold", color = "on_surface" }),
    ui.row({ flexGrow = 1 }, {}),
    ui.row({ gap = 6, align = "center" }, chips),
  }
end

-- groupHeader is sidebar_group_header.go's: the title in capitals, its count, and a rule to the edge.
local function groupHeader(glyph, title, count)
  local kids = {}
  if glyph then table.insert(kids, ui.glyph({ name = glyph, size = 12, color = "on_surface_variant" })) end
  table.insert(kids, ui.label({ text = string.upper(title), fontSize = 10, fontWeight = "semibold", color = "on_surface_variant", maxLines = 1 }))
  table.insert(kids, ui.label({ text = tostring(count), fontSize = 10, fontWeight = "medium", color = "on_surface_variant/0.6" }))
  table.insert(kids, ui.separator({ flexGrow = 1, orientation = "horizontal", color = "outline_variant" }))
  return ui.row({ gap = 6, align = "center", paddingH = 4, paddingV = 4 }, kids)
end

-- body groups by project, then by sidebar folder, the way lich's sidebar does.
function M.body(sessions, frame, dir, home, ctl)
  local body = {}
  if #sessions == 0 then
    table.insert(body, ui.label({ text = noctalia.tr("panel.empty"), fontSize = 12, color = "on_surface_variant" }))
  end
  local byProject, projects = M.groupBy(sessions, "project")
  for i, project in projects do
    if i > 1 then table.insert(body, ui.spacer({ height = 6 })) end
    table.insert(body, groupHeader(nil, project, #byProject[project]))
    local byFolder, folders = M.groupBy(byProject[project], "folder")
    for _, folder in folders do
      if folder ~= "" then table.insert(body, groupHeader("folder", folder, #byFolder[folder])) end
      for _, s in byFolder[folder] do
        table.insert(body, M.card(s, frame, dir, home, ctl))
      end
    end
  end
  return body
end

return M
