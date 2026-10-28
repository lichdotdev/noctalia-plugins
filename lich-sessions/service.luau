--!nonstrict
-- Reads lich's CLI and publishes its sessions, with their sidebar folder and
-- branch, to the plugin's shared state for the bar, panel and desktop widget.
-- shortcut: polls every 3s because the lich CLI has no event stream; switch once it does.

local assets = require("./assets.luau")

local POLL_MS = 3000
-- Folders and branches change rarely: refresh them every 5th tick (15s).
local META_EVERY = 5

local lastState = {}
local inFlight = false
local tick = 0
local folderOf = {} -- [project][label] = folder
local branchOf = {} -- [path] = branch
local assetsDir = ""

noctalia.setUpdateInterval(POLL_MS)

local function shellQuote(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function decode(res)
  if type(res) ~= "table" or res.exitCode ~= 0 then return nil end
  return noctalia.json.decode(res.stdout)
end

local function notifyWaiting(sessions)
  for _, s in sessions do
    if s.state == "waiting" and lastState[s.id] ~= nil and lastState[s.id] ~= "waiting" then
      noctalia.notify("lich", noctalia.tr("notify.waiting", { label = s.label, project = s.project }))
    end
  end
  lastState = {}
  for _, s in sessions do
    lastState[s.id] = s.state
  end
end

local function refreshMeta(sessions)
  local seen = {}
  for _, s in sessions do
    if not seen[s.project] then
      seen[s.project] = true
      local project, projectPath = s.project, s.projectPath
      local q = shellQuote(projectPath)
      noctalia.runAsync(`lich folders --project {q} --json`, function(res)
        local folders = decode(res)
        if not folders then return end
        local map = {}
        for _, f in folders do
          for _, label in f.sessions or {} do map[label] = f.name end
        end
        folderOf[project] = map
      end, 5000)
      noctalia.runAsync(`lich worktrees --project {q} --json`, function(res)
        for _, w in decode(res) or {} do branchOf[w.path] = w.name end
      end, 5000)
      -- The project's own checkout is not among its worktrees.
      noctalia.runAsync(`git -C {q} branch --show-current`, function(res)
        if type(res) == "table" and res.exitCode == 0 then
          branchOf[projectPath] = noctalia.string.trim(res.stdout)
        end
      end, 5000)
    end
  end
end

local function publishAssets()
  local dir = assets.ensure()
  if dir ~= assetsDir then
    assetsDir = dir
    noctalia.state.set("assets", dir)
  end
end

function update()
  publishAssets()
  if inFlight then return end
  inFlight = true
  noctalia.runAsync("lich sessions --json", function(res)
    inFlight = false
    local all = decode(res)
    if not all then
      noctalia.state.set("error", (type(res) == "table" and res.stderr ~= "" and res.stderr) or noctalia.tr("error.sessions"))
      return
    end
    local sessions = {}
    for _, s in all do
      if s.kind ~= "shell" then table.insert(sessions, s) end
    end
    if tick % META_EVERY == 0 then refreshMeta(sessions) end
    tick += 1
    for _, s in sessions do
      s.folder = (folderOf[s.project] or {})[s.label] or ""
      s.branch = branchOf[s.path] or ""
    end
    notifyWaiting(sessions)
    noctalia.state.set("error", "")
    noctalia.state.set("sessions", sessions)
  end, 5000)
end

function onIpc(event, _payload)
  if event == "refresh" then update() end
end
