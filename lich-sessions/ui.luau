--!nonstrict
-- Session cards shaped like lich's sidebar (native/cmd/lich-native/sidebar_card.go).

local assets = require("./assets.luau")

-- 33ms is lich's own spinnerFrame.
local FRAME_MS = 33

-- providericon.go: a Lobe mark where Lobe has one, a glyph otherwise.
local PROVIDER_ICON = { claude = "claude", codex = "codex", antigravity = "antigravity", opencode = "opencode", omp = "pi", cursor = "cursor" }
local PROVIDER_GLYPH = { crush = "sparkles", kiro = "ghost" }

local M = { FRAME_MS = FRAME_MS }

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
      ui.glyph({ name = PROVIDER_GLYPH[s.kind] or "terminal", size = 12, color = "on_surface_variant" }),
    }),
  })
end

local function caption(text, color, weight)
  return ui.label({ text = text, fontSize = 11, fontWeight = weight, color = color, maxLines = 1 })
end

-- One line under the title: the state when it wants attention, else the branch, else the path.
local function secondLine(s, home)
  if M.isBusy(s) then
    return caption(noctalia.tr("state.busy"), "on_surface_variant")
  elseif s.state == "waiting" then
    return caption(noctalia.tr("state.waiting"), "tertiary", "medium")
  elseif (s.branch or "") ~= "" then
    return ui.row({ gap = 4, align = "center" }, {
      ui.glyph({ name = "git-branch", size = 11, color = "on_surface_variant" }),
      caption(s.branch, "on_surface_variant"),
    })
  end
  local path = s.path or ""
  if home ~= "" and path:sub(1, #home) == home then path = "~" .. path:sub(#home + 1) end
  return caption(path, "on_surface_variant")
end

function M.card(s, frame, dir, home, onClick)
  local fill = s.state == "waiting" and "tertiary/0.08" or "on_surface/0.03"
  return ui.row({ gap = 10, align = "center", paddingH = 10, paddingV = 8, radius = 8, fill = fill, onClick = onClick }, {
    M.ring(s, frame, dir),
    ui.column({ gap = 3, flexGrow = 1 }, {
      ui.label({ text = s.label, fontSize = 13, fontWeight = "medium", color = "on_surface", maxLines = 1 }),
      secondLine(s, home),
    }),
  })
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

function M.groupHeader(title, count)
  return ui.row({ gap = 6, align = "center", paddingH = 4 }, {
    ui.label({ text = string.upper(title), fontSize = 10, fontWeight = "bold", color = "on_surface_variant" }),
    ui.label({ text = tostring(count), fontSize = 10, color = "on_surface_variant/0.6" }),
  })
end

-- body groups by project, then by sidebar folder, the way lich's sidebar does.
function M.body(sessions, frame, dir, home, onClick)
  local body = {}
  if #sessions == 0 then
    table.insert(body, ui.label({ text = noctalia.tr("panel.empty"), fontSize = 12, color = "on_surface_variant" }))
  end
  local byProject, projects = M.groupBy(sessions, "project")
  for i, project in projects do
    if i > 1 then table.insert(body, ui.spacer({ height = 6 })) end
    table.insert(body, M.groupHeader(project, #byProject[project]))
    local byFolder, folders = M.groupBy(byProject[project], "folder")
    for _, folder in folders do
      if folder ~= "" then
        table.insert(body, ui.row({ gap = 6, align = "center", paddingH = 4, paddingV = 2 }, {
          ui.glyph({ name = "folder", size = 12, color = "on_surface_variant" }),
          caption(folder, "on_surface_variant"),
        }))
      end
      for _, s in byFolder[folder] do
        table.insert(body, M.card(s, frame, dir, home, onClick and function() onClick(s) end or nil))
      end
    end
  end
  return body
end

return M
