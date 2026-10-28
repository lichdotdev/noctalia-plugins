--!nonstrict
local view = require("./ui.luau")

local sessions = noctalia.state.get("sessions") or {}
local err = noctalia.state.get("error") or ""
local dir = noctalia.state.get("assets") or ""

local function render()
  local container = barWidget.isVertical() and ui.column or ui.row
  local items = {}
  if dir ~= "" then table.insert(items, ui.image({ path = `{dir}/lich.svg`, width = 14, height = 14 })) end
  if err ~= "" then
    table.insert(items, ui.label({ text = "!", color = "error", fontWeight = "bold" }))
    barWidget.setTooltip(err)
  else
    local busy, waiting = view.counts(sessions)
    table.insert(items, ui.label({ text = tostring(busy), color = "on_surface" }))
    if waiting > 0 then
      table.insert(items, ui.row({ fill = "tertiary/0.2", radius = 8, paddingH = 6, align = "center" }, {
        ui.label({ text = tostring(waiting), color = "tertiary", fontWeight = "bold" }),
      }))
    end
    barWidget.setTooltip(noctalia.tr("tooltip", { total = #sessions, busy = busy, waiting = waiting }))
  end
  barWidget.render(container({ gap = 6, align = "center" }, items))
end

noctalia.state.watch("sessions", function(value)
  sessions = value or {}
  render()
end)
noctalia.state.watch("error", function(value)
  err = value or ""
  render()
end)
noctalia.state.watch("assets", function(value)
  dir = value or ""
  render()
end)

function update()
  noctalia.setUpdateInterval(60000)
  render()
end

function onClick()
  noctalia.togglePanel("lichdotdev/lich-sessions:panel")
end
