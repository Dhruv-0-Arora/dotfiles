local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local spaces = {}

local function update_aerospace_spaces()
  -- Get the currently focused workspace name from Aerospace
  local active_ws_cmd = io.popen("aerospace list-workspaces --focused")
  local active_ws = active_ws_cmd:read("*a"):gsub("^%s*(.-)%s*$", "%1") -- Read output and trim whitespace
  active_ws_cmd:close()

  -- Loop through all the space items we created
  for sid, space_group in pairs(spaces) do
    local is_selected = (sid == active_ws)

    -- Set properties based on whether the space is selected
    space_group.item:set({
      background = {
        border_color = is_selected and colors.black or colors.bg2,
      },
      label = {
        highlight = is_selected,
      },
    })
    space_group.bracket:set({
      background = {
        border_color = is_selected and colors.grey or colors.bg2,
      },
    })
  end
end

-- Use io.popen to execute the aerospace command and loop over its output.
-- 'lines()' iterates over each line, where each line is a workspace name.
for sid in io.popen("aerospace list-workspaces --all"):lines() do
  -- Trim any whitespace from the workspace name
  sid = sid:gsub("^%s*(.-)%s*$", "%1")

  -- Use 'item' instead of 'space' for custom window manager integration
  local space = sbar.add("item", "space." .. sid, {
    -- The label is now the workspace name (sid) from Aerospace
    label = {
      string = sid,
      padding_right = 8,
      color = colors.grey,
      highlight_color = colors.white,
      font = { family = settings.font.text },
      y_offset = -1,
    },
    padding_right = 1,
    padding_left = 1,
    background = {
      color = colors.bg2,
      border_width = 1,
      height = 26,
      border_color = colors.black,
    },
    -- When clicked, switch to this workspace
    click_script = "aerospace workspace '" .. sid .. "'",
  })

  -- Single item bracket for space items to achieve double border on highlight
  local space_bracket = sbar.add("bracket", { space.name }, {
    background = {
      color = colors.transparent,
      border_color = colors.bg2,
      height = 28,
      border_width = 2,
    },
  })

  -- Padding space
  sbar.add("item", "space.padding." .. sid, {
    width = settings.group_paddings,
  })

  -- Store references to the item and its bracket for easy updating
  spaces[sid] = {
    item = space,
    bracket = space_bracket,
  }
end

-- Add a single item to listen for Aerospace workspace changes
local aerospace_observer = sbar.add("item", "aerospace_observer", { drawing = false })
aerospace_observer:subscribe("aerospace_workspace_change", update_aerospace_spaces)

-- Run the update function once at the start to set the initial state
update_aerospace_spaces()
